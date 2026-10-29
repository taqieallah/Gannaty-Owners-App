-- Owners app — security hardening v3 (before distributing the app)
--
-- Found in a review of the live project on 2026-10-29:
--   1. owner_check_password / owner_id_text_by_docid are SECURITY DEFINER and
--      callable by `anon`, so anyone with the public key could test passwords
--      with no lockout (the owner-login function's lockout doesn't apply).
--      Only the owner-login Edge Function (service role) needs them.
--   2. owner_login / owner_set_password (the older RPC login path) are also
--      callable by `anon`. Neither app calls them any more.
--   3. receipts_auth_read let every `authenticated` token — including every
--      owner token — list and read the whole receipts bucket: other owners'
--      statements, claims and receipts. Staff (workspace members) keep full
--      read; owners keep only their own reports and their service-request
--      uploads. Shared public links (/object/public/...) are unaffected: a
--      public bucket serves those without consulting RLS.
--
-- Run in the SQL editor of project hgfrtxktcucqucanfqhi. Safe to re-run.

-- 1 + 2: server-only functions --------------------------------------------
revoke execute on function public.owner_check_password(text, text)
  from public, anon, authenticated;
revoke execute on function public.owner_id_text_by_docid(text)
  from public, anon, authenticated;
revoke execute on function public.owner_login(text, text, text)
  from public, anon, authenticated;
revoke execute on function public.owner_set_password(text, text, text, text)
  from public, anon, authenticated;
grant execute on function public.owner_check_password(text, text) to service_role;
grant execute on function public.owner_id_text_by_docid(text) to service_role;

-- owner_reset_password already checks for an admin member; signed-out callers
-- have no reason to reach it.
revoke execute on function public.owner_reset_password(text, text)
  from public, anon;

-- 3: receipts read scope --------------------------------------------------
drop policy if exists receipts_auth_read on storage.objects;
create policy receipts_auth_read on storage.objects
  for select to authenticated
  using (
    bucket_id = 'receipts'
    and (
      exists (
        select 1 from public.workspace_members m
        where m.auth_uid = (select auth.uid())
      )
      or (
        public.jwt_owner_id() is not null
        and (
          name like '%owner_reports/' || public.jwt_owner_id() || '/%'
          or (storage.foldername(name))[1] = 'service_requests'
        )
      )
    )
  );
