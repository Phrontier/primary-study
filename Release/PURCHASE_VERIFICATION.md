# Apple sandbox purchase verification — October 13, 2026

Build 1.0 (1), TestFlight internal Release Verification group.

- Owner confirmed one-week free trial and US $5.99/month.
- Owner completed purchase and all events unlocked on device.
- Initial database check: zero transactions, entitlements, and notifications. Client unlock alone does not establish backend readiness.
- Function-edge logs showed ES256 requests rejected with 401 (GET and POST). subscription-entitlement v4 had legacy gateway verification enabled.
- Deployed subscription-entitlement v5 with legacy verification disabled. Its existing Auth.getUser validation runs before any admin read/write, with original ownership and Apple signature checks preserved.
- Live probes verified missing and invalid credentials both return 401 with Sign-in is required.
- Awaiting owner Restore Purchases retry, persisted Apple Sandbox transaction/entitlement, reinstall restoration, renewal/refund notification checks.

No purchase backend pass is claimed yet. No synthetic production entitlement was inserted.

## Verifier repair — October 13

Isolated Cloudflare verifier deployed with Apple library 3.1.0, real roots, online revocation, authenticated internal POST /verify, and bounded requests. Supabase endpoints and ownership RPC retained. Live Worker authenticated probe using real Apple certificates reached invalid_signature rejection (422); missing credential returned 401. This demonstrates live certificate-chain and OCSP execution without granting access to invalid data.

Worker request-scoped initialization and native-fetch transport adapter preserve Apple's cryptographic verification unchanged. Local Miniflare OCSP requests returned HTTP 403; the deployed Worker passed the same chain path. No online check was disabled.

After the first restore retry, subscription function v8 returned 401. Local reproduction confirmed duplicate lowercase/uppercase Authorization headers combined two bearer tokens. Canonical Authorization header deployed in subscription-entitlement v9 and regression test passes. Notifications use v6.

Nine Worker tests and eleven Supabase tests pass; TypeScript checks pass. The public policy was updated to include Cloudflare Apple purchase verification and effective date October 13. Owner asked to retry restore after v9. Real transaction/entitlement persistence and lifecycle tests remain pending; no backend pass claimed.

## Restore follow-up

Owner still sees sync message after v9. Live logs show authenticated GET 200 and purchase POST 400; failure category persistence_or_ownership. Database function exists and service_role has execute permission. Rollback-only production subscription_atomic.sql passed again, including ownership, duplicate/stale events and partial-write rollback. No fixture rows were committed. Diagnostic subscription function v10 adds safe SQL/API error codes; awaiting next restore to identify the live persistence failure. Repair is not yet complete.

### October 13: persistence permission repair

The phone restore reached verified transaction persistence but returned PostgreSQL `42501`. Production `service_role` had write access to subscription tables and RPC execution, but lacked the account-ID lookup permission on `auth.users` required by invoker ownership checks. Migration `20261013204024_subscription_owner_lookup_permission.sql` grants SELECT on **id only** to that server role. The RPC remains SECURITY INVOKER; no ordinary-user permissions were added.

`supabase/tests/subscription_service_role.sql` passed against production in a rollback-only transaction: purchase persistence, repeated reconciliation, notification-first account resolution, and restricted Auth column/function permissions. No synthetic records persisted. Awaiting a real TestFlight restore after this repair; successful Apple verification alone does not establish account synchronization.

Post-fix live query confirmed **one real Sandbox transaction and one matching active, unexpired account entitlement**, with matching owner and original transaction. This establishes real authenticated purchase reconciliation after the permission repair. Apple notification count remains zero; notification delivery and lifecycle coverage remain pending. Phone message clearance still needs confirmation.

### Owner confirmation and next lifecycle gate

Owner confirmed the synchronization message cleared after the live account-ID permission repair. Real-device purchase plus backend persistence is passed. The next check found no persisted Apple notifications and auto-renew status still unknown; historical failures predate the Cloudflare verifier deployment. App Store Connect session expired and a sign-in tab was opened to inspect notification configuration before the next cancellation test. Cancellation, renewal, expiry, refund, and reinstall restoration remain unverified.

App Store Connect audit after owner sign-in confirmed both Production and Sandbox Server URLs point to the existing `apple-subscription-notifications` endpoint. No settings changed. Owner was asked to disable renewal through the app's Manage Subscription control, retain the subscription without resubscribing, and confirm current Premium access. Next query should check `DID_CHANGE_RENEWAL_STATUS`, `will_auto_renew=false`, and unchanged access until verified expiry.

### Real Apple cancellation notification passed — October 13

Owner cancelled through Manage Subscription and confirmed Premium remains available. Supabase persisted Apple's Sandbox `DID_CHANGE_RENEWAL_STATUS / AUTO_RENEW_DISABLED` notification signed at 2026-10-13 21:07:50.159 UTC. Matching entitlement is active, unexpired, and `will_auto_renew=false`; verified expiry is 2026-10-14 02:14:51 UTC (October 13, 9:14:51 PM America/Chicago). This establishes live signed notification verification and persistence, including cancellation without premature access removal. Renewal, expiry, reinstall restore, account mismatch/deleted-owner recovery, grace/refund remain external lifecycle gates.

### Sign-out control and build recovery — October 13

Profile Account Details now exposes the existing AccountStore.signOut operation via a Sign Out button (disabled while account work is in progress). Existing phone build does not include this control yet. xcodebuild stalled for over an hour in NSFileCoordinator while opening the OneDrive project; a stack sample confirmed the file-access coordination wait. Terminated that specific process and copied the project, app sources, and required Contents assets into /tmp. Bounded unsigned Release device build from that local copy passed (exit 0), validating the sign-out change. Log: /tmp/primary-gouge-local-validation.log. Future archive validation should use a complete local snapshot to avoid the cloud-folder stall. Signed archive/upload and device sign-out verification remain pending.

Build 1.0 (2) signed archive succeeded and upload accepted at 2026-10-13 20:08:29 local Mac log time after Xcode account reauthentication. App Store Connect confirms Processing. Earlier two uploads failed with expired interactive credentials; no API key was created. Includes the Sign Out control and current app source/privacy disclosure. Processing and tester assignment must be confirmed before claiming install availability.

### Real-device sign-out and expiry passed — October 13 (Central)

Owner confirmed Sign Out works in the installed updated build, and opening Premium content after subscription expiry displays the Premium expired screen. Supabase independently confirms the Sandbox entitlement is expired, auto-renew disabled, and expiry deadline passed. Apple `EXPIRED / VOLUNTARY` notification signed 2026-10-14 02:15:04.803 UTC persisted successfully (October 13 Central). Cancellation-at-period-end and expiry now pass both device behavior and verified backend notification persistence. Renewal, refund/revocation, grace/billing retry, cross-account ownership and deleted-owner recovery still require real sandbox evidence.

### Resubscription after expiry passed — October 13 (Central)

Owner resubscribed without synchronization error. Supabase entitlement is active and unexpired with auto-renew enabled. Apple Sandbox `SUBSCRIBED / RESUBSCRIBE` notification signed 2026-10-14 03:07:40.573 UTC persisted. New period ends 2026-10-15 03:07:39 UTC (October 14 at 10:07:39 PM Central). Automatic renewal itself is still pending; resubscription is a separate lifecycle event.
