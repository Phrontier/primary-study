# Redesign decisions

## Home · Round 01 feedback

**Status:** Preferred direction selected; activity treatment unresolved.

- Use A as the foundation: its greeting and seamless activity area, highlighted last-studied item, and supporting recent items as open subsections.
- Preserve A's question-of-the-day card treatment.
- Borrow B's green surface for the entire EPs / Limits / N/W/C shortcut. It should read as an important tappable destination, not a floating heading.
- C and D contain possibilities worth keeping for reference, but A is the preferred starting point.
- Replace the small streak pill. It feels underemphasized and leaves excessive space around it.
- Explore a larger, expressive flame or a theme-appropriate visual for the streak. No final asset is selected.
- Preserve clear daily activity information to the right. All prior activity treatments remain unapproved.
- Explore a user-set flashcard goal with a progress ring; a no-goal state could use a solid ring or plain count. Goal setting and the daily metric are not committed runtime features.

Round 02 isolates three activity treatments on the preferred composition. A flame emoji stands in for possible future raster artwork; no image generation or mascot development is included. The initial Home feedback preceded formal design-language documentation.

## Home · Round 02 feedback

**Status:** A1 selected as the working Home direction.

- Keep the larger flame with a plain daily count. Defer daily goals and goal rings to a future iteration.
- Give the streak and daily count matching numeric type sizes, weights, and label hierarchy.
- Tighten the vertical composition between greeting, activity, and continue studying; avoid an oversized empty activity band.
- Preserve A's recent-content hierarchy and question card plus B's green reference shortcut.
- Flame artwork and the daily activity metric remain provisional. Selection does not authorize production tracking or feature changes.

A1 metric alignment refinement: both numbers occupy the same fixed-height row and baseline. Labels begin below that row; wrapping the daily activity label must not shift its number upward.

## Home foundation approved

The user approved refined A1 as the starting design language. Reusable rules and exact study tokens are recorded in `design-language.md`. Continue with static Events root, Contacts Sims event list, and Instructors root studies. These companion layouts require review before adoption; production code remains outside this stage.

## Companion exploration clarification

The user requested three options for each companion screen, not a single application per screen. Preserve the original layouts as A. B explores white grouped surfaces; C explores phase tiles, an event-identifier rail, and a compact instructor roster. All retain approved Home typography, palette, navigation, and selective container use. These are competing proposals, not additional approved design-language rules.

## Companion selections and instructor refinement

- Events A and Contacts Sims A are user-approved as the intended layouts.
- Instructors A is the preferred roster layout. Adopt C's full-width segmented All / Sims / Flights control.
- Submit Review must be visibly highlighted; round 04 proposes a full-width blue action below the roster heading.
- Chill factor and grading style need meaningful color. Round 04 proposes colored numbers plus a seven-segment indicator and existing descriptive scale labels; this treatment awaits review.
- Correct the exploratory instructor denominator: the app stores 1–7 and displays normalized values out of 10. Previous mockups used /5 incorrectly. Refined studies now use the existing conversion, rounded raw-score color band, and descriptive labels. Scores remain fictional sample data.

## Instructor color · Round 05 feedback

B (colored numbers/labels only) and C (tinted badges) are rejected. A's colored numbers and scale are closer to the desired direction, but not approved. Replace B/C in the active comparison with D (continuous spectrum plus position marker) and E (compact color arc around the score). Preserve the instructor layout, segmented control, and review action. Both new treatments remain exploratory.

## Instructor color selected

The user selected rating color option A for now: colored numbers, a small segmented scale, and descriptive labels. Combine it with instructor layout A, C's segmented All / Sims / Flights control, and the highlighted Submit Review action. D/E are unselected exploration references; B/C remain rejected. This is the working direction, not a requirement to keep exploring ratings.

## Detail-screen selections

- Event Detail C is selected: open overview with a colored vertical rule, compact FAM2101 identifier pill above the title, open study-tool rows, and an amber briefing-guide destination.
- The identifier pill is an approved extension of the language: it identifies the event rather than displaying an inventory metric. Keep it compact and subordinate to the title; do not turn every heading or counter into a pill.
- Instructor Detail A is selected. Every individual review must retain its own chill factor and grading style scores, distinct from the overall averages. The study now includes fictional review-level scores using the existing rating mapping.
- Discussion Reading C is selected. Remove the redundant separator between the page introduction and first reading section; retain one divider and the colored heading rule.
- These selections are visual direction only. Production changes remain outside the current static-study stage.

## Instructor detail reconsidered after individual grades

