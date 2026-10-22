# Remaining selected native screens

> App-wide extension: see [current design language](design-language.md), [screen recipes](screen-recipes.md), and [coverage audit](screen-audit.md). This document retains the scope and evidence of its original pass; it is not a restriction on the authorized app-wide rollout.

**Status:** Implemented October 15, 2026; visual/UI validation complete, with the StoreKit verification limitation recorded below. The new native screens await visual review.

The user approved Home and the connected event/study pilot, then authorized implementing the remaining selected designs. This pass translates the locked studies rather than exploring new directions.

## Selected references and implementation

| Area | Reference | Native translation |
| --- | --- | --- |
| Instructor browsing | Round 04 A, C filter control, rating color A | Open roster, search, All/Sims/Flights segmented control, full-width blue review action, aligned colored averages and seven-segment scales |
| Instructor detail | Round 07 A | Open identity, blue At a glance rule, overall score pair, individual white review cards with each submission's scores and text |
| Welcome | Onboarding A | Layered product illustration, centered greeting/description, native Apple button, outlined email action, sign-in and legal links |
| Account creation | Onboarding A | 32pt title, understated underline fields, blue action; same language extends to sign-in, verification, and password recovery |
| Training setup | Onboarding A | Open fields and existing choices; compact blue “Not sure yet? Start with Echo.” callout; existing profile save/default behavior |
| More | First integrated-banner selection | Full-width blue header with identity and aviation artwork, gold membership module, white grouped destinations |
| Settings | Existing native preferences in the selected language | Compact back header, open title and focus section, white grouped content and existing focus-manager sheet |
| Premium | Selected A-palette/C-composition hybrid | Blue illustrated header, overlapping white timeline, rounded nested rail, centered live offer, Secured by Apple, prominent Continue and dismissal |

`SelectedDesign.swift` contains scaled typography, shared action/surface treatments, the native product illustration, and aviation motif. The More banner reuses the already selected illustration in the `StudyAviation` image asset. No new image generation or runtime image dependency is introduced.

## Fidelity details

- Root/content insets retain 22pt; account screens use the selected 24pt inset.
- Instructor identity titles use 18pt bold; paired numbers use 26pt/31pt and compact review values use 21pt/25pt. Category labels, denominators, seven segments, and descriptors remain distinct.
- Scores still store 1–7 and display normalized out of ten. Color follows the rounded raw score, including explicit bright dark-mode foregrounds. No rating data or review text is invented.
- Account titles use 32pt/36.8pt with −1pt tracking, field labels 12pt, fields 14pt, and actions 15pt. The product illustration is decorative and excluded from accessibility reading order.
- More's banner is integrated into the page and fills the status-bar safe area. Its gold module shows actual entitlement status; it does not fabricate a trial date. Manage retains light gold with dark-gold text in dark mode.
- Premium uses a 35pt/37.8pt headline, 18pt step headings, 14pt/21pt body, a 30pt timeline rail, 20pt card corners, and a 15pt Continue radius. There are no ticket-edge circles or dotted seam.
- Native segmented controls, menus, Apple buttons, permission sheets, and subscription-management/purchase sheets retain platform behavior and sizing. Status bars, tab bars, SF Symbols, and font rasterization remain native. Real names, reviews, counts, and membership states differ from the static reference's fictional content.

## Accessibility adaptations

Layouts expand vertically. Instructor scores stack at accessibility sizes; labels and descriptors remain present. The roster search uses the shorter visible placeholder “Search” at accessibility sizes while retaining the full accessibility label. More's avatar initials remain a fixed decorative glyph; long names receive the available width and decorative aviation art is omitted at accessibility sizes. Gold membership content stacks above Manage. Account fields, callouts, and actions grow and scroll; no fixed preview-height clipping is imposed.

## Subscription behavior

Localized price and introductory-trial eligibility still come from StoreKit. Eligible day/week offers supply their actual duration; Day 5/Day 7 is shown for a seven-day trial. Ineligible or unavailable products do not receive a fabricated trial or price. Active/grace access, pending, cancellation, errors, restore, account synchronization and Apple management remain connected to the existing subscription store.

