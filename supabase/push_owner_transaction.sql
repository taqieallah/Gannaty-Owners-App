-- ============================================================================
-- Background push: fire push-owner-transaction on every new owner payment, so
-- the owner's phone is notified even when the app is closed.
-- ============================================================================
-- Run once in the Supabase SQL Editor AFTER deploying the function. Replace the
-- two placeholders first:
--   __FUNCTION_URL__ = https://hgfrtxktcucqucanfqhi.functions.supabase.co/push-owner-transaction
--   __PUSH_SECRET__  = the same value as the PUSH_TRIGGER_SECRET secret
-- Idempotent — safe to re-run.
-- ============================================================================

create extension if not exists pg_net with schema extensions;

-- Fired for every INSERT on documents; only owner_transactions reach the function.
-- OwnerId/Amount are sent as TEXT (owner Ids are int64 beyond JSON number range).
create or replace function public.notify_owner_transaction()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if new.collection = 'owner_transactions'
     and upper(coalesce(new.data->>'TxType', '')) = 'PAYMENT' then
    perform net.http_post(
      url     := '__FUNCTION_URL__',
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
  end if;
  return new;
end;
$$;

drop trigger if exists trg_notify_owner_transaction on public.documents;
create trigger trg_notify_owner_transaction
  after insert on public.documents
  for each row
  execute function public.notify_owner_transaction();