The user now prefers a hybrid of A/B: individual reviews warrant separate cards, while the overall At a glance summary needs more emphasis. Preserve A's open identity and B's separate review cards. Round 07 compares an open summary with a blue heading rule, a soft-blue summary surface, and a white summary with a blue edge. The user is leaning toward B, but the summary treatment is not yet selected. This supersedes the earlier open-review-section preference for instructor detail only.

## Instructor summary and discussion disclosure selected

- Select round 07 instructor summary A: open overall score pair with a blue heading accent, open identity, and separate white cards for individual reviews. This supersedes earlier tentative preferences for B's summary surface.
- Discussion Reading C retains its approved typography and teal heading rules. Make each discussion section independently collapsible, defaulting all sections open. Use a small chevron beside the heading; tapping the heading toggles only that section. Preserve complete text and nested lists when expanded.
- The static study uses native HTML details/summary to demonstrate disclosure. Future native implementation should expose expanded/collapsed state to accessibility, support long headings, and retain all-open defaults when entering the reading screen. No saved collapse preference or collapse-all feature is added.

## Screen designs locked

The user approved locking the selected root and detail screens, including Discussion C's independently collapsible sections with all-open defaults. The authoritative selection table is in `design-language.md`. Previous A/B/C/D/E variants are reference history only. Final selected instructor detail is round 07 A (open summary plus individual review cards), not the original all-open review layout. Continue from these selections without repeating exploration unless requested or a concrete implementation constraint requires adjustment. This approval locks visual direction; it does not request native implementation.

## Flashcard refinement selections

- Deck overview: keep C's introduction and action group through All cards. Below that heading, use one separate white card per flashcard, inspired by B's surface treatment; do not enclose the entire list in one card.
- Question and answer: use C's physical-card treatment. Remove the separator between Discussion Items and the progress bar; retain the progress bar itself.
- Remove the blue vertical rule beside How well did you know it.
- Arrange Missed / Hard / Good / Easy in one row, inspired by B, with tighter gaps between buttons. Retain the established rating colors.
- Round 09 shows the combined refinements; round 08 retains original alternatives. This is static-study direction, not production implementation.

## Flashcard screens locked

The user approved the round 09 combined deck, question, and answer designs. These join the seven previously locked screens as the current light-mode visual targets. No further flashcard exploration is required unless the user requests changes or native validation reveals a concrete issue.

## Account, More/settings, and subscription exploration

Before dark mode and larger text, review round 10's A/B/C options for onboarding, More/settings, and subscription. Each area has a stage selector so corresponding screens can be compared across the flow. References are annotated in `references.md`. Current account requirements and monthly-only product are preserved. No direction is locked yet; prototype navigation does not authorize auth, subscription, or production changes.

## Premium reference fidelity correction

The user wants nearly the exact Buddy trial layout, not a loose timeline adaptation. Use a bold colored header, overlapping white timeline card with a continuous icon rail, centered offer, and prominent rounded Continue action. Adapt branding to Primary Gouge's blue palette. User confirms Apple setup supports the trial → notification → Premium sequence; treat Day 5 reminder as a required part of the intended flow.

Local source images in `Mobbin/` were visually inspected, including Buddy trial/plan sheet and the Copilot/Blinkist trial examples. These images do not establish user-test results for Primary Gouge. Pricing, trial eligibility, and actual reminder delivery still need runtime verification during native implementation. Repository inspection found daily study notification support but no trial-ending reminder scheduling in the inspected subscription/notification services. Resolve that delivery path before shipping reminder promises. Only the existing monthly product is represented; no annual or lifetime plan is added.

`previews/premium.html` is the focused reference-faithful study. It includes local reminder-permission, Apple-handoff, and success/cancellation specimens; it performs no real action. Onboarding/More choices remain open and their local reference images remain available for targeted refinement.

## Premium variations requested

Keep the reference-faithful trial structure and change the badge to “Secured by Apple.” Compare A (reference with restrained aviation detail), B (light-blue illustrated flight path), and C (blue/teal header and ticket-inspired timeline). Artwork is code-native SVG for cheap precise iteration; no raster generation is needed. All retain Today / Day 5 / Day 7, offer placement, close access, and prominent Continue. No new direction is locked yet.

## Premium palette/composition preference

The user prefers A's blue color scheme and C's spacing and imagery. `premium-selected.html` combines them: C's illustration, overlap, timeline spacing, ticket edge, and action layout with A's blue header/rail and neutral text/badge treatment. Preserve Secured by Apple. The combined study awaits confirmation before locking Premium.

## Premium design locked

The user approved the A-color/C-composition hybrid, with two final refinements: remove ticket-edge circles and the dotted seam under the timeline card; render the rail as a rounded blue foreground bar within a longer softly fading track, avoiding the abrupt horizontal color cut. `premium-selected.html` is the locked Premium visual target. Trial reminder delivery, localized pricing, eligibility, and native permission/payment states remain implementation verification items. Onboarding and More/settings remain unselected; continue with them before dark mode and larger text.

