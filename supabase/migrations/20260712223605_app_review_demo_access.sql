create table if not exists public.subscription_access_overrides (
  user_id uuid primary key references auth.users(id) on delete cascade,
  reason text not null check (reason in ('app_review', 'customer_support')),
  is_active boolean not null default true,
  expires_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  check (expires_at is null or expires_at > created_at)
);

alter table public.subscription_access_overrides enable row level security;

-- Access overrides are server-managed and intentionally unavailable through
-- the client Data API. The entitlement Edge Function reads them using the
-- service-role client after authenticating the requesting user.
revoke all on table public.subscription_access_overrides from anon, authenticated;

drop trigger if exists subscription_access_overrides_set_updated_at
on public.subscription_access_overrides;
create trigger subscription_access_overrides_set_updated_at
before update on public.subscription_access_overrides
for each row execute function public.set_account_updated_at();
