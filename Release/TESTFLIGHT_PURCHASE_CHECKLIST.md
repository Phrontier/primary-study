# TestFlight purchase verification

Record build number, device/iOS version, date, app account UUID, Apple sandbox transaction ID, and matching database/notification results for every step. Do not publish tester passwords or Apple private keys in this report.

## Setup

- Add the Apple Developer account in Xcode; register a development device or install a valid signing profile. Create a signed Release archive, validate it, and upload it as an internal TestFlight build. Disable the local StoreKit configuration when testing Apple sandbox transactions.
- Confirm Premium Monthly product `bolt.primarygouge.premium.monthly`, one month, US $5.99, seven-day introductory offer, and localization/review screenshot. Keep product identifiers unchanged.
- Confirm both App Store Server Notifications V2 URLs point to `https://nsnezmbmosqtpychvpea.supabase.co/functions/v1/apple-subscription-notifications`. Request Apple’s test notification and verify successful delivery. Production numeric Apple ID is 6790042189.
- Configure Apple authorization-revocation secrets in Supabase: APPLE_TEAM_ID, APPLE_KEY_ID, APPLE_PRIVATE_KEY, APPLE_CLIENT_ID. The private key stays outside the repository. Verify email/Apple sign-in and account deletion using controlled tester accounts.
- The sandbox test account must be eligible for the introductory offer. Local Xcode StoreKit transactions cannot establish Apple-signed backend readiness.

## Phone walkthrough

1. Install the internal TestFlight build. Sign up, verify email delivery, complete profile, and confirm the free tier. Repeat with Sign in with Apple. Test email password reset and sign-out/sign-in.
2. Open More → Premium. Verify Apple supplies price and trial eligibility. Cancel Apple’s purchase sheet: no access change. Complete purchase: Premium unlocks and a signed transaction appears in Supabase for the same app account UUID.
3. Relaunch and verify access remains. Delete and reinstall the app, sign into the same account, use Restore Purchases, and verify entitlement/ownership persists. Another existing app account must receive an ownership conflict and no Premium access.
4. Disable auto-renewal: access continues through the paid deadline. Trigger accelerated renewal and inspect a newer transaction plus the matching notification. After expiry, access closes on client and server.
5. Exercise billing retry and billing grace period using Apple sandbox tools. Grace access must end at the grace deadline; billing retry without valid grace must not unlock.
6. Request a sandbox refund/revocation. Confirm the notification is persisted and Premium closes after refresh. Send a duplicate notification/test replay: one notification record and no duplicate ownership or entitlement changes.
7. Disconnect during purchase reconciliation. Local verified access remains only until its deadline; restart, reconnect, and verify persisted reconciliation retries. Switch accounts during delayed work and verify no private history or Premium access leaks.
8. Delete the original app account while preserving the Apple subscription, create a replacement account, and Restore Purchases. Recovery must work only after the original owner is deleted; account deletion itself must remove private cloud/local data and revoke Apple authorization. Cancel the subscription separately through Apple.
9. Test instructor submission/report/moderation with controlled accounts. Block a contributor, verify rejection, appeal via Support, unblock, and verify account deletion removes its account-linked submissions.

## Evidence and result

Record each step as PASS/FAIL with observed client state, database state, and Apple notification timestamps. Read-only database checks can inspect app_store_transactions, subscription_entitlements, and app_store_notifications for the controlled test transaction. Never fabricate or directly insert a production entitlement to make a purchase test pass.

Structural readiness requires a signed validated upload, all automated checks passing, authenticated production behavior, successful Apple sandbox reconciliation/restoration/notification checks, and closed publication gates. Apple approval is separate.

Apple guidance: https://developer.apple.com/documentation/storekit/testing-at-all-stages-of-development-with-xcode-and-the-sandbox
