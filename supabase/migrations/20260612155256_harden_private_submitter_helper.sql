create or replace function private.request_submitter_client_id()
returns text
language sql
stable
set search_path = ''
as $function$
  select nullif(current_setting('request.headers', true)::json ->> 'x-submitter-client-id', '');
$function$;;
