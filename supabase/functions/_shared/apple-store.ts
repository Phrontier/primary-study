import type { JWSRenewalInfoDecodedPayload, JWSTransactionDecodedPayload, ResponseBodyV2DecodedPayload } from "npm:@apple/app-store-server-library@3.1.0";

export const bundleID = Deno.env.get("APP_BUNDLE_ID") ?? "bolt.Primary-Gouge";
export const premiumProductID = "bolt.primarygouge.premium.monthly";
export type VerificationKind = "transaction" | "renewal" | "notification";
export class AppleVerificationError extends Error {
  constructor(public category: "configuration" | "transport" | "invalid_signed_data" | "invalid_response") { super(`Apple verification failed: ${category}`); }
}

export async function verifyRemote(kind: VerificationKind, signedPayload: string, options = {
  url: Deno.env.get("APPLE_VERIFIER_URL"), token: Deno.env.get("APPLE_VERIFIER_TOKEN"), fetch: globalThis.fetch,
}): Promise<Record<string, unknown>> {
  const expectedURL = "https://primary-gouge-apple-verifier.tz4mz7ry42.workers.dev/verify";
  if (options.url !== expectedURL || !options.token || options.token.length < 32) throw new AppleVerificationError("configuration");
  let response: Response;
  try {
    response = await options.fetch(expectedURL, { method: "POST", redirect: "error", signal: AbortSignal.timeout(40_000),
      headers: { "user-agent": "PrimaryGougeBackend/1.0", "authorization": `Bearer ${options.token}`, "content-type": "application/json" },
      body: JSON.stringify({ kind, signedPayload }) });
  } catch { throw new AppleVerificationError("transport"); }
  if (response.status === 422) throw new AppleVerificationError("invalid_signed_data");
  if (response.status !== 200) throw new AppleVerificationError("transport");
  let body;
  try { body = await response.json(); } catch { throw new AppleVerificationError("invalid_response"); }
  const p = body?.payload;
  const environment = kind === "notification" ? p?.data?.environment ?? p?.summary?.environment ?? p?.appData?.environment : p?.environment;
  const valid = body?.version === 1 && body?.kind === kind && p && typeof p === "object" && !Array.isArray(p)
    && (environment === "Sandbox" || environment === "Production")
    && typeof p.signedDate === "number" && Number.isFinite(p.signedDate) && p.signedDate > 0;
  const validKind = kind === "transaction" ? typeof p?.transactionId === "string" && typeof p?.originalTransactionId === "string" && p?.bundleId === bundleID && p?.productId === premiumProductID
    : kind === "renewal" ? typeof p?.originalTransactionId === "string" && p?.productId === premiumProductID
    : typeof p?.notificationUUID === "string" && typeof p?.notificationType === "string";
  if (!valid || !validKind) throw new AppleVerificationError("invalid_response");
  return p;
}
export async function verifyTransaction(payload: string): Promise<JWSTransactionDecodedPayload> {
  return await verifyRemote("transaction", payload) as JWSTransactionDecodedPayload;
}
export async function verifyRenewalInfo(payload: string): Promise<JWSRenewalInfoDecodedPayload> {
  return await verifyRemote("renewal", payload) as JWSRenewalInfoDecodedPayload;
}
export async function verifyNotification(payload: string): Promise<ResponseBodyV2DecodedPayload> {
  return await verifyRemote("notification", payload) as ResponseBodyV2DecodedPayload;
}

export function isoDate(milliseconds: number | undefined): string | null {
  return typeof milliseconds === "number" ? new Date(milliseconds).toISOString() : null;
}

export function normalizedEnvironment(environment: string | undefined): "Sandbox" | "Production" | "Xcode" {
  if (environment === "Production") return "Production";
  if (environment === "Xcode") return "Xcode";
  return "Sandbox";
}

export function entitlementStatus(
  transaction: JWSTransactionDecodedPayload,
  serverStatus?: number,
): "active" | "billing_retry" | "grace_period" | "expired" {
  if (transaction.revocationDate) return "expired";
  if (serverStatus === 3) return "billing_retry";
  if (serverStatus === 4) return "grace_period";
  if (serverStatus === 2 || serverStatus === 5) return "expired";
  if (transaction.expiresDate && transaction.expiresDate <= Date.now()) return "expired";
  return "active";
}

export type { JWSTransactionDecodedPayload } from "npm:@apple/app-store-server-library@3.1.0";
