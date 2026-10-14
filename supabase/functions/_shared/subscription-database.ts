import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2.95.0";
import {
  entitlementStatus,
  isoDate,
  normalizedEnvironment,
  premiumProductID,
  type JWSTransactionDecodedPayload,
} from "./apple-store.ts";

export type AdminClient = SupabaseClient;

export function createAdminClient(): AdminClient {
  const url = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !serviceRoleKey) throw new Error("Supabase server environment is not configured.");
  return createClient(url, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

export function createUserClient(authorization: string, fetcher: typeof fetch = globalThis.fetch): SupabaseClient {
  const url = Deno.env.get("SUPABASE_URL");
  const publishableKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!url || !publishableKey) throw new Error("Supabase user environment is not configured.");
  return createClient(url, publishableKey, {
    global: { headers: { Authorization: authorization }, fetch: fetcher },
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

export function publicEntitlement(row: Record<string, unknown> | null, now = Date.now()) {
  if (!row) return { status: "not_subscribed", product_id: null, expires_at: null, grace_expires_at: null, last_verified_at: null, will_auto_renew: null, environment: null };
  const deadline = row.status === "grace_period" ? row.grace_expires_at : row.expires_at;
  const validDeadline = typeof deadline === "string" && Date.parse(deadline) > now;
  const status = (row.status === "active" || row.status === "grace_period") && !validDeadline ? "expired" : row.status;
  return { status, product_id: row.product_id, expires_at: row.expires_at,
    grace_expires_at: row.grace_expires_at, last_verified_at: row.last_verified_at,
    will_auto_renew: row.will_auto_renew, environment: row.environment };
}

export async function entitlementForUser(admin: AdminClient, userID: string) {
  const { data: override, error: overrideError } = await admin
    .from("subscription_access_overrides")
    .select("reason,is_active,expires_at")
    .eq("user_id", userID)
    .maybeSingle();
  if (overrideError) throw overrideError;

  const overrideIsCurrent = override?.is_active === true && (
    !override.expires_at || new Date(override.expires_at).getTime() > Date.now()
  );
  if (overrideIsCurrent) {
    return {
      status: "active",
      product_id: premiumProductID,
      expires_at: override.expires_at,
      will_auto_renew: false,
      environment: override.reason === "app_review" ? "AppReview" : "SupportOverride",
    };
  }

  const { data, error } = await admin
    .from("subscription_entitlements")
    .select("status,product_id,expires_at,grace_expires_at,last_verified_at,will_auto_renew,environment")
    .eq("user_id", userID)
    .maybeSingle();
  if (error) throw error;
  return publicEntitlement(data);
}

export type SubscriptionNotification = {
  notification_uuid: string; notification_type: string; subtype: string | null;
  environment: string | null; signed_at: string;
};

export function transactionRecord(transaction: JWSTransactionDecodedPayload,
  options: { serverStatus?: number; willAutoRenew?: boolean | null; graceExpiresAt?: number } = {}) {
  if (!transaction.originalTransactionId || !transaction.transactionId || !transaction.purchaseDate || !transaction.signedDate) {
    throw new Error("Apple transaction is missing required identifiers or dates.");
  }
  if (transaction.bundleId !== (Deno.env.get("APP_BUNDLE_ID") ?? "bolt.Primary-Gouge") || transaction.productId !== premiumProductID) {
    throw new Error("Unsupported Apple transaction.");
  }
  return { original_transaction_id: transaction.originalTransactionId,
    latest_transaction_id: transaction.transactionId, app_account_token: transaction.appAccountToken ?? null,
    product_id: transaction.productId, environment: normalizedEnvironment(transaction.environment as string | undefined),
    status: entitlementStatus(transaction, options.serverStatus), purchased_at: isoDate(transaction.purchaseDate),
    expires_at: isoDate(transaction.expiresDate), revoked_at: isoDate(transaction.revocationDate),
    will_auto_renew: options.willAutoRenew ?? null, last_signed_at: isoDate(transaction.signedDate),
    grace_expires_at: isoDate(options.graceExpiresAt) };
}

export async function persistTransaction(admin: AdminClient, transaction: JWSTransactionDecodedPayload | null,
  options: { userID?: string; serverStatus?: number; willAutoRenew?: boolean | null;
    graceExpiresAt?: number; notification?: SubscriptionNotification } = {}) {
  const { data, error } = await admin.rpc("persist_verified_subscription", {
    p_transaction: transaction ? transactionRecord(transaction, options) : {},
    p_user_id: options.userID ?? null, p_notification: options.notification ?? null,
  });
  if (error) throw error;
  return data;
}

export type { JWSTransactionDecodedPayload } from "npm:@apple/app-store-server-library@3.1.0";
