create or replace function public.set_account_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

revoke all on function public.set_account_updated_at() from public;
revoke all on function public.set_account_updated_at() from anon;
revoke all on function public.set_account_updated_at() from authenticated;

revoke all on function public.handle_new_account_user() from public;
revoke all on function public.handle_new_account_user() from anon;
revoke all on function public.handle_new_account_user() from authenticated;

drop function if exists public.delete_current_user();
;
