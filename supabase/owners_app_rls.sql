-- ============================================================================
-- Owners App (client) — Supabase RLS
-- ----------------------------------------------------------------------------
-- The client app signs in ANONYMOUSLY (after validating the owner's
-- phone+password against their owner record) and reads its data from the shared
-- `documents` table. This mirrors the old Firebase model (any authenticated user
-- — including anonymous — could read owner/compound data; the app filters by
-- phone). Run once in the Supabase SQL Editor.
--
-- PREREQUISITE: enable anonymous sign-ins:
--   Dashboard → Authentication → Providers → Anonymous → ON.
-- ============================================================================

-- Collections the client app may READ under the workspace partition.
create or replace function public.is_owners_app_collection(c text)
returns boolean language sql immutable as $$
  select c in (
    'owners','owner_transactions','owner_year_settings','owner_statements',
    'revenues','attachments','villas','payments','serviceRequests',
    'annualSettlements','annualSettings','announcements','config'
  );
$$;

-- READ: any authenticated user (incl. anonymous client) can read the
-- owners-app collections for the workspace. The app filters by phone.
drop policy if exists owners_app_read on public.documents;
create policy owners_app_read on public.documents
  for select
  to authenticated
  using (
    uid = '5nCpbFKDt1NyrXCw56HaattDVT42'
    and public.is_owners_app_collection(collection)
  );

-- INSERT: clients may create service requests.
drop policy if exists owners_app_insert_requests on public.documents;
create policy owners_app_insert_requests on public.documents
  for insert
  to authenticated
  with check (
    uid = '5nCpbFKDt1NyrXCw56HaattDVT42'
    and collection = 'serviceRequests'
  );

-- UPDATE: clients may update their own owner/villa doc (e.g. set password) and
-- their service requests. (App enforces the phone match; this keeps writes
-- scoped to the owners-app collections.)
drop policy if exists owners_app_update on public.documents;
create policy owners_app_update on public.documents
  for update
  to authenticated
  using (
    uid = '5nCpbFKDt1NyrXCw56HaattDVT42'
    and collection in ('owners','villas','serviceRequests')
  )
  with check (
    uid = '5nCpbFKDt1NyrXCw56HaattDVT42'
    and collection in ('owners','villas','serviceRequests')
  );

-- NOTE: the set_document RPC is SECURITY INVOKER, so these policies also govern
-- writes made through it (owners app password updates / service requests).
-- The full ERP admin still has full access via the workspace_members policy.
