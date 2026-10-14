import { handleSubscriptionRequest } from "../functions/subscription-entitlement/index.ts";
import { handleNotificationRequest } from "../functions/apple-subscription-notifications/index.ts";
import { publicEntitlement, transactionRecord, createUserClient } from "../functions/_shared/subscription-database.ts";
import { verifyTransaction } from "../functions/_shared/apple-store.ts";

function assert(condition: unknown, message = "Assertion failed") { if (!condition) throw new Error(message); }
const request = (body?: unknown, authorization = "Bearer test") => new Request("https://test.invalid", {
  method: "POST", headers: { authorization, "content-type": "application/json" }, body: JSON.stringify(body),
});

Deno.test("expired and malformed deadlines cannot grant backend access", () => {
  const now = Date.now();
  for (const status of ["active", "grace_period"]) {
    for (const deadline of [null, "not a date", new Date(now - 1).toISOString()]) {
      assert(publicEntitlement({ status, expires_at: deadline, grace_expires_at: deadline }, now).status === "expired");
    }
  }
  assert(publicEntitlement({ status: "grace_period", expires_at: new Date(now - 1).toISOString(), grace_expires_at: new Date(now + 1000).toISOString() }, now).status === "grace_period");
  assert(publicEntitlement(null).status === "not_subscribed");
});

Deno.test("Apple verifier rejects unsigned and malformed transactions", async () => {
  for (const payload of ["", "a.b.c", "eyJhbGciOiJub25lIn0.eyJwcm9kdWN0SWQiOiJib2x0LnByaW1hcnlnb3VnZS5wcmVtaXVtLm1vbnRobHkifQ."]) {
    let rejected = false;
    try { await verifyTransaction(payload); } catch { rejected = true; }
    assert(rejected);
  }
});

Deno.test("entitlement endpoint requires an authenticated user", async () => {
  const missing = await handleSubscriptionRequest(request({}, ""));
  assert(missing.status === 401);
  const rejected = await handleSubscriptionRequest(request({ signed_transaction: "test" }), {
    createUserClient: (() => ({ auth: { getUser: async () => ({ data: { user: null }, error: new Error("invalid JWT") }) } })) as never,
  } as never);
  assert(rejected.status === 401);
});

Deno.test("invalid signature never reaches the database", async () => {
  let writes = 0;
  const response = await handleSubscriptionRequest(request({ signed_transaction: "forged" }), {
    createUserClient: (() => ({ auth: { getUser: async () => ({ data: { user: { id: "test" } }, error: null }) } })) as never,
    createAdminClient: (() => ({})) as never,
    verifyTransaction: (async () => { throw new Error("invalid signature"); }) as never,
    persistTransaction: (async () => { writes++; }) as never,
  } as never);
  assert(response.status === 400 && writes === 0);
});

Deno.test("ownership conflicts return a distinct 409 without granting access", async () => {
  const response = await handleSubscriptionRequest(request({ signed_transaction: "verified" }), {
    createUserClient: (() => ({ auth: { getUser: async () => ({ data: { user: { id: "test" } }, error: null }) } })) as never,
    createAdminClient: (() => ({})) as never,
    verifyTransaction: (async () => ({ originalTransactionId: "original" })) as never,
    persistTransaction: (async () => { throw { message: "account_mismatch" }; }) as never,
  } as never);
  assert(response.status === 409 && (await response.json()).code === "account_mismatch");
});

Deno.test("notification validation fails closed and transient persistence failure is not acknowledged", async () => {
  assert((await handleNotificationRequest(request({}))).status === 400);
  let writes = 0;
  const dependencies = {
    verifyNotification: (async () => ({ notificationUUID: crypto.randomUUID(), notificationType: "TEST", signedDate: Date.now() })) as never,
    createAdminClient: (() => ({})) as never,
    persistTransaction: (async () => { writes++; throw new Error("database unavailable"); }) as never,
  };
  assert((await handleNotificationRequest(request({ signedPayload: "verified" }), dependencies as never)).status === 400);
  assert(writes === 1);
});

Deno.test("transaction persistence rejects foreign products and bundles", () => {
  let rejected = 0;
  for (const values of [{ bundleId: "wrong", productId: "bolt.primarygouge.premium.monthly" }, { bundleId: "bolt.Primary-Gouge", productId: "wrong" }]) {
    try { transactionRecord({ ...values, transactionId: "1", originalTransactionId: "1", signedDate: Date.now(), purchaseDate: Date.now() }); } catch { rejected++; }
  }
  assert(rejected === 2);
});

Deno.test("session validation sends exactly one bearer token", async () => {
  const originalURL = Deno.env.get("SUPABASE_URL"), originalKey = Deno.env.get("SUPABASE_ANON_KEY");
  Deno.env.set("SUPABASE_URL", "https://example.supabase.co"); Deno.env.set("SUPABASE_ANON_KEY", "public-test-key");
  try {
    let sent = "";
    const client = createUserClient("Bearer regression-token", (async (_input, init) => {
      sent = new Headers(init?.headers).get("authorization") ?? "";
      return Response.json({ id: "test-user" });
    }) as typeof fetch);
    const { data, error } = await client.auth.getUser("regression-token");
    assert(sent === "Bearer regression-token" && data.user?.id === "test-user" && !error);
  } finally {
    originalURL === undefined ? Deno.env.delete("SUPABASE_URL") : Deno.env.set("SUPABASE_URL", originalURL);
    originalKey === undefined ? Deno.env.delete("SUPABASE_ANON_KEY") : Deno.env.set("SUPABASE_ANON_KEY", originalKey);
  }
});
