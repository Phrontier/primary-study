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

export function createUserClient(authorization: string): SupabaseClient {
  const url = Deno.env.get("SUPABASE_URL");
  const publishableKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!url || !publishableKey) throw new Error("Supabase user environment is not configured.");
  return createClient(url, publishableKey, {
    global: { headers: { authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

export function publicEntitlement(row: Record<string, unknown> | null) {
  if (!row) {
    return {
      status: "not_subscribed",
      product_id: null,
      expires_at: null,
      will_auto_renew: null,
      environment: null,
    };
  }
  return {
    status: row.status,
    product_id: row.product_id,
    expires_at: row.expires_at,
    will_auto_renew: row.will_auto_renew,
    environment: row.environment,
  };
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
    .select("status,product_id,expires_at,will_auto_renew,environment")
    .eq("user_id", userID)
    .maybeSingle();
  if (error) throw error;
  return publicEntitlement(data);
}

export async function persistTransaction(
  admin: AdminClient,
  transaction: JWSTransactionDecodedPayload,
  options: { userID?: string | null; serverStatus?: number; willAutoRenew?: boolean | null },
) {
  const originalID = transaction.originalTransactionId;
  const transactionID = transaction.transactionId;
  if (!originalID || !transactionID || !transaction.purchaseDate || !transaction.signedDate) {
    throw new Error("Apple transaction is missing required identifiers or dates.");
  }
  if (transaction.bundleId !== (Deno.env.get("APP_BUNDLE_ID") ?? "bolt.Primary-Gouge")) {
    throw new Error("Apple transaction bundle ID does not match this app.");
  }
  if (transaction.productId !== premiumProductID) {
    throw new Error("Apple transaction product is not supported.");
  }

  const { data: existing, error: existingError } = await admin
    .from("app_store_transactions")
    .select("user_id,last_signed_at,will_auto_renew")
    .eq("original_transaction_id", originalID)
    .maybeSingle();
  if (existingError) throw existingError;

  const signedAt = isoDate(transaction.signedDate)!;
  if (existing?.last_signed_at && new Date(existing.last_signed_at).getTime() > transaction.signedDate) {
    return { originalID, userID: existing.user_id as string | null, ignoredAsStale: true };
  }

  const resolvedUserID = options.userID === undefined
    ? (existing?.user_id as string | null ?? null)
    : options.userID;
  const status = entitlementStatus(transaction, options.serverStatus);
  const willAutoRenew = options.willAutoRenew === undefined
    ? (existing?.will_auto_renew as boolean | null ?? null)
    : options.willAutoRenew;
  const environment = normalizedEnvironment(transaction.environment as string | undefined);

  const { error: transactionError } = await admin.from("app_store_transactions").upsert({
    original_transaction_id: originalID,
    latest_transaction_id: transactionID,
    user_id: resolvedUserID,
    app_account_token: transaction.appAccountToken ?? null,
    product_id: transaction.productId,
    environment,
    status,
    purchased_at: isoDate(transaction.purchaseDate),
    expires_at: isoDate(transaction.expiresDate),
    revoked_at: isoDate(transaction.revocationDate),
    will_auto_renew: willAutoRenew,
    last_signed_at: signedAt,
  }, { onConflict: "original_transaction_id" });
  if (transactionError) throw transactionError;

  if (resolvedUserID) {
    const { error: entitlementError } = await admin.from("subscription_entitlements").upsert({
      user_id: resolvedUserID,
      original_transaction_id: originalID,
      product_id: transaction.productId,
      status,
      environment,
      expires_at: isoDate(transaction.expiresDate),
      will_auto_renew: willAutoRenew,
      last_verified_at: signedAt,
    }, { onConflict: "user_id" });
    if (entitlementError) throw entitlementError;
  }

  return { originalID, userID: resolvedUserID, ignoredAsStale: false };
}

export type { JWSTransactionDecodedPayload } from "npm:@apple/app-store-server-library@3.1.0";
