# App Store subscription deployment

The app and backend are configured for product ID
`bolt.primarygouge.premium.monthly` and bundle ID `bolt.Primary-Gouge`.

## 1. App Store Connect

1. Create the iOS app record with bundle ID `bolt.Primary-Gouge` and a stable SKU such as `primary-gouge-ios`.
2. Accept the Paid Apps Agreement and complete banking and tax setup.
3. Create subscription group `Primary Gouge Premium`.
4. Create `Premium Monthly` with product ID `bolt.primarygouge.premium.monthly`, a one-month duration, and the U.S. $6.99 price point.
5. Add a seven-day free introductory offer and English localization.
6. Copy the app's numeric Apple ID for the backend secret below.

Do not submit the subscription for review until its paid benefits, description,
review notes, and screenshot accurately describe the final paywall.

Debug and Release builds enable StoreKit purchasing. Keep the paid product in a
reviewable state and submit it with the first app version that exposes the
production paywall.

## 2. Deploy Supabase

Install or invoke the current Supabase CLI, then run from the repository root:

```sh
npx --yes supabase@latest login
npx --yes supabase@latest link --project-ref nsnezmbmosqtpychvpea
npx --yes supabase@latest db push
npx --yes supabase@latest secrets set APP_BUNDLE_ID=bolt.Primary-Gouge APP_APPLE_ID=<NUMERIC_APPLE_ID>
npx --yes supabase@latest functions deploy subscription-entitlement
npx --yes supabase@latest functions deploy apple-subscription-notifications --no-verify-jwt
```

`SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` are supplied
automatically to hosted Edge Functions. Never add the service-role key to the
iOS app or this repository.

For Sign in with Apple account deletion, also configure `APPLE_TEAM_ID`,
`APPLE_KEY_ID`, `APPLE_PRIVATE_KEY`, and `APPLE_CLIENT_ID=bolt.Primary-Gouge` as
Supabase function secrets. The private key must never be committed.

## 3. App Store Server Notifications V2

Set both the production and sandbox Notification V2 URLs to:

```text
https://nsnezmbmosqtpychvpea.supabase.co/functions/v1/apple-subscription-notifications
```

After saving the URL, send Apple's test notification and confirm a successful
delivery in App Store Connect and the Supabase Edge Function logs.

## 4. Local StoreKit testing

In Xcode, edit the Primary Gouge Run scheme and select
`Primary Gouge/Configuration.storekit` under Run > Options > StoreKit
Configuration. Use Xcode's StoreKit Transaction Manager to test renewal,
expiration, billing retry, grace period, refund, and revocation.

Transactions created by the local Xcode StoreKit configuration provide local
entitlement behavior but are not signed by Apple's production/sandbox chain, so
backend reconciliation is expected to retry. Use a Sandbox Apple Account on a
physical device for end-to-end JWS and server-notification verification.

## 5. App Review account

Create a dedicated verified account and grant it time-limited Premium access
using [APP_REVIEW.md](../APP_REVIEW.md). Store its password only in App Store
Connect's review-information fields.
