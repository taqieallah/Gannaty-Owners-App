// Push notifications to owners' devices. The payload's `kind` picks the message:
//   (none) / owner_transaction  a payment (سداد) was recorded
//   service_status              one of their service requests changed status
//   visitor_arrived             a visitor pass of theirs was used at the gate
//   reminders                   monthly maintenance / overdue reminders for every
//                               owner (sent by pg_cron, at most once a month each)
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
// A malformed secret must not crash the function at boot (every call would
// then fail with no explanation); it is reported per request instead.
function parseServiceAccount(): Record<string, string> {
  try {
    return JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT") ?? "{}");
  } catch {
    return {};
  }
}
const SERVICE_ACCOUNT = parseServiceAccount();
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
  data: Record<string, string> = { type: "owner_transaction", screen: "balance" },
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
          data,
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


// ── Message texts ───────────────────────────────────────────────────────────
type Msg = { title: string; body: string; data: Record<string, string> };

function egp(v: string | number): string {
  const n = Number(v);
  if (!isFinite(n)) return String(v);
  return Math.round(n).toLocaleString("en-US");
}

function messageFor(amount: string, description: string): Msg {
  const desc = (description ?? "").trim();
  return {
    title: "تم تسجيل دفعة",
    body: [
      `تم تسجيل دفعة بمبلغ ${egp(amount)} ج.م`,
      desc ? `(${desc})` : "",
    ].filter(Boolean).join(" "),
    data: { type: "owner_transaction", screen: "balance" },
  };
}

// What the owner is told when the admin moves their request along.
function statusMessageFor(
  status: string,
  adminNote: string,
  requestId: string,
): Msg {
  const m: Record<string, { title: string; body: string }> = {
    in_progress: {
      title: "طلبك قيد التنفيذ",
      body: "جاري العمل على طلب الخدمة الخاص بك.",
    },
    solved: {
      title: "تم حل طلبك ✓",
      body: "تم الانتهاء من طلب الخدمة الخاص بك.",
    },
  };
  const msg = m[status] ?? {
    title: "تحديث على طلبك",
    body: "تم تحديث حالة طلب الخدمة الخاص بك.",
  };
  const note = adminNote.trim();
  return {
    title: msg.title,
    body: note ? `${msg.body} ملاحظة: ${note}` : msg.body,
    // Open the request itself when we know which one it was.
    data: requestId
      ? { type: "service_status", screen: "request_detail", id: requestId }
      : { type: "service_status", screen: "requests" },
  };
}

function visitorMessageFor(visitor: string, gate: string): Msg {
  const who = visitor.trim() || "زائرك";
  return {
    title: "وصل زائرك",
    body: gate.trim() ? `${who} دخل من ${gate.trim()}` : `${who} دخل الكمبوند`,
    data: { type: "visitor_arrived", screen: "visitors" },
  };
}

const MONTHS = [
  "يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو",
  "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر",
];

/// [balance] is the current-year ClosingBalance — the number the owner sees
/// on their balance screen. Returns null when there is nothing to remind.
function reminderFor(
  type: string,
  monthly: number,
  balance: number,
  month: number,
): Msg | null {
  const data = { type: "reminder", screen: "balance" };
  if (type === "monthly") {
    if (monthly <= 0) return null;
    const owed = balance > monthly + 1
      ? ` • رصيدك المستحق: ${egp(balance)} ج.م`
      : "";
    return {
      title: "قسط الصيانة الشهري",
      body: `قسط شهر ${MONTHS[month - 1]}: ${egp(monthly)} ج.م${owed}`,
      data,
    };
  }
  // Overdue: owes more than the current month's installment.
  if (balance <= Math.max(monthly, 0) + 1) return null;
  return {
    title: "تذكير بالمتأخرات",
    body: `عليك مبلغ ${egp(balance)} ج.م مستحق السداد. برجاء السداد في أقرب وقت.`,
    data,
  };
}

// ── Delivery ────────────────────────────────────────────────────────────────

/// Sends [msg] to an owner's device; clears a token FCM says is gone. The
/// token is cleared through set_document (a JSONB merge in Postgres): writing
/// the whole owner back from JS would round its int64 `Id` and break the
/// account.
async function deliver(
  docId: string,
  token: string,
  msg: Msg,
): Promise<boolean> {
  const res = await sendToToken(token, msg.title, msg.body, msg.data);
  if (res.unregistered) {
    await supabase.rpc("set_document", {
      p_uid: WORKSPACE_UID,
      p_collection: "owners",
      p_doc_id: docId,
      p_data: { FcmToken: "" },
      p_merge: true,
    });
  }
  return res.ok;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}

