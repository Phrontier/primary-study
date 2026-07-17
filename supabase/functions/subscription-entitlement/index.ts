import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { verifyTransaction } from "../_shared/apple-store.ts";
import {
  createAdminClient,
  createUserClient,
  entitlementForUser,
  persistTransaction,
} from "../_shared/subscription-database.ts";

const headers = { "content-type": "application/json; charset=utf-8" };

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers });
}

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") return new Response(null, { status: 204 });
  if (request.method !== "GET" && request.method !== "POST") {
    return json({ error: "Method not allowed." }, 405);
  }

  const authorization = request.headers.get("authorization");
  if (!authorization?.startsWith("Bearer ")) {
    return json({ error: "Sign-in is required." }, 401);
  }

  try {
    const userClient = createUserClient(authorization);
    const { data, error } = await userClient.auth.getUser();
    if (error || !data.user) return json({ error: "Sign-in is required." }, 401);

    const admin = createAdminClient();
    if (request.method === "GET") {
      return json(await entitlementForUser(admin, data.user.id));
    }

    const body = await request.json().catch(() => null) as { signed_transaction?: unknown } | null;
    if (!body || typeof body.signed_transaction !== "string" || body.signed_transaction.length > 50_000) {
      return json({ error: "A signed App Store transaction is required." }, 400);
    }

    const transaction = await verifyTransaction(body.signed_transaction);
    if (!transaction.originalTransactionId) {
      return json({ error: "The App Store transaction is incomplete." }, 400);
    }

    const { data: existing, error: existingError } = await admin
      .from("app_store_transactions")
      .select("user_id,app_account_token")
      .eq("original_transaction_id", transaction.originalTransactionId)
      .maybeSingle();
    if (existingError) throw existingError;

    if (existing?.user_id && existing.user_id !== data.user.id) {
      return json({
        code: "account_mismatch",
        message: "This subscription is linked to another Primary Gouge account.",
      }, 409);
    }

    // New purchases must carry this account's token. If an account was deleted,
    // its retained transaction has no owner and a verified restore may claim it.
    if (!existing && transaction.appAccountToken?.toLowerCase() !== data.user.id.toLowerCase()) {
      return json({
        code: "account_mismatch",
        message: "This purchase was not created for the signed-in Primary Gouge account.",
      }, 409);
    }

    if (existing && !existing.user_id && existing.app_account_token?.toLowerCase() !== data.user.id.toLowerCase()) {
      const { data: originalOwner, error: ownerLookupError } = await admin.auth.admin.getUserById(existing.app_account_token);
      if (ownerLookupError && ownerLookupError.status !== 404) throw ownerLookupError;
      if (originalOwner.user) {
        return json({
          code: "account_mismatch",
          message: "This subscription belongs to another active Primary Gouge account.",
        }, 409);
      }
      // The original app account was deleted. Possession of the Apple-signed
      // restored transaction allows the unowned purchase to be claimed again.
    }

    await persistTransaction(admin, transaction, { userID: data.user.id });
    return json(await entitlementForUser(admin, data.user.id));
  } catch (error) {
    console.error("subscription-entitlement", error);
    return json({ error: "Premium could not be verified with the App Store." }, 400);
  }
});
