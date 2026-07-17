create table if not exists public.app_store_transactions (
  original_transaction_id text primary key,
  latest_transaction_id text not null unique,
  user_id uuid references auth.users(id) on delete set null,
  app_account_token uuid,
  product_id text not null check (product_id = 'bolt.primarygouge.premium.monthly'),
  environment text not null check (environment in ('Sandbox', 'Production', 'Xcode')),
  status text not null check (status in ('active', 'billing_retry', 'grace_period', 'expired')),
  purchased_at timestamptz not null,
  expires_at timestamptz,
  revoked_at timestamptz,
  will_auto_renew boolean,
  last_signed_at timestamptz not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists app_store_transactions_user_id_idx
on public.app_store_transactions (user_id)
where user_id is not null;

create table if not exists public.subscription_entitlements (
  user_id uuid primary key references auth.users(id) on delete cascade,
  original_transaction_id text not null unique references public.app_store_transactions(original_transaction_id),
  product_id text not null check (product_id = 'bolt.primarygouge.premium.monthly'),
  status text not null check (status in ('active', 'billing_retry', 'grace_period', 'expired')),
  environment text not null check (environment in ('Sandbox', 'Production', 'Xcode')),
  expires_at timestamptz,
  will_auto_renew boolean,
  last_verified_at timestamptz not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.app_store_notifications (
  notification_uuid uuid primary key,
  notification_type text not null,
  subtype text,
  original_transaction_id text,
  environment text check (environment is null or environment in ('Sandbox', 'Production', 'Xcode')),
  signed_at timestamptz not null,
  processed_at timestamptz not null default timezone('utc', now())
);

alter table public.app_store_transactions enable row level security;
alter table public.subscription_entitlements enable row level security;
alter table public.app_store_notifications enable row level security;

revoke all on table public.app_store_transactions from anon, authenticated;
revoke all on table public.subscription_entitlements from anon, authenticated;
revoke all on table public.app_store_notifications from anon, authenticated;

drop trigger if exists app_store_transactions_set_updated_at on public.app_store_transactions;
create trigger app_store_transactions_set_updated_at
before update on public.app_store_transactions
for each row execute function public.set_account_updated_at();

drop trigger if exists subscription_entitlements_set_updated_at on public.subscription_entitlements;
create trigger subscription_entitlements_set_updated_at
before update on public.subscription_entitlements
for each row execute function public.set_account_updated_at();;
