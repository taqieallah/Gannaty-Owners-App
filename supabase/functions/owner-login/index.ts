// Supabase Edge Function: owner-login
// ---------------------------------------------------------------------------
// Verifies an owner's phone + password against the `documents` table (owners
// collection) using the service role, then mints a short-lived Supabase JWT
// carrying an `owner_id` claim. The client uses this token as its Supabase
// access token (third-party auth), and RLS scopes every read/write to that
// owner via `auth.jwt() ->> 'owner_id'`.
//
// This replaces the old "sign in anonymously + filter client-side" model, in
// which any anonymous user was effectively an admin.
//
// Required function secrets (set with `supabase secrets set`):
//   OWNERS_WORKSPACE_UID   the workspace partition uid (owners live here)
//   APP_JWT_SECRET         the project's legacy JWT secret (Dashboard →
//                          Settings → API → JWT Settings → JWT Secret)
// Automatically injected by the platform:
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
//
// Deploy:  supabase functions deploy owner-login --no-verify-jwt
//   (--no-verify-jwt because callers are unauthenticated at login time.)
// ---------------------------------------------------------------------------

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { create, getNumericDate } from "https://deno.land/x/djwt@v3.0.2/mod.ts";
import { compare as bcryptCompare } from "https://deno.land/x/bcrypt@v0.4.1/mod.ts";

const WORKSPACE_UID = Deno.env.get("OWNERS_WORKSPACE_UID") ?? "";
const JWT_SECRET = Deno.env.get("APP_JWT_SECRET") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const TOKEN_TTL_SECONDS = 60 * 60 * 24 * 30; // 30 days

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

// Egyptian phone normalization — mirrors the Dart client so lookups match.
function normalizePhone(value: string): string {
  const arabicIndic: Record<string, string> = {
    "٠": "0", "١": "1", "٢": "2", "٣": "3", "٤": "4",
    "٥": "5", "٦": "6", "٧": "7", "٨": "8", "٩": "9",
  };
  let n = (value ?? "").trim();
  for (const [src, tgt] of Object.entries(arabicIndic)) n = n.split(src).join(tgt);
  n = n.replace(/[^0-9+]/g, "");
  if (n.startsWith("+20")) n = "0" + n.slice(3);
  else if (n.startsWith("20") && n.length > 10) n = "0" + n.slice(2);
  if (n.startsWith("0020")) n = "0" + n.slice(4);
  return n;
}

// A deterministic UUID (v5-like) from the owner id, used as the JWT `sub`.
async function ownerSub(ownerId: string): Promise<string> {
  const data = new TextEncoder().encode(`gannaty-owner-${ownerId}`);
  const hash = new Uint8Array(await crypto.subtle.digest("SHA-256", data));
  const h = [...hash.slice(0, 16)].map((b) => b.toString(16).padStart(2, "0")).join("");
  return `${h.slice(0, 8)}-${h.slice(8, 12)}-${h.slice(12, 16)}-${h.slice(16, 20)}-${h.slice(20, 32)}`;
}

async function hmacKey(secret: string): Promise<CryptoKey> {
  return await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign", "verify"],
  );
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  if (!WORKSPACE_UID || !JWT_SECRET || !SUPABASE_URL || !SERVICE_ROLE) {
    return json({ error: "server_misconfigured" }, 500);
  }

  let phone = "";
  let password = "";
  let fcmToken: string | null = null;
  try {
    const body = await req.json();
    phone = String(body.phone ?? "");
    password = String(body.password ?? "");
    fcmToken = body.fcmToken != null ? String(body.fcmToken) : null;
  } catch {
    return json({ error: "bad_request" }, 400);
  }
  if (!phone || !password) return json({ error: "missing_credentials" }, 400);

  const admin = createClient(SUPABASE_URL, SERVICE_ROLE, {
    auth: { persistSession: false },
  });

  // Load the owners for this workspace (small set) and match by phone.
  const { data: rows, error } = await admin
    .from("documents")
    .select("doc_id, data")
    .eq("uid", WORKSPACE_UID)
    .eq("collection", "owners");
  if (error) return json({ error: "lookup_failed" }, 500);

  const wanted = normalizePhone(phone);
  const match = (rows ?? []).find((r: any) => {
    const p = normalizePhone(String(r.data?.Phone ?? ""));
    return p.length > 0 && p === wanted;
  });
  if (!match) return json({ error: "phone_not_found" }, 401);

  const d = match.data ?? {};
  const stored = String(d.Password ?? "").trim();
  const isDefault = stored === "" || stored === "123456";

  // Verify: bcrypt if the stored value is hashed, else plaintext (transition).
  let ok = false;
  if (isDefault) {
    ok = password.trim() === "123456" || stored === password.trim();
  } else if (stored.startsWith("$2")) {
    try { ok = await bcryptCompare(password, stored); } catch { ok = false; }
  } else {
    ok = password.trim() === stored;
  }
  if (!ok) return json({ error: "wrong_password" }, 401);

  // Exact int64 Id as text — owner Ids exceed JS safe-integer range, so we
  // fetch data->>'Id' via a service-role RPC (SQL keeps it exact) rather than
  // reading the precision-lost parsed number.
  const { data: idText } = await admin.rpc("owner_id_text_by_docid", {
    p_doc_id: match.doc_id,
  });
  const ownerIdText = String(idText ?? "").trim();
  if (!ownerIdText) return json({ error: "owner_missing_id" }, 500);

  // Best-effort: persist the FCM token on the owner doc (service role).
  if (fcmToken) {
    try {
      await admin.rpc("set_document", {
        p_uid: WORKSPACE_UID,
        p_collection: "owners",
        p_doc_id: match.doc_id,
        p_data: { FcmToken: fcmToken },
        p_merge: true,
      });
    } catch { /* non-critical */ }
  }

  const now = getNumericDate(0);
  const payload = {
    role: "authenticated",
    aud: "authenticated",
    iss: `${SUPABASE_URL}/auth/v1`,
    sub: await ownerSub(ownerIdText),
    owner_id: ownerIdText,
    phone: normalizePhone(String(d.Phone ?? "")),
    iat: now,
    exp: getNumericDate(TOKEN_TTL_SECONDS),
  };

  const token = await create(
    { alg: "HS256", typ: "JWT" },
    payload,
    await hmacKey(JWT_SECRET),
  );

  // Return the token plus the owner's public profile (never the password).
  return json({
    access_token: token,
    expires_in: TOKEN_TTL_SECONDS,
    owner: {
      Id: ownerIdText,
      Name: String(d.Name ?? ""),
      VillaNo: String(d.VillaNo ?? ""),
      Phone: String(d.Phone ?? ""),
      VillaArea: d.VillaArea ?? 0,
      InitialMaintenance: d.InitialMaintenance ?? 0,
      DepositPaid: d.DepositPaid ?? 0,
      IsFirstLogin: (d.IsFirstLogin as boolean | undefined) ?? isDefault,
      CreatedAt: d.CreatedAt ?? null,
    },
  });
});
