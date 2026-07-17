import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import {
  verifyNotification,
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

Deno.serve(async (request: Request) => {
  if (request.method !== "POST") return response(405);

  try {
    const body = await request.json().catch(() => null) as { signedPayload?: unknown } | null;
    if (!body || typeof body.signedPayload !== "string" || body.signedPayload.length > 100_000) {
      return response(400);
    }

    const notification = await verifyNotification(body.signedPayload);
    if (!notification.notificationUUID || !notification.notificationType || !notification.signedDate) {
      return response(400);
    }

    const admin = createAdminClient();
    let transaction = null;
    let renewal = null;
    if (notification.data?.signedTransactionInfo) {
      transaction = await verifyTransaction(notification.data.signedTransactionInfo);
    }
    if (notification.data?.signedRenewalInfo) {
      renewal = await verifyRenewalInfo(notification.data.signedRenewalInfo);
    }

    if (transaction) {
      await persistTransaction(admin, transaction, {
        serverStatus: notification.data?.status,
        willAutoRenew: renewal?.autoRenewStatus === 1,
      });
    }

    // Record idempotency only after the entitlement update succeeds. If a
    // database write fails, Apple receives a non-2xx response and can retry the
    // complete operation instead of finding a prematurely recorded UUID.
    const { error: notificationError } = await admin.from("app_store_notifications").insert({
      notification_uuid: notification.notificationUUID,
      notification_type: notification.notificationType,
      subtype: notification.subtype ?? null,
      original_transaction_id: transaction?.originalTransactionId ?? null,
      environment: notification.data?.environment ?? transaction?.environment ?? null,
      signed_at: new Date(notification.signedDate).toISOString(),
    });
    if (notificationError?.code === "23505") return response(200);
    if (notificationError) throw notificationError;

    return response(200);
  } catch (error) {
    // A non-2xx response tells Apple to retry. Never acknowledge an unverified
    // or partially persisted notification as successfully processed.
    console.error("apple-subscription-notifications", error);
    return response(400);
  }
});
