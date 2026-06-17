create or replace function public.set_account_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

revoke all on function public.set_account_updated_at() from public;
revoke all on function public.set_account_updated_at() from anon;
revoke all on function public.set_account_updated_at() from authenticated;

create or replace function public.handle_new_account_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.account_profiles (id, display_name)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data ->> 'display_name',
      new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'name'
    )
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

revoke all on function public.handle_new_account_user() from public;
revoke all on function public.handle_new_account_user() from anon;
revoke all on function public.handle_new_account_user() from authenticated;

drop function if exists public.delete_current_user();
