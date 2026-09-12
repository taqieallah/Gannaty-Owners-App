# Gannaty — Compound Management System (Project Overview)

> Handoff document for engineers **and AI agents**. It describes the whole
> system end‑to‑end so you can make changes safely without re‑discovering the
> architecture. Arabic‑first, RTL product for **اتحاد شاغلي كمبوند جنتي**.

---

## 1. The two apps + one backend

| App | Repo / path | Platform | Users | Backend |
|---|---|---|---|---|
| **Owners app** (`client_app`) | `D:\Gannaty-Owners-App` (this repo), `apps/client_app` | Android (primary), iOS/desktop possible | ~84 compound owners | **Supabase** (branch `supabase`) |
| **Admin app** (`admin_app`) | same repo, `apps/admin_app` | — | compound admin | Firebase (legacy, not the focus) |
| **ERP** (compound management) | `D:\gannaty-macos-important-files` | Windows desktop (Flutter/CMake) | 1 admin (the union manager) | **Supabase** (branch `supabase`) |

- The owners app is a **melos monorepo**: `apps/client_app`, `apps/admin_app`,
  shared package `packages/compound_core` (models, repositories, cloud layer).
- **The owners app and the ERP share ONE Supabase project** — same project,
  same `documents` table, same workspace uid. Their traffic shares one egress
  budget. This is the single most important fact for cost/security.

**Supabase project:** ref `hgfrtxktcucqucanfqhi`, url
`https://hgfrtxktcucqucanfqhi.supabase.co`. Workspace uid (data partition):
`5nCpbFKDt1NyrXCw56HaattDVT42`.

---

## 2. Data model — the `documents` table

Everything lives in **one Postgres table** that emulates a document store:

```
public.documents ( uid text, collection text, doc_id text, data jsonb )
```

- `uid` = workspace partition (always `5nCpbFKDt1NyrXCw56HaattDVT42`).
- `collection` = logical collection name (see below).
- `doc_id` = the document id (string).
- `data` = the document body (JSON).

Writes go through the `set_document(p_uid, p_collection, p_doc_id, p_data, p_merge)`
RPC. Reads are plain `select ... where uid = ? and collection = ? [and data->>field = ?]`.

