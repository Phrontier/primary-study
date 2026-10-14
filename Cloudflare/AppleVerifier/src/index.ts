import { Buffer } from "node:buffer";
import { createHash, timingSafeEqual } from "node:crypto";
import type { Environment, SignedDataVerifier } from "@apple/app-store-server-library";
import { appleRoots } from "./apple-roots";

export type Kind = "transaction" | "renewal" | "notification";
export interface Env { APPLE_VERIFIER_TOKEN: string }
const roots = appleRoots.map(value => Buffer.from(value, "base64"));
const verifiers = new Map<Environment, SignedDataVerifier>();
let library: Promise<typeof import("@apple/app-store-server-library")> | undefined;
function loadLibrary() { return library ??= import("@apple/app-store-server-library"); }
async function verifier(environment: Environment) {
  const { SignedDataVerifier, Environment } = await loadLibrary();
  let value = verifiers.get(environment);
  if (!value) {
    value = new SignedDataVerifier(roots, true, environment, "bolt.Primary-Gouge", environment === Environment.PRODUCTION ? 6790042189 : undefined);
    verifiers.set(environment, value);
  }
  return value;
}

export async function verify(kind: Kind, payload: string) {
  // Untrusted decoding selects a verifier only; no decoded claims are accepted
  // until Apple's unchanged verifier validates the chain, signature and identity.
  const claims = JSON.parse(Buffer.from(payload.split(".")[1] ?? "", "base64url").toString());
  const candidate = kind === "notification" ? claims.data?.environment ?? claims.summary?.environment ?? claims.appData?.environment : claims.environment;
  if (candidate !== "Sandbox" && candidate !== "Production") throw new SyntaxError("Unsupported environment");
  const checked = await verifier(candidate as Environment);
  if (kind === "transaction") return await checked.verifyAndDecodeTransaction(payload);
  if (kind === "renewal") return await checked.verifyAndDecodeRenewalInfo(payload);
  return await checked.verifyAndDecodeNotification(payload);
}

async function readBounded(request: Request, maximum: number): Promise<string> {
  if (Number(request.headers.get("content-length")) > maximum) throw new RangeError("size");
  const reader = request.body?.getReader();
  if (!reader) return "";
  const chunks: Uint8Array[] = []; let length = 0;
  try {
    while (true) {
      const { value, done } = await reader.read();
      if (done) break;
      length += value.byteLength;
      if (length > maximum) { await reader.cancel(); throw new RangeError("size"); }
      chunks.push(value);
    }
  } finally { reader.releaseLock(); }
  return Buffer.concat(chunks).toString("utf8");
}

export async function handle(request: Request, env: Env, verifyPayload = verify): Promise<Response> {
  const requestID = crypto.randomUUID();
  const json = (body: unknown, status: number) => Response.json(body, { status, headers: { "x-request-id": requestID, "cache-control": "no-store" } });
  if (new URL(request.url).pathname !== "/verify") return json({ error: "not_found" }, 404);
  if (request.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  if (!env.APPLE_VERIFIER_TOKEN || env.APPLE_VERIFIER_TOKEN.length < 32) return json({ error: "unavailable" }, 503);
  const expected = createHash("sha256").update(`Bearer ${env.APPLE_VERIFIER_TOKEN}`).digest();
  const received = createHash("sha256").update(request.headers.get("authorization") ?? "").digest();
  if (!timingSafeEqual(expected, received)) return json({ error: "unauthorized" }, 401);
  if (!request.headers.get("content-type")?.startsWith("application/json")) return json({ error: "invalid_request" }, 415);
  let body: { kind?: unknown; signedPayload?: unknown };
  try { body = JSON.parse(await readBounded(request, 110_000)); }
  catch (error) { return json({ error: "invalid_request" }, error instanceof RangeError ? 413 : 400); }
  if (!body || !["transaction", "renewal", "notification"].includes(String(body.kind)) || typeof body.signedPayload !== "string" || !body.signedPayload || body.signedPayload.length > (body.kind === "notification" ? 100_000 : 50_000)) return json({ error: "invalid_request" }, 400);
  try {
    const payload = await verifyPayload(body.kind as Kind, body.signedPayload);
    return json({ version: 1, kind: body.kind, payload }, 200);
  } catch (error) {
    const { VerificationException, VerificationStatus } = await loadLibrary();
    const retry = !(error instanceof VerificationException) && !(error instanceof SyntaxError) || error instanceof VerificationException && error.status === VerificationStatus.RETRYABLE_VERIFICATION_FAILURE;
    console.error(JSON.stringify({ request_id: requestID, kind: body.kind, category: retry ? "verification_unavailable" : "invalid_signed_data", verification_status: error instanceof VerificationException ? error.status : undefined }));
    const reason = error instanceof VerificationException && error.cause?.name === "JsonWebTokenError" ? "invalid_signature" : undefined;
    return json({ error: retry ? "verification_unavailable" : "invalid_signed_data", reason }, retry ? 503 : 422);
  }
}

export default { fetch: (request: Request, env: Env) => handle(request, env) };
