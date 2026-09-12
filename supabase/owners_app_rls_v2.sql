-- ============================================================================
-- Owners App (client) — Supabase RLS v2: per-owner scoping via custom JWT.
-- ----------------------------------------------------------------------------
-- Replaces owners_app_rls.sql (the "anonymous can read/write everything" model).
--
-- Model: the client authenticates through the `owner-login` Edge Function
-- (verifies phone+password server-side) and receives a JWT carrying an
-- `owner_id` claim — the owner's EXACT numeric Id AS TEXT (owner Ids are int64
-- values beyond JS/int4 range, so everything compares as text). RLS scopes
-- every read and write to that owner via that claim.
--
-- PREREQUISITES:
--   1) Deploy the edge function:  supabase functions deploy owner-login --no-verify-jwt
--   2) Set secrets: APP_JWT_SECRET (= the project's Legacy JWT Secret, which
--      still verifies HS256 tokens) and OWNERS_WORKSPACE_UID.
--   3) Dashboard → Authentication → Providers → Anonymous → OFF.
--   4) Run this whole file in the SQL Editor.
-- ============================================================================

create extension if not exists pgcrypto;

-- ── Idempotent teardown ─────────────────────────────────────────────────────
-- Drop the policies that depend on the helper functions, then drop the helper
-- whose return type is changing (int -> text on re-run), so this file can be
-- run repeatedly without a "cannot change return type" error.
drop policy if exists owners_app_read on public.documents;
drop policy if exists owners_app_read_own on public.documents;
drop policy if exists owners_app_read_shared on public.documents;
drop policy if exists owners_app_insert_requests on public.documents;
drop policy if exists owners_app_update on public.documents;
drop policy if exists owners_app_request_uploads on storage.objects;
drop function if exists public.jwt_owner_id();

-- ── Helpers ─────────────────────────────────────────────────────────────────

-- The owner_id claim from the caller's JWT, as TEXT (null when absent/empty).
create or replace function public.jwt_owner_id()
returns text language sql stable as $$
  select nullif(
    current_setting('request.jwt.claims', true)::jsonb ->> 'owner_id', ''
  );
$$;

-- phone claim from the caller's JWT.
create or replace function public.jwt_phone()
returns text language sql stable as $$
  select current_setting('request.jwt.claims', true)::jsonb ->> 'phone';
$$;

-- Egyptian phone normalization — mirrors the Dart client and edge function.
create or replace function public.normalize_eg_phone(v text)
returns text language plpgsql immutable as $$
declare n text := coalesce(v, '');
begin
  n := translate(n, '٠١٢٣٤٥٦٧٨٩', '0123456789');
  n := regexp_replace(n, '[^0-9+]', '', 'g');
  if left(n, 3) = '+20' then
    n := '0' || substr(n, 4);
  elsif left(n, 2) = '20' and length(n) > 10 then
    n := '0' || substr(n, 3);
  end if;
  if left(n, 4) = '0020' then
    n := '0' || substr(n, 5);
  end if;
  return n;
end $$;

-- Exact owner Id (int64) as TEXT for a given owner doc — called by the
-- owner-login Edge Function (service role) so the id never passes through a
-- JS number. Restricted to service_role.
create or replace function public.owner_id_text_by_docid(p_doc_id text)
returns text language sql security definer set search_path = public as $$
  select data->>'Id' from public.documents
  where uid = '5nCpbFKDt1NyrXCw56HaattDVT42'
    and collection = 'owners' and doc_id = p_doc_id
  limit 1;
$$;
revoke all on function public.owner_id_text_by_docid(text) from public, authenticated;
grant execute on function public.owner_id_text_by_docid(text) to service_role;

-- Verify an owner's password server-side using the SAME pgcrypto that created
-- the bcrypt hash (avoids Deno/Postgres bcrypt incompatibility). Called by the
-- owner-login Edge Function (service role). Returns true when the password is
-- correct (bcrypt hash, plaintext transition value, or the 123456 default).
create or replace function public.owner_check_password(p_doc_id text, p_password text)
returns boolean language plpgsql security definer
set search_path = public, extensions as $$
declare v_stored text;
begin
  select data->>'Password' into v_stored from public.documents
  where uid = '5nCpbFKDt1NyrXCw56HaattDVT42'
    and collection = 'owners' and doc_id = p_doc_id
  limit 1;
  if v_stored is null then return false; end if;
  if v_stored = '' or v_stored = '123456' then
    return coalesce(p_password, '') = '123456' or coalesce(p_password, '') = v_stored;
  elsif v_stored like '$2%' then
    return crypt(coalesce(p_password, ''), v_stored) = v_stored;
  else
    return coalesce(p_password, '') = v_stored;
  end if;
end $$;
revoke all on function public.owner_check_password(text, text) from public, authenticated;
grant execute on function public.owner_check_password(text, text) to service_role;

-- ── Drop the old permissive policies ────────────────────────────────────────
drop policy if exists owners_app_read on public.documents;
drop policy if exists owners_app_insert_requests on public.documents;
drop policy if exists owners_app_update on public.documents;

