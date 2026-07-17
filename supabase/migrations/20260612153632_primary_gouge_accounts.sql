create table if not exists public.account_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  squadron_id text,
  syllabus_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint account_profiles_display_name_length check (display_name is null or char_length(display_name) <= 120),
  constraint account_profiles_squadron_id_length check (squadron_id is null or char_length(squadron_id) <= 64),
  constraint account_profiles_syllabus_id_check check (syllabus_id is null or syllabus_id in ('delta', 'echo', 'not_sure'))
);

create table if not exists public.account_roles (
  user_id uuid not null references auth.users(id) on delete cascade,
  permission text not null,
  created_at timestamptz not null default now(),
  primary key (user_id, permission),
  constraint account_roles_permission_check check (permission in ('instructor_gouge_moderator'))
);

create index if not exists account_roles_permission_idx on public.account_roles(permission);

create or replace function public.set_account_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_account_profiles_updated_at on public.account_profiles;
create trigger set_account_profiles_updated_at
  before update on public.account_profiles
  for each row execute function public.set_account_updated_at();

alter table public.account_profiles enable row level security;
alter table public.account_roles enable row level security;

grant select, insert, update on public.account_profiles to authenticated;
grant select on public.account_roles to authenticated;

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
    nullif(coalesce(
      new.raw_user_meta_data ->> 'display_name',
      new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'name'
    ), '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_account_user();

create or replace function public.delete_current_user()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  requester uuid := auth.uid();
begin
  if requester is null then
    raise exception 'Sign-in is required.' using errcode = '28000';
  end if;

  delete from auth.users
  where id = requester;
end;
$$;

revoke all on function public.delete_current_user() from public;
grant execute on function public.delete_current_user() to authenticated;

drop policy if exists "Users can read own account profile" on public.account_profiles;
create policy "Users can read own account profile"
  on public.account_profiles
  for select
  to authenticated
  using ((select auth.uid()) is not null and (select auth.uid()) = id);

drop policy if exists "Users can insert own account profile" on public.account_profiles;
create policy "Users can insert own account profile"
  on public.account_profiles
  for insert
  to authenticated
  with check ((select auth.uid()) is not null and (select auth.uid()) = id);

drop policy if exists "Users can update own account profile" on public.account_profiles;
create policy "Users can update own account profile"
  on public.account_profiles
  for update
  to authenticated
  using ((select auth.uid()) is not null and (select auth.uid()) = id)
  with check ((select auth.uid()) is not null and (select auth.uid()) = id);

drop policy if exists "Users can read own account roles" on public.account_roles;
create policy "Users can read own account roles"
  on public.account_roles
  for select
  to authenticated
  using ((select auth.uid()) is not null and (select auth.uid()) = user_id);
;