**Firestore‑style path mapping** (used by the ERP's `firestore_shim.dart`):
`users/<uid>/<collection>/<doc_id>` ⇢ `(uid, collection, doc_id)`.

### Collections the owners app touches
| collection | written by | read by owner app | notes |
|---|---|---|---|
| `owners` | ERP | yes (own row) | owner accounts: `Id`, `VillaNo`, `Name`, `Phone`, `Password`, `IsFirstLogin`, `FcmToken`, financials |
| `owner_transactions` | ERP | yes (own, by `OwnerId`) | ledger: `TxType` `PAYMENT`/`CHARGE`, `Amount`, `TxDate`, `Category` |
| `owner_statements` | ERP | yes (own, by `OwnerId`) | precomputed yearly statement (**authoritative balance**): `Year`, `TotalPayments`, `TotalCharges`, `ClosingBalance`, `Maintenance` |
| `owner_year_settings` | ERP | yes | per‑year settings |
| `serviceRequests` | owners app (insert) + ERP (status) | yes (own, by `clientPhone`) | `villaId`, `villaNumber`, `clientPhone`, `clientName`, `type`, `description`, `status`, `imageUrl`, `createdAt` |
| `announcements` | ERP | yes (all) | `title`, `body`, `createdAt` |
| `revenues`, `attachments` | ERP | yes (receipts) | receipt lookup; **not per‑owner scoped** (residual) |

> ⚠️ **Owner `Id` is an int64 beyond JS/`int4` range** (e.g. `-723953584590969500`).
> Always handle it **as text** (never a JS number, never `::int` in SQL —
> use text compare). The owner's `doc_id` is a *different* value from `Id`.

---

## 3. Auth

### Owners (custom‑JWT via Edge Function)
1. Client calls the **`owner-login`** Edge Function with `{phone, password}`.
2. The function (service role) finds the owner by normalized phone, verifies the
   password **in Postgres** via `owner_check_password` (pgcrypto bcrypt or
   plaintext transition or the `123456` default), fetches the exact `Id` as text
   via `owner_id_text_by_docid`, and mints an **HS256 JWT** signed with the
   project's **legacy JWT secret** (`APP_JWT_SECRET`), carrying
   `owner_id` (exact text) + `phone` claims + `role: authenticated`.
3. The client runs supabase‑flutter in **third‑party‑auth mode**
   (`Supabase.initialize(accessToken: () => token)`), so that JWT authorizes all
   REST + Realtime calls. RLS scopes every read/write to that owner via the
   `owner_id` claim (text compare).
4. First login (`IsFirstLogin` or password `123456`) forces the set‑password
   screen → `owners_app_set_password(current, new)` (bcrypt, own row only).
5. Password reset (from the ERP) → `owner_reset_password(p_workspace, p_owner_no)`
   → sets `Password='123456'`, `IsFirstLogin=true` (SECURITY DEFINER, admin‑only).

> The **legacy HS256 JWT secret** must stay enabled (it is a "previous key" that
> still verifies tokens). If reads return `permission denied` even when logged in,
> the secret was rotated/disabled or `APP_JWT_SECRET` doesn't match it.

### Admin / ERP
The ERP authenticates as a real Supabase user that has a `workspace_members`
row (`workspace_uid` + `auth_uid`) → full RLS access to the workspace.

### RLS (owners app) — `supabase/owners_app_rls_v2.sql`
- Reads scoped by `jwt_owner_id()` (text): owners→`Id`, transactions/statements/
  year_settings→`OwnerId`, serviceRequests→`clientPhone`(normalized), announcements
  + config global; receipt collections require a valid owner token (residual: not
  per‑owner).
- Inserts: serviceRequests only, own phone. No client UPDATE/DELETE — password/FCM
  go through SECURITY DEFINER RPCs.
- **Anonymous sign‑ins must be OFF.**

---

## 4. Backend files (deploy targets)

Owners app repo — `supabase/`:
- `functions/owner-login/index.ts` — login + JWT mint.
- `functions/push-owner-transaction/index.ts` — FCM push to an owner on a new PAYMENT.
- `owners_app_rls_v2.sql` — RLS + `owner_check_password` / `owners_app_set_password` /
  `owners_app_save_fcm` / `owner_id_text_by_docid`.
- `push_owner_transaction.sql` — trigger (owner_transactions INSERT → push function).
- `fix_service_request_trigger.sql` — `notify_service_request` (fixed URL + never
  aborts the insert).
- `SECURITY_RUNBOOK.md` — deploy steps.

ERP repo — `supabase/`:
- `functions/push-service-request`, `functions/ai-assistant`, `functions/telegram-expense-bot`.
- `push_notifications.sql`, `owner_auth.sql`, `fix_owner_reset_password.sql`.

Deploy a function: `supabase functions deploy <name> --no-verify-jwt --project-ref hgfrtxktcucqucanfqhi`.
SQL files: paste into the SQL Editor. Secrets:
`APP_JWT_SECRET` (legacy JWT secret), `OWNERS_WORKSPACE_UID`, `PUSH_TRIGGER_SECRET`,
`FCM_SERVICE_ACCOUNT`.

---

## 5. Owners app — code map

`apps/client_app/lib/`
- `core/providers/app_providers.dart` — **the heart**. `SessionController`
  (login/restore/biometric/signout/password), and providers:
  `currentVillaProvider`, `ownerAccountProvider` (balance — reactive: re‑runs on
  transaction + statement realtime), `ownerTransactionsStreamProvider`,
  `ownerStatementSignalProvider`, `serviceRequestsProvider`, `announcementsProvider`.
- `core/theme/app_theme.dart` — cognac/cream theme (Cairo font).
- `core/router/app_router.dart` — go_router, `ShellRoute` = `ClientShell`
  (bottom nav). Routes: `/home /balance /payments /requests(/new,/:id)
  /announcements /profile`, plus `/login /set-password /notifications`.
- `features/*/screens/*` — home, balance (account statement), payments, service
  requests (list/detail/submit), announcements, notifications, profile, auth.
- `shared/widgets/client_shell.dart` — bottom nav + the realtime
  transaction listener that shows a local notification + a receipt sheet.

`packages/compound_core/lib/`
- `cloud/supa_config.dart` (client + owner token), `cloud/supa_db.dart`
  (`list`/`queryEq`/`getById`/`set`/`watch`/**`watchWhere`** scoped realtime/`callRpc`).
- `services/auth_service.dart` (`ownerLogin` via the Edge Function).
- `services/notification_service.dart` (FCM + local notifications, `currentToken`).
- `repositories/owner_account_repository.dart`, `payment_repository.dart`,
  `service_request_repository.dart`, `announcement_repository.dart`, etc.
- `models/*` (Villa, OwnerAccount, OwnerStatement, OwnerLedgerEntry, ServiceRequest,
  Announcement, Payment).

### Key behaviours to preserve
- **Balance is authoritative from the statement** (`OwnerAccount.balance =>
  statement?.closingBalance ?? computed`). The ERP rebuilds the statement ~1.5s
  after a transaction; the client refreshes via the statement realtime signal +
  a 4s fallback refetch.
- **Realtime needs `alter table public.documents replica identity full`** so
  UPDATE/DELETE events reach the client under RLS (INSERT works without it).
- **Egress:** all client streams are server‑scoped (`watchWhere`), never full‑
  collection. Don't reintroduce full `list()` on shared collections.

---

## 6. Feature inventory (what the owner can do today)
View balance + account status • account statement (per year, with transactions)
• payments list • submit a maintenance request (with image) • track request
status • announcements • notifications history • profile + change password +
biometric unlock • push notification on a new payment.

---

## 7. Build & run
- Owners app (emulator/device): `cd apps/client_app && flutter run`.
  APK: `flutter build apk --release` (from `apps/client_app`).
- ERP (Windows): kill `GannatyCompound.exe`, then `flutter build windows --release`
  (CMake — no Gradle). APK of the ERP fails in sandboxes (Gradle loopback); build
  it in a real terminal.
- If pub cache errors ("cannot find the path"): `flutter pub get`, then if it
  recurs `flutter pub cache repair`.

---

## 8. Conventions / gotchas (read before editing)
- Owner `Id` is int64 → **text everywhere**; `doc_id ≠ Id`; transactions/statements
  link by `OwnerId` (= `Id`).
- Egyptian phone normalization: strip non‑digits, `+20`/`20…`→`0…`; the same logic
  lives in Dart, the Edge Function, and `normalize_eg_phone()` in SQL — keep them in sync.
- Passwords: bcrypt via pgcrypto (schema `extensions` on Supabase → functions set
  `search_path = public, extensions`). Never verify bcrypt in Deno.
- Postgres triggers that call Edge Functions must wrap `net.http_post` in
  `begin … exception when others then null; end;` so a push failure never aborts
  the write, and use the real function URL (no placeholders).
- The ERP compound module and the owners app must use the **same collection
  names** (e.g. `serviceRequests`, not `compound_service_requests`).
- Don't push to git or deploy without being asked. Commit trailer:
  `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.

---

## 9. Backlog / candidate features (see chat for rationale)
Online/deferred payments record + receipt upload by owner • dues reminders &
due‑date schedule • maintenance categories + priority + rating • two‑way chat with
admin on a request • documents/downloads (contracts, statements PDF) • gate QR /
visitor passes • polls / AGM voting • directory & emergency contacts • dark‑mode
polish • English localization pass • per‑owner receipt scoping (tighten
revenues/attachments RLS).
