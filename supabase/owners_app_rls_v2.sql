-- ============================================================================
-- Owners App (client) — Supabase RLS v2: per-owner scoping via custom JWT.
-- ----------------------------------------------------------------------------
-- Replaces owners_app_rls.sql (the "anonymous can read/write everything" model).
--
-- Model: the client authenticates through the `owner-login` Edge Function
-- (verifies phone+password server-side) and receives a JWT carrying an
-- `owner_id` (and `phone`) claim. The Flutter client uses that token as its
-- Supabase access token (third-party auth). These policies scope every read
-- and write to the calling owner via that claim.
--
-- PREREQUISITES (do these too):
--   1) Deploy the edge function:  supabase functions deploy owner-login --no-verify-jwt
--   2) Dashboard → Authentication → Providers → Anonymous → OFF  (critical)
--   3) Run this whole file in the SQL Editor.
-- ============================================================================

create extension if not exists pgcrypto;

-- ── Helpers ─────────────────────────────────────────────────────────────────

-- owner_id from the caller's JWT (null when the token is not an owner token).
create or replace function public.jwt_owner_id()
returns int language sql stable as $$
  select nullif(
    current_setting('request.jwt.claims', true)::jsonb ->> 'owner_id', ''
  )::int;
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

-- ── Drop the old permissive policies ────────────────────────────────────────
drop policy if exists owners_app_read on public.documents;
drop policy if exists owners_app_insert_requests on public.documents;
drop policy if exists owners_app_update on public.documents;

-- ── READ: owner-account data, scoped to the calling owner ───────────────────
drop policy if exists owners_app_read_own on public.documents;
create policy owners_app_read_own on public.documents
  for select to authenticated
  using (
    uid = '5nCpbFKDt1NyrXCw56HaattDVT42'
    and public.jwt_owner_id() is not null
    and (
         (collection = 'owners'             and (data->>'Id')::int      = public.jwt_owner_id())
      or (collection = 'owner_transactions' and (data->>'OwnerId')::int = public.jwt_owner_id())
      or (collection = 'owner_year_settings'and (data->>'OwnerId')::int = public.jwt_owner_id())
      or (collection = 'owner_statements'   and (data->>'OwnerId')::int = public.jwt_owner_id())
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
-- policy above. Restricting to only the collections the client actually needs.
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
-- writes go through the SECURITY DEFINER RPCs below, which are scoped to the
-- caller's own owner_id — closing the account-takeover hole. The full ERP admin
-- keeps its access via the separate workspace_members policy.

-- ── RPC: change own password (verifies current, stores bcrypt) ──────────────
create or replace function public.owners_app_set_password(p_current text, p_new text)
returns boolean language plpgsql security definer set search_path = public as $$
declare
  v_uid constant text := '5nCpbFKDt1NyrXCw56HaattDVT42';
  v_owner int := public.jwt_owner_id();
  v_doc text;
  v_stored text;
begin
  if v_owner is null then raise exception 'not_owner'; end if;
  if length(coalesce(p_new, '')) < 4 then raise exception 'weak_password'; end if;

  select doc_id, data->>'Password' into v_doc, v_stored
  from public.documents
  where uid = v_uid and collection = 'owners' and (data->>'Id')::int = v_owner
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
  v_owner int := public.jwt_owner_id();
  v_doc text;
begin
  if v_owner is null then raise exception 'not_owner'; end if;
  select doc_id into v_doc from public.documents
  where uid = v_uid and collection = 'owners' and (data->>'Id')::int = v_owner
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