-- ── READ: owner-account data, scoped to the calling owner (TEXT id match) ────
drop policy if exists owners_app_read_own on public.documents;
create policy owners_app_read_own on public.documents
  for select to authenticated
  using (
    uid = '5nCpbFKDt1NyrXCw56HaattDVT42'
    and public.jwt_owner_id() is not null
    and (
         (collection = 'owners'             and data->>'Id'      = public.jwt_owner_id())
      or (collection = 'owner_transactions' and data->>'OwnerId' = public.jwt_owner_id())
      or (collection = 'owner_year_settings'and data->>'OwnerId' = public.jwt_owner_id())
      or (collection = 'owner_statements'   and data->>'OwnerId' = public.jwt_owner_id())
      or (collection = 'serviceRequests'    and public.normalize_eg_phone(data->>'clientPhone')
                                                = public.normalize_eg_phone(public.jwt_phone()))
      or (collection = 'announcements')   -- global to all owners
      or (collection = 'config')          -- non-sensitive workspace config
    )
  );

-- ── READ: shared receipt/legacy collections — any authenticated OWNER ───────
-- These rows are not per-owner in the current schema, so an owner can read
-- other owners' rows here. This still removes ALL anonymous/public access
-- (a valid owner JWT is now required). RESIDUAL RISK — tighten later by tagging
-- revenue/attachment rows with an owner link, then move them to the scoped
-- policy above.
drop policy if exists owners_app_read_shared on public.documents;
create policy owners_app_read_shared on public.documents
  for select to authenticated
  using (
    uid = '5nCpbFKDt1NyrXCw56HaattDVT42'
    and public.jwt_owner_id() is not null
    and collection in (
      'revenues', 'attachments', 'payments', 'villas',
      'annualSettlements', 'annualSettings'
    )
  );

-- ── INSERT: an owner may create service requests for their own phone only ───
drop policy if exists owners_app_insert_requests on public.documents;
create policy owners_app_insert_requests on public.documents
  for insert to authenticated
  with check (
    uid = '5nCpbFKDt1NyrXCw56HaattDVT42'
    and public.jwt_owner_id() is not null
    and collection = 'serviceRequests'
    and public.normalize_eg_phone(data->>'clientPhone')
        = public.normalize_eg_phone(public.jwt_phone())
  );

-- NOTE: there is deliberately NO client UPDATE/DELETE policy. Password and FCM
-- writes go through the SECURITY DEFINER RPCs below, scoped to the caller's own
-- owner_id — closing the account-takeover hole. The full ERP admin keeps its
-- access via the separate workspace_members policy.

-- ── RPC: change own password (verifies current, stores bcrypt) ──────────────
create or replace function public.owners_app_set_password(p_current text, p_new text)
returns boolean language plpgsql security definer
-- pgcrypto (crypt/gen_salt) lives in the `extensions` schema on Supabase.
set search_path = public, extensions as $$
declare
  v_uid constant text := '5nCpbFKDt1NyrXCw56HaattDVT42';
  v_owner text := public.jwt_owner_id();
  v_doc text;
  v_stored text;
begin
  if v_owner is null then raise exception 'not_owner'; end if;
  if length(coalesce(p_new, '')) < 4 then raise exception 'weak_password'; end if;

  select doc_id, data->>'Password' into v_doc, v_stored
  from public.documents
  where uid = v_uid and collection = 'owners' and data->>'Id' = v_owner
  limit 1;
  if v_doc is null then return false; end if;

  if v_stored is null or v_stored = '' or v_stored = '123456' then
    null; -- first-login / default: allow set without current password
  elsif v_stored like '$2%' then
    if crypt(coalesce(p_current, ''), v_stored) <> v_stored then
      raise exception 'wrong_password';
    end if;
  else
    if coalesce(p_current, '') <> v_stored then
      raise exception 'wrong_password';
    end if;
  end if;

  update public.documents
  set data = data || jsonb_build_object(
    'Password', crypt(p_new, gen_salt('bf')),
    'IsFirstLogin', false
  )
  where uid = v_uid and collection = 'owners' and doc_id = v_doc;
  return true;
end $$;
revoke all on function public.owners_app_set_password(text, text) from public;
grant execute on function public.owners_app_set_password(text, text) to authenticated;

-- ── RPC: save own FCM token ─────────────────────────────────────────────────
create or replace function public.owners_app_save_fcm(p_token text)
returns boolean language plpgsql security definer set search_path = public as $$
declare
  v_uid constant text := '5nCpbFKDt1NyrXCw56HaattDVT42';
  v_owner text := public.jwt_owner_id();
  v_doc text;
begin
  if v_owner is null then raise exception 'not_owner'; end if;
  select doc_id into v_doc from public.documents
  where uid = v_uid and collection = 'owners' and data->>'Id' = v_owner
  limit 1;
  if v_doc is null then return false; end if;
  update public.documents
  set data = data || jsonb_build_object('FcmToken', coalesce(p_token, ''))
  where uid = v_uid and collection = 'owners' and doc_id = v_doc;
  return true;
end $$;
revoke all on function public.owners_app_save_fcm(text) from public;
grant execute on function public.owners_app_save_fcm(text) to authenticated;

-- ── Storage: owners may upload service-request images (valid owner only) ────
drop policy if exists owners_app_request_uploads on storage.objects;
create policy owners_app_request_uploads on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'receipts'
    and public.jwt_owner_id() is not null
    and (storage.foldername(name))[1] = 'service_requests'
  );
