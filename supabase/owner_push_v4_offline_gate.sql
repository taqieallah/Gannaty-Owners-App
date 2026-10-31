-- ============================================================================
-- Owner push v4: no stale "your visitor arrived/left" after a gate outage.
--
-- A gate PC that lost internet keeps letting visitors through and sends those
-- scans when the line is back (ERP repo: supabase/visitor_pass_offline.sql);
-- they reach gate_log with Offline = true and At = when the scan happened.
-- A push hours later would be misleading, so a scan synced more than 15
-- minutes after it happened is recorded without one. Everything else is as
-- in owner_push_v3_visitor_exit.sql, which this replaces.
--
-- Run once after owner_push_v3_visitor_exit.sql. Idempotent.
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
     and coalesce(new.data->>'OwnerId', '') <> ''
     and not (coalesce(new.data->>'Offline', 'false') = 'true'
              and (new.data->>'At')::timestamptz < now() - interval '15 minutes') then
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
