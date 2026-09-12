-- ============================================================================
-- Background push: fire push-owner-transaction on every new owner payment, so
-- the owner's phone is notified even when the app is closed.
-- ============================================================================
-- Run once in the Supabase SQL Editor AFTER deploying the function. Replace the
-- ONE placeholder first:
--   __PUSH_SECRET__ = the same value as the PUSH_TRIGGER_SECRET secret.
--     (Tip: the existing service-request trigger already embeds it — read it
--      with:  select prosrc from pg_proc where proname = 'notify_service_request';
--      and copy the value after 'x-push-secret'.)
-- The function URL is already filled in for this project.
-- Idempotent — safe to re-run.
-- ============================================================================

create extension if not exists pg_net with schema extensions;

-- Fired for every INSERT on documents; only owner_transactions PAYMENT rows
-- reach the function. OwnerId/Amount are sent as TEXT (int64-safe). The whole
-- HTTP call is wrapped so a push failure can NEVER block saving the row.
create or replace function public.notify_owner_transaction()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if new.collection = 'owner_transactions'
     and upper(coalesce(new.data->>'TxType', '')) = 'PAYMENT' then
    begin
      perform net.http_post(
        url     := 'https://hgfrtxktcucqucanfqhi.functions.supabase.co/push-owner-transaction',
        headers := jsonb_build_object(
          'content-type', 'application/json',
          'x-push-secret', '__PUSH_SECRET__'
        ),
        body    := jsonb_build_object(
          'owner_id',    new.data->>'OwnerId',
          'tx_type',     new.data->>'TxType',
          'amount',      new.data->>'Amount',
          'description', new.data->>'Description'
        )
      );
    exception when others then
      -- Never let a notification problem abort the transaction insert.
      null;
    end;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_notify_owner_transaction on public.documents;
create trigger trg_notify_owner_transaction
  after insert on public.documents
  for each row
  execute function public.notify_owner_transaction();