Continue offers a reminder choice before an eligible trial purchase. Notification permission is requested only after the user selects reminders. After a successful purchase, a one-time local notification uses the verified entitlement expiration minus 48 hours. Scheduling requires authorization and a future trigger; failure does not produce a success claim. Continuing without reminders still reaches Apple's purchase interface. Daily study preferences remain separate, and signing out removes account notifications.

The display fixture requires both `--ui-testing` and `--premium-fidelity-fixture` in a Debug build. It shows a clearly documented sample seven-day/$9.99 offer for composition review. Its Continue/skip actions only demonstrate the reminder screen and never call StoreKit or request notification permission. It cannot grant access. The training-setup fixture likewise requires the UI-test flag and does not save sample profile data. Release builds exclude these fixture conditions.

No authentication, review submission/moderation, entitlement policy, backend schema, or pricing changes are included. Account deletion and sign-out remain explicit existing actions. Peripheral screens without an approved study—such as moderation, report forms, and support articles—retain their existing layout; navigation to them is preserved.


## Validation and review artifacts

The comparison gallery is `previews/remaining-fidelity.html`. Each selected normal/light screen has a reference/native pair and an overlay excluding system chrome. Supporting captures show actual review cards, free/active membership, Settings, the Premium reminder step, and the bottom of long forms. Dark/normal and dark/largest-accessibility captures accompany the selected screens.

Prices, instructor identities/reviews, and existing training defaults differ where native views use real data. The sample Premium offer is display-only. Native control sizes and the actual password minimum guidance can add vertical space absent from the static form reference.

The store currently reports active entitlement and expiration, rather than a separate verified trial-versus-paid membership flag; More does not infer or fabricate that distinction. Billing retry, grace, expired, loading, unavailable, pending, and restore states retain explicit handling. Premium uses Close to return because the selected purchase flow hides the tab bar; content-access regression tests follow that path before switching tabs.

The local StoreKit integration test could not load a product: iOS 27's test service reported an unknown storefront error with storefront nil, including a retry with explicit USA/en_US settings. This remains a verification limitation, not a passed purchase test. The mock subscription lifecycle tests cover purchase success, cancellation, pending, unavailable/unverified product, account isolation, restore, renewal, grace/retry/expiry/refund, and authentication retry. No real App Store purchase was performed. A StoreKit/TestFlight purchase and delivered notification still require validation in a working StoreKit environment.

## Recorded checks

- Debug simulator build passed at the 393 × 852 logical iPhone 14 Pro size.
- Instructor roster → instructor detail → individual review cards → Back → More → Premium active → Close → Settings passed.
- Welcome → account creation, training setup scrolling, sample Premium offer → reminder choice → skip → offer passed without creating an account, purchasing, or requesting notification permission.
- Password creation and reset retain live minimum-length guidance and keyboard interaction; both regression tests passed after account-footer changes.
- Free/Premium access from Events and Search/More passed after following the selected offer's Close path before changing tabs.
- The previously approved connected event/discussion/flashcard flow passed after this rollout.
- Twelve targeted model tests passed: ten subscription lifecycle cases, instructor scale formatting, and trial reminder permission/timing boundaries.
- Normal dark and largest-accessibility dark screen-family flows passed. Type scales relative to heading, title, body, and caption roles; columns stack and long content scrolls.
- `git diff --check` passed. Comparison assets and supporting-state links resolve locally.

Evidence: `/tmp/remaining-final-captures-light.xcresult`, `/tmp/remaining-final-captures-dark.xcresult`, `/tmp/remaining-auth-final-light.xcresult`, `/tmp/remaining-auth-final-dark.xcresult`, and `/tmp/remaining-accessibility-final.xcresult`. Access regressions passed in `/tmp/remaining-dark-final.xcresult`; that bundle also contains the separately failed local StoreKit integration retry documented above. The earlier connected pilot/auth regressions and targeted models are in `/tmp/remaining-final-light.xcresult`, which also contains the initial StoreKit failure and a tab-navigation test subsequently updated to use the selected full-screen offer's Close action.

Builds use a local temporary source copy to avoid OneDrive coordinated-read stalls; the workspace remains authoritative. This is simulator verification, not real-device/VoiceOver certification or App Store purchase/delivery verification.
