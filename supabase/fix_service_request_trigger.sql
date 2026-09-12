-- ============================================================================
-- Fix the service-request push trigger: it still had the __FUNCTION_URL__
-- placeholder, so net.http_post raised "invalid URL / Bad scheme" and aborted
-- the INSERT — breaking client service-request submission. Fill the real URL
-- and wrap the HTTP call so a push failure can never block the insert.
-- Replace __PUSH_SECRET__ with your PUSH_TRIGGER_SECRET value, then run.
-- ============================================================================

create extension if not exists pg_net with schema extensions;

create or replace function public.notify_service_request()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if new.collection = 'serviceRequests' then
    begin
      perform net.http_post(
        url     := 'https://hgfrtxktcucqucanfqhi.functions.supabase.co/push-service-request',
        headers := jsonb_build_object(
          'content-type', 'application/json',
          'x-push-secret', '__PUSH_SECRET__'
        ),
        body    := jsonb_build_object(
          'record', jsonb_build_object('doc_id', new.doc_id, 'data', new.data)
        )
      );
    exception when others then
      null; -- never let a notification problem abort the service request
    end;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_notify_service_request on public.documents;
create trigger trg_notify_service_request
  after insert on public.documents
  for each row
  execute function public.notify_service_request();
