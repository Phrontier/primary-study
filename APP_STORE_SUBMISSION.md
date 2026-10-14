# App Store submission handoff

Updated October 4, 2026. Structural readiness remains **pending**. Signed Release archive succeeded October 12, 2026. After refreshing Xcode credentials, App Store distribution export/upload succeeded October 12, 2026 and Apple reports the package is processing. Build 1.0 (1) is assigned to Release Verification and group status is Testing; owner saved the operating-system-only encryption declaration. Apple-signed purchases remain unverified.

Primary Gouge retains its permanent free tier and Premium Monthly product `bolt.primarygouge.premium.monthly`. The owner selected US **$5.99/month** at launch; this saved price was verified in App Store Connect. The existing seven-day introductory trial remains subject to Apple Account eligibility. Price and trial presentation come from StoreKit.

## Implemented

- Injectable StoreKit client, deterministic deadline-based entitlements, expired-token refresh with one authentication retry, and account/session guards.
- Valid verified local access during backend outages; persisted account-scoped reconciliation queue across launches; deleted-owner restoration through backend verification.
- Atomic subscription ownership, transaction, entitlement, and notification updates. Duplicate/stale events are ignored; grace deadlines are persisted and returned.
- Moderator-controlled contributor bans enforced by the Worker, with moderator UI controls, reporting, support/appeal access, and documented response procedures.
- HTTP/download validation before video caching. Account changes clear private history, drafts, quiz/progress data and reminders. Future TOLD/Fuel/Jet Log tools are hidden.
- Corrected stale Systems brief assertions and UI selectors without dropping coverage. Added purchase lifecycle, backend handler/atomicity, moderation, and invalid-download tests.
- Draft public privacy, terms, support pages and App Store metadata prepared under `Release/`. Description, promotional text, keywords and subtitle saved to the App Store draft.

## Production changes verified

- Supabase restored to ACTIVE_HEALTHY. Migration `20261004222633_atomic_subscription_processing.sql` applied. Updated entitlement and Apple notification functions deployed as version 4; delete-account deployed source matches the repository.
- Production entitlement rejects unauthenticated calls (401); notification endpoint rejects invalid payloads (400).
- APP_APPLE_ID and APP_BUNDLE_ID secret digests match app 6790042189 and bolt.Primary-Gouge.
- Cloudflare contributor-ban migration applied and Worker deployed, version `584d7db3-53f7-4c98-8c13-2c5abb23c398`. Health returns 200; anonymous submission returns 401.
- Apple Developer agreement acceptance confirmed by owner. Xcode now recognizes the Apple account. Paid Apps and Free Apps agreements, banking, US tax form, and DSA status show Active in App Store Connect.
- US subscription price $5.99 saved; one-week trial previously verified. Both Apple notification URLs point to the Supabase notification function.

## Test evidence

These are recorded results, not a claim that every planned scenario has been verified.

| Check | Result / evidence |
| --- | --- |
| iPhone 17 Pro, iOS 26.4.1 | 104 deterministic unit tests and 10 UI tests passed on final source; `Release/Evidence/iphone-current.json`, `/tmp/primary-gouge-account-reset-final.xcresult` |
| iPad Pro 13 M5, iOS 26.4.1 | 104 unit tests and 12 UI tests passed on final source; `Release/Evidence/ipad-current.json`, `/tmp/primary-gouge-ipad-current.xcresult` |
| Backend handlers | 7 Deno tests passed; entitlement, notification and deletion functions type-check |
| Database atomicity | Rollback-only production SQL assertions passed for ownership, grace, duplicate/stale events, partial-write rollback, deleted-owner restoration and privileges |
| Worker | TypeScript check and local real-D1 moderation integration test passed |
| Content/import | All 114 resource paths exist; all 37 video range probes passed; two importer tests passed |
| Release device build | Final source unsigned Release device build passed; `/tmp/primary-gouge-release-current.log` |
| Real local StoreKit | Unresolved Apple simulator test-service failures/stalls; this test has not passed |

The final iPhone run includes the cold-start account-reset regression and current-price configuration. Test results in `/tmp` are local session evidence and are not durable release artifacts.

