# Owners App — Security Hardening Runbook

This turns the owners client app from "anonymous = everyone can read/write
everything" into **per-owner authorization** via a custom `owner_id` JWT.

**Do all steps on a test build with 1–2 owner accounts before releasing to the
84 owners.** The app will not work against the new RLS until steps 1–4 are done.

## What changed in the code (already committed)
- `supabase/functions/owner-login/index.ts` — Edge Function: verifies
  phone+password server-side (bcrypt or plaintext during transition) and mints
  a signed JWT with an `owner_id` claim.
- `supabase/owners_app_rls_v2.sql` — new RLS scoped by that claim + secure
  `owners_app_set_password` / `owners_app_save_fcm` RPCs. Removes the old
  anonymous-read-all and the account-takeover UPDATE policy.
- Client (`compound_core` + `client_app`): login now calls the function, holds
  the returned token as Supabase's access token (third-party auth), and no
  longer signs in anonymously or compares passwords on the device.

## Deploy steps (run on your machine / Supabase dashboard)

1. **Set function secrets.** Get the JWT secret from
   Dashboard → Settings → API → **JWT Settings → JWT Secret** (the legacy HS256
   secret). Then:
   ```bash
   supabase secrets set \
     APP_JWT_SECRET='<the JWT secret>' \
     OWNERS_WORKSPACE_UID='5nCpbFKDt1NyrXCw56HaattDVT42'
   ```
2. **Deploy the function** (unauthenticated callers at login time):
   ```bash
   supabase functions deploy owner-login --no-verify-jwt
   ```
3. **Run the RLS** — paste all of `supabase/owners_app_rls_v2.sql` into the
   SQL Editor and run it.
4. **Disable anonymous auth:** Dashboard → Authentication → Providers →
   **Anonymous → OFF**. (This is what closes the "anyone with the public key is
   admin" hole.)

## Test checklist (before releasing)
- [ ] Login with a real owner phone + password succeeds; wrong password fails.
- [ ] Account balance, transactions, statement, announcements all load.
- [ ] Submit a service request; it appears in "my requests" and to the admin.
- [ ] Change password succeeds; re-login with the NEW password works; the OLD
      one fails. (New passwords are stored bcrypt-hashed.)
- [ ] A second owner CANNOT see the first owner's account/transactions
      (verify by inspecting network, or trust the RLS scope).
- [ ] App restart restores the session (token valid ~30 days); after expiry it
      returns to the login screen.

## Key thing to verify (JWT acceptance)
The client sends the function's HS256 token as its Supabase access token. The
project must accept tokens signed with the legacy JWT secret. If reads return
`permission denied`/empty **even when logged in**, the legacy secret is likely
disabled — re-enable it (or switch the function to sign with the project's
active signing key) and retest. Also confirm `bcrypt` runs in the Edge runtime
(the password check); if it errors, the login returns `wrong_password`.

## Known residual (tighten later)
`revenues` / `attachments` (receipt data) are not per-owner in the schema, so a
logged-in owner can read other owners' receipt rows. The v2 RLS still removes
ALL anonymous/public access to them. To fully scope: tag each revenue/attachment
row with an owner link (e.g. `OwnerId`) on the ERP side, then move those
collections into the scoped `owners_app_read_own` policy.

## Rollback
Re-run the old `supabase/owners_app_rls.sql`, re-enable Anonymous auth, and
deploy the previous app build.
