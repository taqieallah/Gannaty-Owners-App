// Push a notification to an owner's device when a payment (سداد) is recorded.
//
// Flow: a Postgres trigger (push_owner_transaction.sql) fires on every INSERT
// into `documents` with collection='owner_transactions' and POSTs the row's
// key fields here (OwnerId as TEXT — owner Ids are int64 beyond JS range). We
// look up that owner's FcmToken (owners collection) and send an FCM message via
// the HTTP v1 API, authenticated with the compound's Firebase service account.
// Works even when the owner app is fully closed.
//
// Deploy:  supabase functions deploy push-owner-transaction --no-verify-jwt
// Secrets (already set on the project):
//   FCM_SERVICE_ACCOUNT   the whole service-account JSON, one line
//   PUSH_TRIGGER_SECRET   shared secret the trigger sends in a header
//   OWNERS_WORKSPACE_UID  the workspace uid the owners live under
//   (SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY are built in)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const PUSH_TRIGGER_SECRET = Deno.env.get("PUSH_TRIGGER_SECRET") ?? "";
const WORKSPACE_UID = Deno.env.get("OWNERS_WORKSPACE_UID") ??
  Deno.env.get("WORKSPACE_UID") ?? "";
const SERVICE_ACCOUNT = JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT") ?? "{}");
const CHANNEL_ID = "compound_high_importance"; // must match the owner app's channel

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

// ── Google OAuth (service-account JWT → access token) ───────────────────────
let cachedToken: { value: string; exp: number } | null = null;

function b64url(bytes: Uint8Array): string {
  let s = "";
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function pemToBytes(pem: string): ArrayBuffer {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const bin = atob(b64);
  const buf = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) buf[i] = bin.charCodeAt(i);
  return buf.buffer;
}

async function getAccessToken(): Promise<string> {
  if (cachedToken && cachedToken.exp - 60 > Date.now() / 1000) {
    return cachedToken.value;
  }
  const now = Math.floor(Date.now() / 1000);
  const enc = new TextEncoder();
  const header = b64url(enc.encode(JSON.stringify({ alg: "RS256", typ: "JWT" })));
  const claim = b64url(enc.encode(JSON.stringify({
    iss: SERVICE_ACCOUNT.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  })));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToBytes(SERVICE_ACCOUNT.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = new Uint8Array(await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    enc.encode(`${header}.${claim}`),
  ));
  const jwt = `${header}.${claim}.${b64url(sig)}`;

  const resp = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  const json = await resp.json();
  if (!json.access_token) throw new Error(`oauth: ${JSON.stringify(json)}`);
  cachedToken = { value: json.access_token, exp: now + 3600 };
  return json.access_token;
}

async function sendToToken(
  token: string,
  title: string,
  body: string,
): Promise<{ ok: boolean; unregistered: boolean }> {
  const accessToken = await getAccessToken();
  const resp = await fetch(
    `https://fcm.googleapis.com/v1/projects/${SERVICE_ACCOUNT.project_id}/messages:send`,
    {
      method: "POST",
      headers: {
        authorization: `Bearer ${accessToken}`,
        "content-type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
          android: {
            priority: "high",
            notification: { channel_id: CHANNEL_ID, sound: "default" },
          },
          data: { type: "owner_transaction", screen: "balance" },
        },
      }),
    },
  );
  if (resp.ok) return { ok: true, unregistered: false };
  const text = await resp.text();
  const unregistered = resp.status === 404 || text.includes("UNREGISTERED");
  console.error("fcm send", resp.status, text.slice(0, 200));
  return { ok: false, unregistered };
}

// ── Notification text from the transaction fields ───────────────────────────
function egp(v: string): string {
  const n = Number(v);
  if (!isFinite(n)) return v;
  return n.toLocaleString("en-US");
}

function messageFor(
  txType: string,
  amount: string,
  description: string,
): { title: string; body: string } {
  const desc = (description ?? "").trim();
  return {
    title: "تم تسجيل دفعة",
    body: [
      `تم تسجيل دفعة بمبلغ ${egp(amount)} ج.م`,
      desc ? `(${desc})` : "",
    ].filter(Boolean).join(" "),
  };
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("ok");
  if (
    PUSH_TRIGGER_SECRET &&
    req.headers.get("x-push-secret") !== PUSH_TRIGGER_SECRET
  ) {
    return new Response("forbidden", { status: 401 });
  }

  let payload: Record<string, any>;
  try {
    payload = await req.json();
  } catch {
    return new Response("bad request", { status: 400 });
  }

  const ownerIdText = String(payload.owner_id ?? "").trim();
  const txType = String(payload.tx_type ?? "").toUpperCase();
  const amount = String(payload.amount ?? "");
  const description = String(payload.description ?? "");

  // Only notify on actual payments (سداد), not charges/other rows.
  if (txType !== "PAYMENT") return new Response(JSON.stringify({ skipped: txType }), {
    headers: { "content-type": "application/json" },
  });
  if (!ownerIdText) return new Response("no owner", { status: 200 });

  // Look up the owner's FCM token (exact text id match — int64-safe).
  const { data: rows, error } = await supabase
    .from("documents")
    .select("doc_id, data")
    .eq("uid", WORKSPACE_UID)
    .eq("collection", "owners")
    .eq("data->>Id", ownerIdText)
    .limit(1);
  if (error) {
    console.error("read owner", error);
    return new Response("error", { status: 500 });
  }
  const owner = (rows ?? [])[0];
  const token = String((owner?.data as Record<string, unknown>)?.FcmToken ?? "");
  if (!token) {
    return new Response(JSON.stringify({ sent: 0, reason: "no_token" }), {
      headers: { "content-type": "application/json" },
    });
  }

  const { title, body } = messageFor(txType, amount, description);
  const res = await sendToToken(token, title, body);

  // Prune a stale token so we don't keep trying it.
  if (res.unregistered && owner) {
    await supabase.from("documents").update({
      data: { ...(owner.data as Record<string, unknown>), FcmToken: "" },
    }).eq("uid", WORKSPACE_UID).eq("collection", "owners").eq("doc_id", owner.doc_id);
  }

  return new Response(JSON.stringify({ sent: res.ok ? 1 : 0 }), {
    headers: { "content-type": "application/json" },
  });
});