## Remaining release gates

1. **Signing/TestFlight:** Phone registration and provisioning succeeded after enabling Developer Mode. Signed Release archive at /tmp/PrimaryGouge-Connected.xcarchive succeeded October 12. After refreshing Xcode credentials, the retry completed with EXPORT SUCCEEDED and “Uploaded package is processing.” Release Verification internal group was created with manual build distribution. Owner-authorized internal tester addition completed: CJ Bolt is in Release Verification. Build 1.0 (1) processing and compliance are complete; assigned to Release Verification and verified status Testing. Purchase verification remains pending. Evidence: Release/Evidence/testflight-build-testing.png. Evidence: Release/Evidence/testflight-tester-added.png. Successful upload evidence: Release/Evidence/testflight-upload-success-oct12.log. Evidence: Release/Evidence/signed-archive-oct12.log and testflight-upload-oct12.log.
2. **Apple account deletion:** Supabase lacks APPLE_TEAM_ID, APPLE_KEY_ID, APPLE_PRIVATE_KEY and APPLE_CLIENT_ID. Configure a Sign in with Apple key securely; never commit its `.p8` contents. Verify Apple sign-in and token revocation during controlled account deletion.
3. **End-to-end purchases:** Complete `Release/TESTFLIGHT_PURCHASE_CHECKLIST.md` on a phone. Prove Apple-signed purchase/restore/reinstall/renewal/refund and notification delivery update production records. Fake StoreKit and local Xcode tests do not establish this.
4. **Authentication/data deletion:** Verify email verification/reset delivery, Apple login, profile persistence, account isolation, and documented local/remote deletion with controlled test accounts.
5. **Reviewer access:** No active override exists. Create and verify a dedicated reviewer account, grant restricted server-side review access, and enter credentials only in App Store Connect. See `APP_REVIEW.md`.
6. **Public pages/contact — complete October 5, 2026:** App-specific privacy/support/terms pages are live on primarygouge.com, admin@primarygouge.com is the published contact, Support/Privacy URLs are saved in App Store Connect, and the owner published the twelve-type privacy disclosures. Evidence is in Release/Evidence/app-privacy-published.png.
7. **App Store record:** Complete age rating, content-rights answers, screenshots, subscription review screenshot and group localization, review notes, build selection, and subscription attachment. Confirm DSA trader declaration with the owner. Audit notification V2 delivery, billing-grace configuration, and streamlined/multiseat purchase settings against account ownership rules.
8. **Testing gaps:** Current deterministic iPhone/iPad suites pass. Complete additional PDF, download, quiz, reminder, recovery/deletion and moderation flows. Resolve or document the local StoreKit service failure. Verify concurrent ownership claims in an isolated database.
9. **Content rights and operations:** Owner must confirm rights to all publications/videos and a staffed moderation/support response process before submission.

Automatic approval review rejected committed synthetic-user fixtures in production for the concurrency test. Rollback-only atomicity checks passed; the simultaneous-claim test remains unverified and should use an isolated database. Automatic review also rejected worldwide price recalculation without explicit scope; the owner subsequently set and saved the launch price directly.

App Store approval remains Apple’s decision. Do not submit or declare complete until every gate above has supporting evidence.

## Purchase verification repair — October 13, 2026

Deployed isolated Cloudflare Apple verifier and Supabase HTTPS client without app endpoint changes. Live real-certificate/OCSP probe passed through signature validation, rejecting intentionally invalid data. Dedicated server-only credential configured; missing/invalid access remains rejected. Worker tests: 9 passed; Supabase tests: 11 passed; type checks passed. Subscription reconciliation v9 includes canonical Authorization header correction; notification function v6 uses the remote verifier. Public privacy policy now lists Cloudflare purchase verification.

See Release/PURCHASE_VERIFICATION.md and Release/Evidence/apple-verifier-rollout-oct13.json. Waiting for owner restore retry to confirm real Sandbox transaction and entitlement persistence. Restore/reinstall, lifecycle notifications and remaining release gates are not yet complete.
