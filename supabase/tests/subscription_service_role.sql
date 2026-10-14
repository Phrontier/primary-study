-- Exercise the production RPC role; synthetic rows never survive this transaction.
begin;
do $$
declare
  account_id uuid := gen_random_uuid();
  original text := 'role-test-' || gen_random_uuid()::text;
  tx jsonb;
  event jsonb;
begin
  insert into auth.users(id) values(account_id);
  tx := jsonb_build_object(
    'original_transaction_id', original, 'latest_transaction_id', original || '-1',
    'app_account_token', account_id, 'product_id', 'bolt.primarygouge.premium.monthly',
    'environment', 'Sandbox', 'status', 'active', 'purchased_at', now(),
    'expires_at', now()+interval '1 hour', 'last_signed_at', now());
  execute 'set local role service_role';
  assert current_user = 'service_role', 'Wrong execution role';
  perform public.persist_verified_subscription(tx, account_id);
  assert exists(select 1 from public.subscription_entitlements where user_id=account_id), 'Purchase missing';
  -- Existing-owner checks and notification-first ownership lookup both read auth.users.id.
  perform public.persist_verified_subscription(tx, account_id);
  tx := tx || jsonb_build_object('original_transaction_id',original || '-notification',
    'latest_transaction_id', original || '-notification-1');
  event := jsonb_build_object('notification_uuid',gen_random_uuid(),'notification_type','SUBSCRIBED',
    'environment','Sandbox','signed_at',now());
  perform public.persist_verified_subscription(tx, null, event);
  assert exists(select 1 from public.app_store_transactions where original_transaction_id=original || '-notification' and user_id=account_id), 'Notification ownership missing';
  assert not has_column_privilege('service_role','auth.users','email','SELECT'), 'Auth email access widened';
  assert not has_column_privilege('anon','auth.users','id','SELECT'), 'Anonymous Auth access';
  assert not has_column_privilege('authenticated','auth.users','id','SELECT'), 'User Auth access';
  assert not has_function_privilege('authenticated','public.persist_verified_subscription(jsonb,uuid,jsonb)','EXECUTE'), 'User can grant subscription';
end;
$$;
rollback;
