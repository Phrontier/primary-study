# Home studies · Round 01

Open `index.html` directly, or serve this folder with `python3 -m http.server 8765 --bind 127.0.0.1` and open http://127.0.0.1:8765.

Four 393 × 852 light-mode phone studies. Each phone scrolls independently; controls are intentionally static. Use the links beneath each phone to isolate a direction.

- `content.js`: shared sample content; update once for all options.
- `styles.css`: common styling, then A/B/C/D overrides. Variables control color and typography.
- `studies.js`: shared markup and consistent inline SVG icons.
- `screenshots/`: initial and scrolled viewport captures for reference.

Streak, daily activity, and recent history are sample data. Daily metric selection is unresolved. Event names and daily question come from the app's content; no study answers or app navigation are implemented here. Native typography and behavior will need a later SwiftUI pilot.

Stop after reviewing Home. Companion event and instructor studies follow selection; no official design language has been established.

## Round 02

Open `?round=2` for three targeted refinements on A's layout with B's green reference tile. A1 uses a flame and plain count; A2 explores a sample daily goal; A3 uses paired circles without a goal. The emoji flame is temporary artwork. Feedback is recorded in `../decisions.md`. Original A–D studies remain available at the base URL.

## Round 03

Open `?round=3` for proposed Events root, Contacts Sims event list, and Instructors root studies. Home A1 is the approved foundation; these companion patterns await feedback. Current manifest includes five phases (including Capstone), unlike the older four-phase screenshot. Event list content is copied from the current Contacts Sims category. Instructor identities and scores are deliberately fictional sample data, not claims about real instructors. Shared rules are recorded in `../design-language.md`.

Round 03 now includes A/B/C for each of the three screens (nine studies). Each group uses identical content. A retains the original study; B tests grouped white surfaces; C tests alternate task-specific arrangements within the approved Home language. Solo URLs retain `events`, `list`, and `instructors` for A; append `-b` or `-c` for the alternatives.

## Round 05 — Instructor color only

Open `?round=5` for three color treatments on the same refined instructor layout. A retains colored numbers and the segmented scale; B removes the scale and uses colored numbers/labels; C gives scores soft tinted badges. Numeric data, semantic mapping, descriptors, control, and Submit Review placement remain the same. No treatment is approved yet.

The active round 05 comparison is now A/D/E. B and C were rejected and removed from the active board; their earlier screenshot remains as history. D uses a continuous red-to-green spectrum with a marker. E uses a compact semantic-color arc. Neither is approved yet.

## Round 06 — Detail and reading screens

Open `?round=6` for nine studies: event detail, instructor detail, and discussion-item reading, with A/B/C for each. Use `kind=eventdetail`, `kind=instructordetail`, or `kind=discussion` to compare one screen. A favors open sections; B tests grouped white surfaces; C uses compact hierarchy and colored anchors. All retain Home's palette, type, navigation, and selective cards. Discussion reading is the reading page, not the flashcard interaction (a later study).

Event overview and the first three complete discussion sections come from the FAM2101 content override. Instructor identities, scores, and review prose are fictional. No new study content is authored here. These detail patterns require user review.

## Round 08 — Flashcards

Open `?round=8` for nine studies: deck overview, question face, answer face, A/B/C per screen. Filter with `kind=deck`, `kind=question`, or `kind=answer`. Prompts and complete answers come from the current FAM2101 deck (seven cards). All-new state, streak/history elsewhere, and session position are sample data. Tap a card (or press Enter/Space) to reveal/hide its answer locally. Rating buttons and review actions remain static; no scheduling, progress, or navigation is saved. Question and answer comparisons use the same first card.

## Round 10 — Account, More, and subscription flows

Open `workflows.html?area=onboarding`, `workflows.html?area=more`, or `workflows.html?area=subscription`. Three options share content and flow requirements. The Flow screen selector changes all three previews together; demo navigation buttons change only local sample stages. No authentication, data collection, OS permissions, profile writes, purchase, cancellation, or subscription management takes place.

Onboarding includes welcome, email creation, verification, training setup, ready, sign-in, password reset, and error specimens. More preserves current normal-user groups and destinations; settings/profile/notification/active subscription specimens follow. Subscription includes offer, illustrative eligible trial, native Apple handoff, active, unavailable pricing, pending, error, and free-access states. Monthly pricing remains a placeholder; no annual plan, discounts, App Store ratings, reminder promise, or real entitlement is invented. Trial length is an illustrative seven-day example, not a guarantee.

References and what was borrowed are in `../references.md`. All round 10 directions await review. Dark mode and larger-text validation follow selection.

## Reference-led onboarding concepts

Open `onboarding.html` for three directions across welcome, account creation, and training setup only. A follows Fable's product-demo composition using a miniature of the approved Home language; B follows Jomo's illustration-led welcome and rounded field treatment; C follows Uptime's colorful content collage. Existing Apple/email and training requirements are preserved. Verification/reset/error specimens remain outside this visual round and will follow the selected language during implementation. The generated aviation artwork is exploratory, not a mascot or final branding. No authentication or profile data is saved.

## More/settings B refinements

Open `more-options.html` for warm-gold, illustrated-profile, and blue/gold treatments, all based on B's grouped content. Flow screen still exposes the same sample destinations. Existing generated artwork is reused; no additional image generation or new app features are introduced.

## More integrated banners D/E/F

Open `more-banners.html` for three additional B-based directions. Identity is integrated into the full-width top banner, not a card. Gold membership modules show current monthly plan/status with a Manage action. The Sample membership selector switches all three through trial, active, and free specimens. Existing sections and generated artwork are reused. References and restrictions are in `../references.md`.

## Theme and text-size validation

Open `validation.html` for 15 selected screen specimens, side-by-side light and proposed dark versions. Text can be increased to 130% as a browser stress check. This approximates larger text; it is not native Dynamic Type or an accessibility certification. No production SwiftUI theme changes are included.

`validation.js` applies theme/text modifiers only when explicit preview query parameters are present. `validation.css` contains the preview adaptations. Standard light-mode targets remain unchanged outside validation mode. Larger text wraps session metadata and allows variable heights; flashcard rating buttons use two rows to remain readable. Native navigation, actual Dynamic Type categories, touch targets, VoiceOver, final artwork, and all auth/payment states still require a pilot.
