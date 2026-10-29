-- ============================================================================
-- Owner push v2: visitor arrivals + monthly / overdue reminders.
--
-- Deploy the push-owner-transaction function first (it learned the
-- `visitor_arrived` and `reminders` kinds).
--
-- 1. The trigger secret moves into Vault (copied from the existing payment
--    trigger, so nobody has to paste it), and new jobs read it from there.
-- 2. owner_reminder_targets(): every owner with a device, their monthly
--    maintenance and the current-year balance the owners app shows
--    (owner_statements/<Id>-<year>.ClosingBalance). Server-only.
-- 3. A visitor scanned in at the gate (gate_log, Kind=visitor, Result=ok,
--    Direction=in) notifies the pass owner.
-- 4. pg_cron: monthly reminder on the 1st, overdue reminder on the 15th,
--    08:00 UTC (10:00/11:00 Cairo). The function sends each owner each type
--    at most once a month.
--
-- Run in the SQL editor of project hgfrtxktcucqucanfqhi. Safe to re-run.
-- ============================================================================

-- 1 ── secret in Vault -------------------------------------------------------
do $$
declare v_secret text;
begin
  if exists (select 1 from vault.secrets where name = 'push_trigger_secret') then
    return;
  end if;
  v_secret := (regexp_match(
    pg_get_functiondef('public.notify_owner_transaction'::regproc),
    'x-push-secret'',\s*''([^'']+)'''))[1];
  if v_secret is null then
    raise exception 'push secret not found in notify_owner_transaction';
  end if;
  perform vault.create_secret(v_secret, 'push_trigger_secret',
    'x-push-secret for the push-owner-transaction function');
end $$;

create or replace function public.push_trigger_secret()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select decrypted_secret from vault.decrypted_secrets
  where name = 'push_trigger_secret' limit 1;
$$;
revoke execute on function public.push_trigger_secret()
  from public, anon, authenticated;

-- 2 ── reminder targets -----------------------------------------------------
create or replace function public.owner_reminder_targets(p_year int)
returns table (
  owner_id text,
  doc_id   text,
  fcm      text,
  monthly  numeric,
  balance  numeric
)
language sql
stable
security definer
set search_path = public
as $$
  select o.data->>'Id',
         o.doc_id,
         o.data->>'FcmToken',
         coalesce(public.safe_numeric(s.data->>'Monthly'), 0),
         coalesce(public.safe_numeric(s.data->>'ClosingBalance'), 0)
  from public.documents o
  left join public.documents s
    on s.uid = o.uid
   and s.collection = 'owner_statements'
   and s.doc_id = (o.data->>'Id') || '-' || p_year
  where o.uid = '5nCpbFKDt1NyrXCw56HaattDVT42'
    and o.collection = 'owners'
    and coalesce(o.data->>'DeletedAt', '') = ''
    and coalesce(o.data->>'FcmToken', '') <> '';
$$;
revoke execute on function public.owner_reminder_targets(int)
  from public, anon, authenticated;
grant execute on function public.owner_reminder_targets(int) to service_role;

-- 3 ── visitor arrival ------------------------------------------------------
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
     and new.data->>'Direction' = 'in'
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

drop trigger if exists trg_notify_visitor_arrival on public.documents;
create trigger trg_notify_visitor_arrival
  after insert on public.documents
  for each row
  when (new.collection = 'gate_log')
  execute function public.notify_visitor_arrival();

-- 4 ── monthly schedule -----------------------------------------------------
create extension if not exists pg_cron;

create or replace function public.send_owner_reminders(p_type text)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  perform net.http_post(
    url     := 'https://hgfrtxktcucqucanfqhi.functions.supabase.co/push-owner-transaction',
    headers := jsonb_build_object(
      'content-type', 'application/json',
      'x-push-secret', public.push_trigger_secret()
    ),
    body    := jsonb_build_object('kind', 'reminders', 'type', p_type),
    timeout_milliseconds := 120000
  );
end $$;
revoke execute on function public.send_owner_reminders(text)
  from public, anon, authenticated;

select cron.schedule('owner-monthly-reminder', '0 8 1 * *',
  $$select public.send_owner_reminders('monthly')$$);
select cron.schedule('owner-overdue-reminder', '0 8 15 * *',
  $$select public.send_owner_reminders('overdue')$$);
