-- ============================================================================
-- Push the owner when the status of their service request changes
-- (pending -> in_progress -> solved).
-- ============================================================================
-- The Firebase Cloud Function that did this (onRequestStatusChanged) could never
-- fire once the app moved to Supabase, so owners were not told when a request
-- was taken up or resolved. This restores it.
--
-- Deploy the function first (it learned a second kind of message):
--   supabase functions deploy push-owner-transaction --no-verify-jwt \
--     --project-ref hgfrtxktcucqucanfqhi
-- A payload with no `kind` is still the payment push, so the existing payment
-- trigger is untouched.
--
-- Then run this once in the SQL Editor after replacing the ONE placeholder:
--   __PUSH_SECRET__ = the same value as the PUSH_TRIGGER_SECRET secret.
--   (Tip: copy it from the existing trigger:
--      select prosrc from pg_proc where proname = 'notify_owner_transaction';
--    it is the value after 'x-push-secret'.)
-- Idempotent -- safe to re-run.
-- ============================================================================

create extension if not exists pg_net with schema extensions;

create or replace function public.notify_service_request_status()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_phone    text := public.normalize_eg_phone(new.data->>'clientPhone');
  v_owner_id text;
begin
  -- The whole body is guarded: a notification problem must never block the
  -- admin from saving the status change.
  begin
    -- A request with no usable phone would match an owner with no phone.
    if v_phone = '' then
      return new;
    end if;

    -- Requests carry the owner's phone, not their id, so find the owner the
    -- same way the owners app's RLS does. The id is read as TEXT: owner ids
    -- are int64 beyond what JSON numbers can hold.
    select o.data->>'Id' into v_owner_id
    from public.documents o
    where o.uid = new.uid
      and o.collection = 'owners'
      and public.normalize_eg_phone(o.data->>'Phone') = v_phone
      and coalesce(o.data->>'Id', '') <> ''
    limit 1;

    if v_owner_id is null then
      return new;
    end if;

    perform net.http_post(
      url     := 'https://hgfrtxktcucqucanfqhi.functions.supabase.co/push-owner-transaction',
      headers := jsonb_build_object(
        'content-type', 'application/json',
        'x-push-secret', '__PUSH_SECRET__'
      ),
      body    := jsonb_build_object(
        'kind',       'service_status',
        'owner_id',   v_owner_id,
        'request_id', new.doc_id,
        'status',     new.data->>'status',
        'admin_note', coalesce(new.data->>'adminNote', '')
      )
    );
  exception when others then
    null;
  end;
  return new;
end;
$$;

-- The WHEN clause keeps Postgres from calling the function for every one of the
-- documents-table updates; only a real status change on a service request does.
drop trigger if exists trg_notify_service_request_status on public.documents;
create trigger trg_notify_service_request_status
  after update on public.documents
  for each row
  when (new.collection = 'serviceRequests'
        and old.data->>'status' is distinct from new.data->>'status')
  execute function public.notify_service_request_status();
