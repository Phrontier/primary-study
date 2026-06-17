create table if not exists public.account_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text check (display_name is null or char_length(display_name) <= 120),
  squadron_id text check (squadron_id is null or char_length(squadron_id) <= 64),
  syllabus_id text check (syllabus_id is null or syllabus_id in ('delta', 'echo', 'not_sure')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.account_profiles enable row level security;

grant select, insert, update on public.account_profiles to authenticated;

drop policy if exists "account_profiles_select_own" on public.account_profiles;
create policy "account_profiles_select_own"
on public.account_profiles
for select
to authenticated
using (auth.uid() = id);

drop policy if exists "account_profiles_insert_own" on public.account_profiles;
create policy "account_profiles_insert_own"
on public.account_profiles
for insert
to authenticated
with check (auth.uid() = id);

drop policy if exists "account_profiles_update_own" on public.account_profiles;
create policy "account_profiles_update_own"
on public.account_profiles
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

create or replace function public.set_account_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists account_profiles_set_updated_at on public.account_profiles;
create trigger account_profiles_set_updated_at
before update on public.account_profiles
for each row execute function public.set_account_updated_at();

create table if not exists public.account_roles (
  user_id uuid not null references auth.users(id) on delete cascade,
  permission text not null check (permission = 'instructor_gouge_moderator'),
  created_at timestamptz not null default timezone('utc', now()),
  primary key (user_id, permission)
);

alter table public.account_roles enable row level security;

grant select on public.account_roles to authenticated;

drop policy if exists "account_roles_select_own" on public.account_roles;
create policy "account_roles_select_own"
on public.account_roles
for select
to authenticated
using (auth.uid() = user_id);

create or replace function public.handle_new_account_user()
returns trigger
language plpgsql
security definer
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

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_account_user();

create or replace function public.delete_current_user()
returns void
language plpgsql
security definer
as $$
begin
  delete from auth.users where id = auth.uid();
end;
$$;

grant execute on function public.delete_current_user() to authenticated;
