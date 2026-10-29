-- ============================================================================
-- Push secret fix.
--
-- The original push triggers (payment, new service request, request status)
-- were installed from a template whose placeholder '__PUSH_SECRET__' was never
-- replaced, so they always sent that literal and push never worked. Vault's
-- `push_trigger_secret` (owner_push_v2.sql) was copied from them, so it holds
-- the same placeholder.
--
-- Before running this, in the dashboard:
--   1. Project Settings → Vault → push_trigger_secret → edit → set it to the
--      SAME value as the Edge Function secret PUSH_TRIGGER_SECRET
--      (Edge Functions → Secrets). Any long random string works, as long as
--      both places hold the same one.
-- Then run this file. It makes the three old triggers read the secret from
-- Vault, like the new ones already do.
--
-- Run in the SQL editor of project hgfrtxktcucqucanfqhi. Safe to re-run.
-- ============================================================================

do $$
declare
  r record;
  v_def text;
begin
  for r in select p.oid from pg_proc p join pg_namespace n on n.oid = p.pronamespace
           where n.nspname = 'public'
             and p.proname in ('notify_owner_transaction',
                               'notify_service_request',
                               'notify_service_request_status')
  loop
    v_def := pg_get_functiondef(r.oid);
    if position('''__PUSH_SECRET__''' in v_def) > 0 then
      execute replace(v_def, '''__PUSH_SECRET__''', 'public.push_trigger_secret()');
    end if;
  end loop;
end $$;

-- Check: every row should say false.
select p.proname,
       pg_get_functiondef(p.oid) like '%__PUSH_SECRET__%' as still_placeholder
from pg_proc p
where p.proname like 'notify_%';