## Onboarding reference fidelity correction

The user rejected generic HTML onboarding layouts and requested stronger fidelity to supplied Mobbin flows, with image generation where helpful. Scope is welcome, account creation, and training setup only; do not regenerate every auth/onboarding state before choosing a visual direction. `onboarding.html` compares Fable-inspired product imagery, Jomo-inspired generated aviation/study illustration, and Uptime-inspired colorful content collage. The locked app typography/palette and existing Apple/email requirements are retained. These concepts are not approved yet.

## Onboarding A locked

The user selected A for welcome, account creation, and training setup. Preserve its Fable-inspired product-preview composition and understated open form fields. Highlight the Not Sure Yet path in training setup with a soft-blue explanatory surface and a clear heading, rather than small footnote text. Preserve the existing Not Sure Yet squadron choice, Echo default, and ability to update the profile later. Extend this selected language to remaining auth states during native implementation; do not generate all remaining screens during this exploration.

Onboarding callout copy refined: “Not sure yet? Start with Echo.” Supporting line: “You can always update it in Profile settings later.” Keep it compact; do not expand into a long explanatory block.

## More/settings B refinements

The user prefers B's grouped section structure and existing contents but wants more character, especially Premium emphasis. `more-options.html` compares warm gold, an illustrated profile, and blue/gold. All preserve B's white grouped sections and identical destinations. Premium uses a restrained gold surface; illustration variants reuse the generated onboarding artwork for low-cost exploration. None of these refinements is selected yet.

## More banner refinements D/E/F

The user prefers illustrated refinement B, but wants the student identity integrated into a page-top banner rather than an isolated profile card. Premium should communicate membership/plan status and a Manage action, combining Brainly's gold tint and Jomo's plan module. `more-banners.html` compares D (blue integrated banner), E (airy illustrated header plus overlapping gold membership), and F (more expressive aviation header and gold membership). All preserve B's grouped settings contents. Sample membership selector compares monthly-trial, active, and free states. No option is locked yet.

## More/settings direction locked

The user chose “A” after viewing the latest three-option banner comparison. Interpret this as the first/latest option, labeled D: integrated blue page-top banner with student identity and aviation artwork, restrained gold monthly membership/status module with Manage, and B's grouped white settings sections. This is not the older open-row A. E/F remain unselected. Preserve sample-state distinctions in the study; native status must use real entitlement data.

## Dark mode and larger-text first pass

The user authorized validation of selected screens. `previews/validation.html` compares 15 selected specimens in light/proposed dark at standard/130% text, totaling 60 width checks. No horizontal overflow was found. Dark surfaces, semantic text contrast, separators, and primary action treatment were refined. Larger text retains aligned Home numbers, wraps session metadata, expands content vertically, and uses a two-row flashcard rating layout. Discussion disclosure and sample onboarding navigation were exercised; theme/text settings persist after sample navigation. Dark/large equivalents await user review; no production changes or native accessibility certification are implied.

## Dark-mode user corrections

- General Library title uses white in dark mode instead of green.
- Instructor numerical scores and descriptors use explicit brighter semantic colors instead of automatic color blending: rose/red, orange, amber, pale gold for neutral, and distinct greens for the higher bands. Preserve the existing raw-score mapping.
- More's Manage action retains a light-gold surface with dark-gold text in dark mode.

These corrections are applied to the validation studies and checked in the browser.

## Dark-mode and larger-text studies approved

The user approved the reviewed validation gallery after the General Library, instructor rating, and Manage-button corrections. Lock these dark-mode visual equivalents and browser larger-text adaptations as the direction for the native pilot. This approval does not certify native Dynamic Type, VoiceOver, all accessibility sizes, runtime states, or payment/reminder behavior. Those remain native verification tasks.


## Native pilot authorized — October 14, 2026

After approval of dark-mode preview corrections, the user authorized the connected SwiftUI pilot: Home → event browsing → event detail → discussion items / flashcards. Implement the locked choices in this slice, preserve live navigation/access and study behavior, and verify native scaling before the wider rollout. See [native pilot](native-pilot.md) for implementation scope, the temporary distinct-card daily metric definition, and verification evidence. The final daily metric, daily goals, and final flame artwork remain deferred.


## Home fidelity correction — October 14, 2026

The user rejected the pilot's approximation of the selected screenshots and authorized a measured fidelity pass, starting with Home only. A1's small in-content Home label, greeting period, metric separator, typography, row hierarchy, colors, spacing, and compact reference treatment are implementation requirements. Native changes and comparison evidence are recorded in [Home fidelity review](home-fidelity.md). Pause for visual review before refining the other pilot screens; functional test success does not constitute visual approval.


