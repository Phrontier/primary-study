import "jsr:@supabase/functions-js@2.117.2/edge-runtime.d.ts";
import {
  verifyNotification,
  AppleVerificationError,
  verifyRenewalInfo,
  verifyTransaction,
} from "../_shared/apple-store.ts";
import {
  createAdminClient,
  persistTransaction,
} from "../_shared/subscription-database.ts";

const headers = { "content-type": "application/json; charset=utf-8" };

function response(status = 200): Response {
  return new Response(null, { status, headers });
}

export async function handleNotificationRequest(request: Request, dependencies = { verifyNotification, verifyTransaction, verifyRenewalInfo, createAdminClient, persistTransaction }): Promise<Response> {
  if (request.method !== "POST") return response(405);

  try {
    const body = await request.json().catch(() => null) as { signedPayload?: unknown } | null;
    if (!body || typeof body.signedPayload !== "string" || body.signedPayload.length > 100_000) {
      return response(400);
    }

    const notification = await dependencies.verifyNotification(body.signedPayload);
    if (!notification.notificationUUID || !notification.notificationType || !notification.signedDate) {
      return response(400);
    }

    const admin = dependencies.createAdminClient();
    let transaction = null;
    let renewal = null;
    if (notification.data?.signedTransactionInfo) {
      transaction = await dependencies.verifyTransaction(notification.data.signedTransactionInfo);
    }
    if (notification.data?.signedRenewalInfo) {
      renewal = await dependencies.verifyRenewalInfo(notification.data.signedRenewalInfo);
    }

    if (renewal && transaction && renewal.originalTransactionId !== transaction.originalTransactionId) {
      return response(400);
    }
    await dependencies.persistTransaction(admin, transaction, {
      serverStatus: notification.data?.status,
      willAutoRenew: renewal ? renewal.autoRenewStatus === 1 : undefined,
      graceExpiresAt: renewal?.gracePeriodExpiresDate,
      notification: {
        notification_uuid: notification.notificationUUID,
        notification_type: notification.notificationType,
        subtype: notification.subtype ?? null,
        environment: notification.data?.environment ?? transaction?.environment ?? null,
        signed_at: new Date(notification.signedDate).toISOString(),
      },
    });

    return response(200);
  } catch (error) {
    // A non-2xx response tells Apple to retry. Never acknowledge an unverified
    // or partially persisted notification as successfully processed.
    console.error(JSON.stringify({ operation: "apple-subscription-notifications", category: error instanceof AppleVerificationError ? error.category : "persistence_or_ownership" }));
    return response(400);
  }
}

if (import.meta.main) Deno.serve((request) => handleNotificationRequest(request));