/// Monthly / overdue reminders for every owner with a device. Each owner gets
/// each type at most once per month (a marker row in `owner_notify_log`), so
/// a retried cron run doesn't repeat messages.
async function sendReminders(type: string): Promise<Response> {
  if (type !== "monthly" && type !== "overdue") {
    return json({ error: "bad_type" }, 400);
  }
  const cairo = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Africa/Cairo",
    year: "numeric",
    month: "2-digit",
  }).format(new Date()); // "2026-11"
  const [year, month] = cairo.split("-").map(Number);

  const { data: targets, error } = await supabase.rpc(
    "owner_reminder_targets",
    { p_year: year },
  );
  if (error) return json({ error: "targets_failed" }, 500);

  let sent = 0;
  let skipped = 0;
  for (const t of (targets ?? []) as Array<Record<string, unknown>>) {
    const msg = reminderFor(
      type,
      Number(t.monthly) || 0,
      Number(t.balance) || 0,
      month,
    );
    if (!msg) continue;
    const marker = `${type}:${cairo}:${t.owner_id}`;
    // The insert is the lock: a second run for the same month conflicts here.
    const { error: dup } = await supabase.from("documents").insert({
      uid: WORKSPACE_UID,
      collection: "owner_notify_log",
      doc_id: marker,
      data: { Type: type, Month: cairo, OwnerId: String(t.owner_id), At: new Date().toISOString() },
    });
    if (dup) {
      skipped++;
      continue;
    }
    if (await deliver(String(t.doc_id), String(t.fcm), msg)) sent++;
  }
  return json({ type, month: cairo, sent, skipped });
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("ok");
  // Every caller is our own trigger or cron job, which send this header.
  const sent = req.headers.get("x-push-secret") ?? "";
  if (!PUSH_TRIGGER_SECRET || sent !== PUSH_TRIGGER_SECRET) {
    // Lengths only, never the values: tells a missing or mistyped secret apart.
    console.error(
      `forbidden: expected ${PUSH_TRIGGER_SECRET.length} chars, got ${sent.length}`,
    );
    return new Response("forbidden", { status: 401 });
  }
  if (!SERVICE_ACCOUNT.private_key || !SERVICE_ACCOUNT.project_id) {
    console.error("FCM_SERVICE_ACCOUNT is not a service-account JSON");
    return json({ error: "fcm_not_configured" }, 500);
  }

  let payload: Record<string, any>;
  try {
    payload = await req.json();
  } catch {
    return new Response("bad request", { status: 400 });
  }

  // A payload without `kind` is the original payment push, so the existing
  // payment trigger keeps working untouched.
  const kind = String(payload.kind ?? "owner_transaction");
  if (kind === "reminders") return await sendReminders(String(payload.type ?? ""));

  // Only notify on actual payments (سداد), not charges/other rows.
  const txType = String(payload.tx_type ?? "").toUpperCase();
  if (kind === "owner_transaction" && txType !== "PAYMENT") {
    return json({ skipped: txType });
  }
  const ownerIdText = String(payload.owner_id ?? "").trim();
  if (!ownerIdText) return json({ sent: 0, reason: "no_owner" });

  let msg: Msg;
  if (kind === "service_status") {
    msg = statusMessageFor(
      String(payload.status ?? ""),
      String(payload.admin_note ?? ""),
      String(payload.request_id ?? "").trim(),
    );
  } else if (kind === "visitor_arrived") {
    msg = visitorMessageFor(
      String(payload.visitor_name ?? ""),
      String(payload.gate ?? ""),
    );
  } else {
    msg = messageFor(String(payload.amount ?? ""), String(payload.description ?? ""));
  }

  // Look up the owner's FCM token (exact text id match — int64-safe).
  const { data: rows, error } = await supabase
    .from("documents")
    .select("doc_id, data->>FcmToken")
    .eq("uid", WORKSPACE_UID)
    .eq("collection", "owners")
    .eq("data->>Id", ownerIdText)
    .limit(1);
  if (error) {
    console.error("read owner", error);
    return new Response("error", { status: 500 });
  }
  const owner = (rows ?? [])[0] as { doc_id: string; FcmToken?: string } | undefined;
  const token = String(owner?.FcmToken ?? "");
  if (!owner || !token) return json({ sent: 0, reason: "no_token" });

  const ok = await deliver(owner.doc_id, token, msg);
  return json({ sent: ok ? 1 : 0 });
});