## Home fidelity approved; remaining pilot authorized — October 15, 2026

The user approved the matched Home refinement (“Excellent that's much better for what I wanted”) and authorized applying the same measured translation to the remaining pilot. Preserve that Home implementation. Refine Events/phase/category browsing, event detail, discussion reading, deck overview, and flashcard question/answer against their locked previews. Instructor, onboarding, More, and subscription remain outside this pass.


## Connected pilot fidelity pass — October 15, 2026

Following Home approval, the user authorized applying the same measured approach to event browsing, event detail, discussion reading, and flashcards. These native screens now use the selected preview's typography roles, compact in-content headers, open rows and separators, semantic accents, and layered physical cards. [Specifications, comparisons, and verification](pilot-fidelity.md) record the implementation. Light, dark, largest-text, interactive-back, rating, and access checks passed. These screens await visual feedback; Home remains approved. Other native screen families remain outside this pass.


## Connected pilot approved; remaining selections authorized — October 15, 2026

The user approved all connected pilot comparisons (“They all look good”) and requested work on the remaining screens. Implement the locked instructor root/detail, onboarding A, More's integrated banner and grouped settings, and selected Premium hybrid using the same measured translation. Preserve the approved Home/event/study flow. [Remaining native rollout](remaining-native.md) records the implementation and verification; the new native screens await their own visual review.


## Remaining selected screens implemented — October 15, 2026

Instructor browsing/detail, onboarding A and related auth forms, the integrated More banner/grouped settings, and the selected Premium hybrid now have native implementations. The [comparison gallery](previews/remaining-fidelity.html) and [implementation/verification notes](remaining-native.md) record measured translation, real-data differences, accessibility adaptations, and the unresolved simulator StoreKit verification limitation. Normal/light, dark and largest-text UI flows passed; these new native screens are ready for user visual review, not yet visually approved. The previously approved Home/event/study screens remain the benchmark.


## October 19 — app-wide reusable system

The approved plan extends the selected visual language to every app-owned screen and makes it the default for future development. Existing native Home/event/study approvals stand. The remaining selected native gallery still needs the user's final visual approval. New screens reuse established recipes; genuinely new compositions require targeted review, not three automatic alternatives.

The previous cumulative language document mixed exploratory and current instructions. It is retained below as historical evidence only. The current design-language.md and linked fidelity specifications take precedence. In particular, earlier pending dark/text notes were superseded by validation approval; tentative instructor-detail alternatives were superseded by round 07 A; “pilot only” restrictions were superseded by the app-wide rollout authorization.

<details>
<summary>Historical cumulative design-language v1 (superseded wording)</summary>

# Primary Gouge — Design language

**Status:** Design language — v1; selected light-mode screens locked  
**Approved foundation:** Home A1 and selected root/detail studies, approved October 14, 2026.  
**Scope:** Approved visual studies at 393 × 852, including subsequent dark/text preview validation. The connected SwiftUI pilot is documented in [native-pilot.md](native-pilot.md); remaining selected screen families are now undergoing native rollout; see [remaining-native.md](remaining-native.md).

Use this document with [the product brief](product-brief.md), [references](references.md), and [decision history](decisions.md). The approved visual target is [Home A1](previews/index.html?round=2&option=r1), with its [saved screenshot](previews/screenshots/a1-selected.jpg). The HTML/CSS study is the current visual reference; production SwiftUI theme values must not silently override it.

## Locked screen selections

The user has approved the selections below. Follow these references for future work; earlier alternatives and exploratory notes are history, not competing instructions. Reopen a choice only when the user requests a change or a concrete native implementation issue requires a documented adjustment.

| Screen | Locked direction | Preview |
| --- | --- | --- |
| Home | Refined A1; equal numbers and aligned baselines, compact activity spacing, green reference tile | [Home A1](previews/index.html?round=2&option=r1) |
| Events root | A; open phase rows and highlighted library access | [Events A](previews/index.html?round=4&option=events) |
| Category event list | A; open event identifiers, titles, and summaries | [Sims A](previews/index.html?round=4&option=list) |
| Instructors root | A layout, C segmented control, highlighted Submit Review, rating color A | [Instructors](previews/index.html?round=4&option=instructors) |
| Event detail | C; identifier pill, blue overview rule, open tools, amber briefing guide | [Event Detail C](previews/index.html?round=6&option=eventdetail-c) |
| Instructor detail | Round 07 A; open identity/summary with blue heading rule, separate white review cards and individual grades | [Instructor Detail A](previews/index.html?round=7&option=instructordetail-a) |
| Discussion reading | C; single separators, teal heading rules, independently collapsible sections defaulting open | [Discussion C](previews/index.html?round=6&option=discussion-c) |

The following flashcard screens are also locked:

| Screen | Locked direction | Preview |
| --- | --- | --- |
| Deck overview | C introduction/actions, individual white flashcard-preview cards | [Deck](previews/index.html?round=9&option=flash-deck-c) |
| Question side | C physical card, colored top edge, no extra header divider | [Question](previews/index.html?round=9&option=flash-question-c) |
| Answer side | C answer card, plain rating heading, four equal-width rating buttons with 4px gaps | [Answer](previews/index.html?round=9&option=flash-answer-c) |

These locks cover the selected light-mode layouts and demonstrated disclosure behavior. Native implementation is now authorized within the connected pilot scope. Sample data, final flame artwork, a permanent daily metric definition, and screen types not yet reviewed remain unapproved; subsequent dark/text approvals are recorded in the decision and validation notes. Daily goals and mascots remain deferred.

## What the user approved and why

| Approved choice | Design term | Intent |
| --- | --- | --- |
| Greeting flows into streak and daily activity | Open composition | Welcome and activity belong to the page, without a surrounding hero card. |
| Last-studied item is highlighted | Visual hierarchy / primary surface | One prominent destination makes resuming obvious. |
| Other recent items are rows, not separate cards | Progressive emphasis / list rhythm | Supporting destinations remain easy to scan without competing with the primary item. |
| Question of the day has its own white card | Functional grouping | The question and answers form one bounded interaction. |
| Entire reference shortcut has a green surface | Semantic surface / action affordance | Important recurring reference access reads as a tappable destination. |
| Larger flame beside the streak | Expressive accent | A focused visual adds warmth without filling every section with decoration. |
| Streak and daily count use matching type | Parallel metric hierarchy | Both measures have equal visual importance. |
| Wrapped labels do not move their numbers | Baseline alignment / independent label flow | Numbers stay aligned even when one caption occupies two lines. |
| Reduced gaps around activity | Vertical rhythm | The welcome feels connected to the next action rather than separated by empty space. |

A1 is the foundation, not a requirement to repeat Home's layout on every screen. Open lists, reading content, metrics, and flashcards need layouts suited to their purpose.

## Composition and containers

- Use a light cool page background, dark blue-gray text, and aligned open sections.
- Establish one clear primary destination where the task calls for it. Do not highlight an arbitrary first list item just because Home highlights its last-studied item.
- Default supporting destinations to open rows with a leading icon, clear title, restrained metadata, and trailing disclosure arrow. Use subtle separators between related rows.
- Use cards to group a discrete interaction or intentionally emphasize a destination. Flashcards retain physical-card behavior; the daily question retains its bounded question-and-answer surface.
- Avoid card-inside-card structures for ordinary metadata and metrics. Do not wrap a whole page introduction, filter group, or instructor score pair in a decorative container by default.
- Colored icon tiles can distinguish destination types without coloring the entire row.
- Preserve meaningful domain colors and rating colors; the Home blue and green do not replace every existing semantic color.
- Keep page titles clear and avoid repeating the same title inside an oversized hero card.
- Metrics must have a useful interpretation. Omit or demote inventory counters that do not help users choose an action. Do not add due counts without explaining what is due.

## Light-mode reference tokens

Values below reproduce the approved browser study. They are a starting visual specification, not an instruction to change native theme code before a pilot is approved.

| Role | Value |
| --- | --- |
| Page background | `#F5F7FB` |
| Primary text | `#18263B` |
| Secondary text | `#637086` |
| Navigation / primary action blue | `#2867DA` |
| Primary surface | Gradient `#E0EBFF` → `#EDF2FF`, 125 degrees |
| Primary surface border | `#D3E1FC`, 1px |
| Question surface | `#FFFFFF` |
| Question surface border | `#E4E9F1`, 1px |
| Row separator | `#E0E6EE`, 1px |
| Blue icon tile | `#E1EDF9` |
| Reference surface | `#E2F1E9` |
| Reference border | `#CFE5DA`, 1px |
| Reference icon tile | `#CAE6D7` |
| Reference heading | `#235B43` |
| Reference caption | `#4D7360` |
| Reference icon / arrow | `#23734F` |
| Streak caption | `#8D601B` |

Use the subtle primary-surface gradient only where appropriate for emphasis. Avoid gradients, glows, and shadows on every row. The preview phone frame's shadow is presentation chrome, not an app component style.

## Typography and spacing

Use the platform system sans-serif family, matching the native iOS feel. Emphasis comes from role, weight, spacing, and contrast rather than introducing many fonts.

| Role | Browser study specification |
| --- | --- |
| Greeting / root title | 30px, bold, -1px letter spacing |
| Activity numbers | 34px, weight 700, 38px line box, -1px letter spacing |
| Activity labels | 12px, line-height 1.4, 5px below number row |
| Section title | 17px, weight 700, -0.3px letter spacing |
| Highlighted destination title | 23px, bold, -0.65px letter spacing |
| Supporting row title | 16px, bold, line-height 1.35 |
| Event identifier | 11px, weight 700, 1.1px letter spacing |
| Metadata | 11–12px, secondary color, line-height 1.5 |
| Daily question | 19px, weight 650, line-height 1.4 |
| Primary action | 14px, weight 650 |

- Screen horizontal inset: 22px. Typical section gap: 26–30px; use 18px between the Home activity band and Continue studying.
- Greeting bottom margin: 12px. Home activity band: 92px high; metric groups: 72px high.
- Both Home numbers share a 38px row and baseline. Captions start below it and wrap independently. Never vertically center each number-plus-caption block as a unit.
- Supporting row padding: 18px vertically; title/metadata remain aligned on one shared text column.
- Primary card padding: 22px; question padding: 20px.
- Main card radius: 24px; green reference radius: 20px; action and icon tile radius: 13px.
- Icon tile: 42 × 42px; standard inline icons: approximately 23px, consistent 1.8px stroke.
- Use these fixed measurements for the comparison studies. Native Dynamic Type must allow flexible heights and wrapping rather than clipping content to preview dimensions.

## Navigation and interactive cues

Preserve Home, Events, Instructors, More, and Search. Use a blue selected state, consistent icon weight, and visible labels. Reserve bottom space so the last destination scrolls fully above the floating navigation.

Primary actions use solid blue, white text, and a clear label. Supporting destinations use a trailing arrow. A green shortcut uses a whole colored surface to communicate emphasis, not just a green title floating on the page.

Study controls are static. Production tap targets, VoiceOver labels, contrast, safe areas, and behavior require verification during the native pilot.

## Boundaries and further validation

- The ten screens in the locked selection table are user-approved. New screen patterns still require review.
- Daily counts, streak values, and history are sample data. Selection of a daily metric and its tracking are unresolved product decisions.
- Daily goals and progress rings are deferred. Do not implement them as part of this direction.
- The flame emoji is temporary artwork. Final raster art may be explored later; no mascot is included now.
- Keep Alan as one composition reference, not a whole-app template. Retain C and D for possible future inspiration.
- Dark mode, reference reading, event detail, instructor detail, flashcards, empty/loading/error states, and larger text still need validation before calling the system complete.

## Replication checklist

1. Read the brief and this document, then inspect the approved A1 image and HTML/CSS.
2. Identify the screen's primary user task and choose its hierarchy before selecting containers.
3. Start with open sections and rows. Add a surface only when it groups an interaction or earns emphasis.
4. Apply role-based type, semantic color, shared alignment, and deliberate spacing.
5. Check long labels, parallel metric baselines, vertical scrolling, and bottom navigation clearance.
6. Compare the result visually with A1. Record intentional differences and seek feedback on new screen patterns before expanding them across the app.

## Approved companion patterns

Events A and Contacts Sims A are approved. Preserve their open rows, clear titles/identifiers, summaries, separators, colored destination icons, and existing bottom navigation. Do not replace them with grouped panels or phase grids.

Instructors A is the preferred structure, with C's segmented All / Sims / Flights control. Submit Review needs a clearly emphasized action. Ratings require semantic color; rating color option A is now selected: colored numbers, a small segmented scale, and descriptive labels. Follow the existing native seven-point rating model, normalized out-of-ten display, rounded-score color mapping, and descriptive labels. Color describes temperament or grading style, not an overall judgment of teaching quality; retain text and numeric information.

### Selected instructor rating treatment

Use [the selected instructor study](previews/index.html?round=4&screen=instructors) as the visual target. Keep rating category labels neutral; apply semantic color to the number and descriptive label. Show seven small segments below each category label: fill through the rounded raw-score band using the existing red-to-green scale and leave remaining segments neutral. This is a rating visualization, not task progress.

Preserve the native model: store scores 1–7, normalize averages to a one-decimal out-of-ten display, and choose color/descriptor from the rounded raw average. Do not reinterpret the model as a five-point scale or assign colors from the displayed value directly. Use darker text equivalents for legibility and retain category names, numbers, denominators, and descriptive labels.

Keep each paired score aligned and use open grouping with one subtle divider. Do not add tinted score badges, continuous gradients, or arc gauges. The full-width blue Submit Review action and segmented All / Sims / Flights control are part of this selected instructor composition.

## Selected detail and reading patterns

### Event Detail C

Use an open overview with a blue vertical rule rather than a enclosing card. Study tools remain open rows with colored icon tiles. Give the briefing-guide destination an amber surface because it is important recurring preparation material.

A compact soft-blue event-code pill above the main title is approved. This is an identity cue, distinct from the inventory-count pills removed elsewhere. Its type stays small and its surface quiet; the event title remains dominant. The pill is optional for identifiers, not a universal heading treatment.

### Instructor Detail A

Use open instructor identity, an aligned pair of overall scores, and open review sections with subtle separators. Each review includes event/date context, its own labeled chill factor and grading style scores, review text, and report access. Overall scores summarize the instructor; review scores describe that individual submission. Preserve the selected rating color A and the existing seven-point model/out-of-ten display for both. Do not omit individual grades or invent them for actual reviews.

### Discussion Reading C

Use open reading sections with compact hierarchy, teal vertical heading rules, muted body text, colored bullets, and clear nested indentation. Preserve complete source text and nesting. Use one separator between the page introduction and the first section; do not stack a header-bottom rule and a first-section-top rule. Later sections may use one divider each.

### Instructor detail refinement in progress

After seeing individual grades, the user prefers separate review cards. Each review is a discrete submission containing its own grades and text, so one white card per review is a purposeful grouping. Keep its score pairs open inside the card; avoid nested score cards. Preserve the open instructor identity. The At a glance emphasis is under comparison in round 07; the earlier all-open instructor detail arrangement is no longer the final target.

### Final instructor detail selection

Round 07 A is selected: an open At a glance score pair with a blue vertical heading accent; open instructor identity; separate white review cards containing individual grade pairs, text, and report access. This supersedes the tentative summary variants discussed above.

### Discussion section disclosure

Each discussion section is independently collapsible and starts expanded. Retain Discussion C's teal heading rule and single separators. Add a small neutral chevron aligned with the heading, pointing down when expanded and right when collapsed. Make the whole heading row the toggle target, not just the icon. Collapsing hides the section body only; its title stays visible. Preserve full source content and nested structure. Provide keyboard and screen-reader expanded-state semantics, allow long titles to wrap, and avoid nested card containers. No collapse-all action or persisted collapse state is part of the current direction.

## Selected flashcard direction

Round 09 is user-approved and locked as the flashcard reference. The deck retains C's compact event identifier and open action group with a blue vertical accent. All cards is an open section heading followed by individual white flashcard-preview cards, each containing state, prompt, and answer excerpt. Do not wrap the entire list in a single enclosing card.

Study question and answer faces use C's white physical-card surface, subtle stack underneath, and a colored top edge (purple prompt, green answer). Keep the compact deck header and progress bar; omit any extra separator between them. Preserve complete answers without clipping and make rating controls reachable by vertical scrolling for long content.

How well did you know it is an ordinary section heading without a vertical accent. Missed / Hard / Good / Easy sit in one equal-width row with 4px gaps and established semantic colors. Use clear labels and at least 44px control height in the study; larger text and native touch targets need later validation. No grading behavior or scheduler changes are authorized by these previews.

## Locked Premium direction

Use [the selected Premium preview](previews/premium-selected.html): A's blue palette with C's spacing and aviation illustration. Preserve the bold header, overlapping white trial timeline, Today / Day 5 reminder / Day 7 billing sequence, centered offer, Secured by Apple badge, prominent Continue action, and clear dismissal.

Remove ticket-edge circles and the dotted seam beneath the timeline card. The timeline uses a rounded blue foreground rail within a longer background track fading softly toward green/white; do not use an abrupt horizontal cutoff between colors.

This additional locked surface does not change the established app-wide palette. Actual pricing/eligibility come from StoreKit. The user confirms the trial/reminder sequence as a requirement; native reminder delivery must be verified before shipping the promise. Native Apple purchase and permission interfaces are handoffs, not custom replacements. No annual or lifetime plan, store ratings, or discounts are implied by the reference.

## Locked onboarding direction

Use A across the main onboarding screens in [the onboarding study](previews/onboarding.html): Fable-inspired layered product preview on welcome, system typography, clear Apple/email actions, open understated account fields, and the same form language for training setup. The generated illustration and content collage alternatives are unselected.

Training setup must make the Not Sure Yet option reassuring and easy to discover. Use a soft-blue explanatory surface with a clear heading and readable supporting copy: choose Not Sure Yet for squadron, start with Echo, and update setup in Profile later. Preserve native defaults and account requirements. Verification, sign-in, recovery, and errors will extend this language during implementation; preview omission does not remove those flows.

The selected training-setup callout uses concise copy: **Not sure yet? Start with Echo.** followed by **You can always update it in Profile settings later.** Keep the soft-blue treatment compact.

## Locked More/settings direction

Use the first option (D, selected by the user as A) in [the integrated banner study](previews/more-banners.html?area=more&variants=banner). Preserve the full-width blue header integrated into the page, open student identity with avatar and aviation artwork, a restrained gold membership module showing current plan/status and Manage, and B's white grouped settings sections. The profile header is not a separate card.

Keep existing settings destinations and their order. Membership status must reflect the actual free/trial/active entitlement; the monthly plan is not an annual plan. Do not import reference-app points, messages, trial dates, or other unsupported features. The illustrated header reuses the exploratory aviation asset; final art may be refined without changing the selected structure.

## Proposed dark and larger-text equivalents

The [validation gallery](previews/validation.html) and [validation notes](validation-notes.md) extend the locked light-mode designs for review. Dark proposals retain colored identity and semantic status, using darker blue/green/gold surfaces with brighter text and subdued separators. At the browser's 130% text stress size, parallel numbers remain aligned, sections expand, metadata wraps, and the four flashcard rating controls use two rows for readability. These equivalents are not locked until reviewed. Native Dynamic Type and accessibility must be validated in SwiftUI.

### Dark-mode feedback refinements

General Library uses white title text in dark mode. Instructor rating numbers require explicit bright semantic foregrounds, not automatically blended muted colors; preserve the scale mapping while making each color band readable. More's Manage button remains light gold (`#F3DFAD`) with dark-gold text (`#62451C`), rather than a dark/black surface.

## Theme and text validation approval

The user approved the light/dark validation gallery and larger-text adaptations after the documented color corrections. These studies are now the selected visual targets for the SwiftUI pilot, superseding earlier “awaiting review” notes for those equivalents. Preserve the standard locked layouts and use flexible wrapping/heights and a two-row rating control when enlarged text requires it. Native Dynamic Type, VoiceOver, safe areas, contrast, and real state behavior still require device/simulator verification.


## Native fidelity specification — Home approved

The Home-only translation now uses explicit scaled roles measured from A1; see [Home fidelity review](home-fidelity.md). Preserve the 30pt greeting with -1pt tracking, 34pt metric numbers in equal 38pt rows, 17pt section titles, 23pt featured title, 16pt recent titles, 11pt code/row metadata, 19pt daily question, 13pt choices, and 14pt primary action. Home's green shortcut has a compact 14pt heading and 11pt caption, overriding the generic section-heading role. Keep the small left-aligned Home label, blue greeting period, and vertical metric divider. Do not replace these measurements with default SwiftUI semantic sizes. Scale roles for Dynamic Type and allow larger content to expand. The user approved Home and the subsequent connected pilot fidelity pass on October 15, 2026.


## Native fidelity specification — October 15, 2026

Selected previews define spacing, hierarchy, line placement, and surface treatments as well as component presence. Use [Home fidelity](home-fidelity.md) for the approved Home implementation and [connected pilot fidelity](pilot-fidelity.md) for measured roles on Events, event lists/details, discussion reading, and flashcards. Avoid substituting generic SwiftUI title/body roles or one shared section gap. Scale the measured roles with Dynamic Type; accessibility layouts may stack and expand. System navigation behavior and safe scrolling clearance remain requirements.


## Remaining native translation — October 15, 2026

The connected event/study pilot is now visually approved. The user authorized implementing the remaining locked selections: instructor root/detail, onboarding A and related auth states, integrated More banner/grouped settings, and the selected Premium hybrid. [Native specification and verification](remaining-native.md) records this pass; those new native screens await their own visual review. Preserve the approved Home/event/study implementation. Native control sizing, real account/catalog data, and required validation text may differ from static samples; record those differences rather than removing behavior to force a screenshot match.

</details>


## October 19 — rollout implementation and validation

App-wide utility screens now extend the locked recipes. Open intros/rows replace legacy nested surfaces; reading/form typography uses measured scaled roles; quiz text grows and scrolls; quiz/practice choice groups no longer have outer cards. Ground-school inventory metrics were removed. My Reviews uses selected score pairs. Debug patterns and repository UI guidance support future development.

Implementation evidence and exact verification boundaries are in [rollout-validation.md](rollout-validation.md), with route/state status in [screen-audit.md](screen-audit.md). Native visual approval is still pending for the remaining families and this extension. Deferred product features and live release gates remain outside this design pass.

## October 22, 2026 — Official design approval

The user approved all native gallery screens, requested preservation of other branch work, and authorized promotion to main and a TestFlight upload for physical-phone testing. The selected native style is now the official app design. Previous branches remain intact; release evidence is recorded separately.
