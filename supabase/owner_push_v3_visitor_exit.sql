-- ============================================================================
-- Owner push v3: tell the owner when a visitor LEAVES, not only when they enter.
--
-- Deploy the push-owner-transaction function first (it learned
-- payload.direction = 'out'), then run this once. Idempotent. Needs
-- owner_push_v2.sql (the trigger, push_trigger_secret()) already applied.
--
-- Only the function body changes: gate_log rows of Kind=visitor, Result=ok are
-- now sent for both directions, and the direction travels with the payload.
-- ============================================================================

create or replace function public.notify_visitor_arrival()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if new.collection = 'gate_log'
     and new.data->>'Kind' = 'visitor'
     and new.data->>'Result' = 'ok'
     and new.data->>'Direction' in ('in', 'out')
     and coalesce(new.data->>'OwnerId', '') <> '' then
    begin
      perform net.http_post(
        url     := 'https://hgfrtxktcucqucanfqhi.functions.supabase.co/push-owner-transaction',
        headers := jsonb_build_object(
          'content-type', 'application/json',
          'x-push-secret', public.push_trigger_secret()
        ),
        body    := jsonb_build_object(
          'kind',         'visitor_arrived',
          'direction',    new.data->>'Direction',
          'owner_id',     new.data->>'OwnerId',
          'visitor_name', new.data->>'VisitorName',
          'gate',         new.data->>'Gate'
        )
      );
    exception when others then
      null; -- never block the gate because a notification failed
    end;
  end if;
  return new;
end $$;
revoke execute on function public.notify_visitor_arrival()
  from public, anon, authenticated;
