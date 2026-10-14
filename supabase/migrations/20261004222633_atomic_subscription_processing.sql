alter table public.app_store_transactions add column if not exists grace_expires_at timestamptz;
alter table public.app_store_transactions add column if not exists last_event_at timestamptz;
alter table public.subscription_entitlements add column if not exists grace_expires_at timestamptz;

-- Service-only, invoker privileges: signature verification happens in the Edge Function.
-- One RPC transaction owns all writes; an exception rolls back notification and entitlement alike.
create or replace function public.persist_verified_subscription(
  p_transaction jsonb,
  p_user_id uuid default null,
  p_notification jsonb default null
) returns jsonb
language plpgsql security invoker set search_path = '' as $$
declare
  original_id text := p_transaction->>'original_transaction_id';
  incoming public.app_store_transactions%rowtype;
  existing public.app_store_transactions%rowtype;
  owner_id uuid;
  incoming_token uuid := (p_transaction->>'app_account_token')::uuid;
  event_at timestamptz := coalesce((p_notification->>'signed_at')::timestamptz, (p_transaction->>'last_signed_at')::timestamptz);
  is_newer boolean;
begin
  if p_notification is not null then
    perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_notification->>'notification_uuid', 0));
    if exists(select 1 from public.app_store_notifications where notification_uuid = (p_notification->>'notification_uuid')::uuid) then
      return jsonb_build_object('duplicate', true);
    end if;
  end if;

  if original_id is not null then
    perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(original_id, 1));
    select * into existing from public.app_store_transactions where original_transaction_id = original_id for update;
    incoming := jsonb_populate_record(null::public.app_store_transactions, p_transaction);
    owner_id := existing.user_id;

    if p_user_id is not null then
      if existing.user_id is not null and existing.user_id <> p_user_id then
        raise exception 'account_mismatch' using errcode = 'P0001';
      end if;
      if existing.original_transaction_id is null and incoming_token is distinct from p_user_id then
        raise exception 'account_mismatch' using errcode = 'P0001';
      end if;
      if existing.original_transaction_id is not null and existing.user_id is null
         and existing.app_account_token is distinct from p_user_id
         and (existing.app_account_token is null or exists(select 1 from auth.users where id = existing.app_account_token)) then
        raise exception 'account_mismatch' using errcode = 'P0001';
      end if;
      owner_id := p_user_id;
    elsif owner_id is null and existing.original_transaction_id is null then
      select id into owner_id from auth.users where id = incoming_token;
    end if;

    if owner_id is not null then
      perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(owner_id::text, 2));
    end if;
    is_newer := existing.original_transaction_id is null
      or event_at > coalesce(existing.last_event_at, existing.last_signed_at);

    if is_newer then
      -- Client reconciliation of the same transaction must not erase notification-only
      -- billing/grace state. A new renewal or verified revocation can advance it.
      if p_notification is null and incoming.latest_transaction_id = existing.latest_transaction_id
         and incoming.revoked_at is null then
        incoming.status := existing.status;
        incoming.grace_expires_at := existing.grace_expires_at;
      end if;
      insert into public.app_store_transactions (
        original_transaction_id, latest_transaction_id, user_id, app_account_token,
        product_id, environment, status, purchased_at, expires_at, revoked_at,
        will_auto_renew, last_signed_at, last_event_at, grace_expires_at
      ) values (
        original_id, incoming.latest_transaction_id, owner_id, incoming_token,
        incoming.product_id, incoming.environment, incoming.status, incoming.purchased_at,
        incoming.expires_at, incoming.revoked_at,
        coalesce(incoming.will_auto_renew, existing.will_auto_renew), incoming.last_signed_at,
        event_at, incoming.grace_expires_at
      ) on conflict (original_transaction_id) do update set
        latest_transaction_id = excluded.latest_transaction_id, user_id = excluded.user_id,
        app_account_token = excluded.app_account_token, status = excluded.status,
        purchased_at = excluded.purchased_at, expires_at = excluded.expires_at,
        revoked_at = excluded.revoked_at, will_auto_renew = excluded.will_auto_renew,
        last_signed_at = excluded.last_signed_at, last_event_at = excluded.last_event_at,
        grace_expires_at = excluded.grace_expires_at;
    elsif owner_id is distinct from existing.user_id then
      update public.app_store_transactions set user_id = owner_id where original_transaction_id = original_id;
    end if;

    select * into incoming from public.app_store_transactions where original_transaction_id = original_id;
    if owner_id is not null then
      insert into public.subscription_entitlements (
        user_id, original_transaction_id, product_id, status, environment, expires_at,
        will_auto_renew, last_verified_at, grace_expires_at
      ) values (
        owner_id, original_id, incoming.product_id, incoming.status, incoming.environment,
        incoming.expires_at, incoming.will_auto_renew,
        coalesce(incoming.last_event_at, incoming.last_signed_at), incoming.grace_expires_at
      ) on conflict (user_id) do update set
        original_transaction_id = excluded.original_transaction_id, product_id = excluded.product_id,
        status = excluded.status, environment = excluded.environment, expires_at = excluded.expires_at,
        will_auto_renew = excluded.will_auto_renew, last_verified_at = excluded.last_verified_at,
        grace_expires_at = excluded.grace_expires_at
      where public.subscription_entitlements.last_verified_at <= excluded.last_verified_at;
    end if;
  end if;

  if p_notification is not null then
    insert into public.app_store_notifications (
      notification_uuid, notification_type, subtype, original_transaction_id, environment, signed_at
    ) values (
      (p_notification->>'notification_uuid')::uuid, p_notification->>'notification_type',
      p_notification->>'subtype', original_id, p_notification->>'environment',
      (p_notification->>'signed_at')::timestamptz
    );
  end if;
  return jsonb_build_object('originalID', original_id, 'userID', owner_id, 'ignoredAsStale', not coalesce(is_newer, false));
end;
$$;
revoke all on function public.persist_verified_subscription(jsonb,uuid,jsonb) from public, anon, authenticated;
grant execute on function public.persist_verified_subscription(jsonb,uuid,jsonb) to service_role;
