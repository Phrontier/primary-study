import "jsr:@supabase/functions-js@2.117.2/edge-runtime.d.ts";
import { verifyTransaction, AppleVerificationError } from "../_shared/apple-store.ts";
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

export async function handleSubscriptionRequest(request: Request, dependencies = { verifyTransaction, createAdminClient, createUserClient, entitlementForUser, persistTransaction }): Promise<Response> {
  if (request.method === "OPTIONS") return new Response(null, { status: 204 });
  if (request.method !== "GET" && request.method !== "POST") {
    return json({ error: "Method not allowed." }, 405);
  }

  const authorization = request.headers.get("authorization");
  if (!authorization?.startsWith("Bearer ")) {
    return json({ error: "Sign-in is required." }, 401);
  }

  try {
    const userClient = dependencies.createUserClient(authorization);
    const { data, error } = await userClient.auth.getUser(authorization.slice(7));
    if (error || !data.user) {
      console.warn(JSON.stringify({ operation: "subscription-entitlement", category: "authentication", code: error?.code ?? "missing_user", status: error?.status }));
      return json({ error: "Sign-in is required." }, 401);
    }

    const admin = dependencies.createAdminClient();
    if (request.method === "GET") {
      return json(await dependencies.entitlementForUser(admin, data.user.id));
    }

    const body = await request.json().catch(() => null) as { signed_transaction?: unknown } | null;
    if (!body || typeof body.signed_transaction !== "string" || body.signed_transaction.length > 50_000) {
      return json({ error: "A signed App Store transaction is required." }, 400);
    }

    const transaction = await dependencies.verifyTransaction(body.signed_transaction);
    if (!transaction.originalTransactionId) {
      return json({ error: "The App Store transaction is incomplete." }, 400);
    }

    await dependencies.persistTransaction(admin, transaction, { userID: data.user.id });
    return json(await dependencies.entitlementForUser(admin, data.user.id));
  } catch (error) {
    if (error && typeof error === "object" && "message" in error && String(error.message).includes("account_mismatch")) {
      return json({ code: "account_mismatch", message: "This subscription belongs to another Primary Gouge account." }, 409);
    }
    console.error(JSON.stringify({ operation: "subscription-entitlement", category: error instanceof AppleVerificationError ? error.category : "persistence_or_ownership", code: error && typeof error === "object" && "code" in error && /^[A-Z0-9_]{1,20}$/.test(String(error.code)) ? String(error.code) : undefined }));
    return json({ error: "Premium could not be verified with the App Store." }, 400);
  }
}

if (import.meta.main) Deno.serve((request) => handleSubscriptionRequest(request));
