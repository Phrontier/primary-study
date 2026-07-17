# App Store submission handoff

Primary Gouge 1.0 is configured as an account-gated app with a permanent free
tier and the auto-renewable subscription `bolt.primarygouge.premium.monthly`.
Every account can use Home, instructor gouge, the NATOPS Question of the Day,
the EPs / Limits / N/W/C deck, Contacts ground school, and the first two
Contacts simulator events. An active subscription, billing grace period, or
time-limited App Review override unlocks everything else. No Premium study
content was removed.

## Verified locally

- Release device archive builds successfully without signing.
- App icon, dark icon, tinted icon, and `PrivacyInfo.xcprivacy` are embedded.
- Minimum iOS version is 17.0; marketing version is 1.0 (build 1).
- 83 unit tests pass.
- Account-gate, App Review Premium access, core navigation, and launch UI tests
  pass across all configured launch appearances.
- Cloudflare Worker and all Supabase Edge Functions type-check.
- Production Cloudflare health check succeeds.
- All 37 production Premium video URLs return HTTP 200 and support byte ranges.
- Production subscription schema and three Edge Functions are present.

## Required before clicking Submit for Review

1. Add the Apple Developer account for team `7SY3P7B4H3` in Xcode Settings >
   Accounts. Download profiles, then create and validate a signed archive.
2. Apply pending Supabase migration `20260712223605_app_review_demo_access.sql`.
   The CLI connection stalled during both dry-run and push, so the migration was
   not marked applied.
3. Add Supabase function secrets `APPLE_TEAM_ID`, `APPLE_KEY_ID`,
   `APPLE_PRIVATE_KEY`, and `APPLE_CLIENT_ID=bolt.Primary-Gouge`, then deploy
   `delete-account`. Never commit or paste the `.p8` private key into source.
4. Deploy `subscription-entitlement` after the reviewer-access migration so it
   can read the override table.
5. Create and verify a dedicated reviewer account, complete its profile, grant
   its 90-day override, and put the credentials only in App Store Connect. Follow
   [APP_REVIEW.md](APP_REVIEW.md).
6. Publish monitored Support, Privacy Policy, and Terms URLs and add them to App
   Store Connect. The in-app copies are complete, but public URLs still require
   the final support email/domain.
7. Confirm the Paid Apps agreement, tax, and banking status; submit Premium
   Monthly with app version 1.0; configure and test App Store Server
   Notifications V2 as described in
   [supabase/APP_STORE_SUBSCRIPTIONS.md](supabase/APP_STORE_SUBSCRIPTIONS.md).
8. Add final screenshots, description, keywords, age rating, content-rights
   answers, and review notes. Confirm distribution rights for every bundled
   publication and training video.

## Archive blocker observed

The signed archive attempt stopped before compilation with `No Accounts` and
`No profiles for 'bolt.Primary-Gouge' were found`. This is an Xcode account and
provisioning setup issue, not a source or build failure. The matching unsigned
Release archive completed successfully.
