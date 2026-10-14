-- Run against a migrated database. All synthetic rows are rolled back.
begin;
do $$
declare
  first_user uuid := gen_random_uuid();
  second_user uuid := gen_random_uuid();
  original text := 'release-test-' || gen_random_uuid()::text;
  notification_id uuid := gen_random_uuid();
  tx jsonb;
  event jsonb;
  conflicted boolean := false;
begin
  insert into auth.users(id) values(first_user), (second_user);
  tx := jsonb_build_object(
    'original_transaction_id', original, 'latest_transaction_id', original || '-1',
    'app_account_token', first_user, 'product_id', 'bolt.primarygouge.premium.monthly',
    'environment', 'Sandbox', 'status', 'active', 'purchased_at', now(),
    'expires_at', now()+interval '1 hour', 'last_signed_at', now(), 'will_auto_renew', true
  );
  perform public.persist_verified_subscription(tx, first_user);
  assert exists(select 1 from public.subscription_entitlements where user_id=first_user and status='active'), 'Purchase missing';
  begin
    perform public.persist_verified_subscription(tx, second_user);
  exception when raise_exception then
    assert sqlerrm = 'account_mismatch', 'Unexpected ownership error';
    conflicted := true;
  end;
  assert conflicted, 'Another account claimed an owned transaction';

  event := jsonb_build_object('notification_uuid', notification_id, 'notification_type', 'DID_FAIL_TO_RENEW',
    'environment', 'Sandbox', 'signed_at', now()+interval '1 minute');
  tx := tx || jsonb_build_object('status','grace_period','grace_expires_at',now()+interval '1 day');
  perform public.persist_verified_subscription(tx, null, event);
  assert exists(select 1 from public.subscription_entitlements where user_id=first_user and status='grace_period' and grace_expires_at is not null), 'Grace period missing';
  -- Duplicate notification cannot change state, even if its payload differs.
  perform public.persist_verified_subscription(tx || jsonb_build_object('status','expired'), null, event);
  assert exists(select 1 from public.subscription_entitlements where user_id=first_user and status='grace_period'), 'Duplicate changed state';
  -- Older notifications and client reconciliation cannot undo newer notification state.
  event := event || jsonb_build_object('notification_uuid',gen_random_uuid(),'signed_at',now()-interval '1 minute');
  perform public.persist_verified_subscription(tx || jsonb_build_object('status','expired'), null, event);
  perform public.persist_verified_subscription(tx || jsonb_build_object('status','active','last_signed_at',now()+interval '2 minutes'), first_user);
  assert exists(select 1 from public.subscription_entitlements where user_id=first_user and status='grace_period'), 'Stale/client data erased grace';

  -- A deliberately invalid notification insert occurs after the entitlement write;
  -- PostgreSQL must roll back that write as well.
  begin
    perform public.persist_verified_subscription(tx || jsonb_build_object('status','expired'), null,
      jsonb_build_object('notification_uuid',gen_random_uuid(),'notification_type',null,'signed_at',now()+interval '3 minutes'));
    raise exception 'Expected persistence failure';
  exception when not_null_violation then null;
  end;
  assert exists(select 1 from public.subscription_entitlements where user_id=first_user and status='grace_period'), 'Partial failure changed entitlement';

  delete from auth.users where id=first_user;
  perform public.persist_verified_subscription(tx, second_user);
  assert exists(select 1 from public.subscription_entitlements where user_id=second_user and status='grace_period'), 'Deleted-account restore missing';
  assert not has_function_privilege('authenticated','public.persist_verified_subscription(jsonb,uuid,jsonb)','execute'), 'Client can grant access';
  assert not has_function_privilege('anon','public.persist_verified_subscription(jsonb,uuid,jsonb)','execute'), 'Anonymous can grant access';
end $$;
rollback;
