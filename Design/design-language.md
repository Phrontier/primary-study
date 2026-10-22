# Primary Gouge — Design language

**Approved specification — v2. App-wide default.** Approved October 22, 2026.

This is the source of truth for visual and interaction design, alongside the [product brief](product-brief.md). The selected previews define composition and fine details. Native code must reproduce those details while supporting real data, Dynamic Type, safe areas, and native behavior. Decision history is in [decisions.md](decisions.md); implementation coverage is in [screen-audit.md](screen-audit.md).

## Reference hierarchy and approval

1. Product intent and confirmed requirements in the brief.
2. Locked references and measured fidelity specifications below.
3. Reusable native recipes and semantic tokens.
4. Documented native adaptations for accessibility, real data, and system interfaces.

The user approved all native gallery screens and the app-wide extension on October 22, 2026. This is the official app design. Visual approval does not replace remaining physical-device or external-service release checks. Earlier alternatives and pending notes preserved in decisions.md do not override this approval or the selected references.

| Family | Selected reference | Measured native specification |
| --- | --- | --- |
| Home | [A1](previews/index.html?round=2&option=r1) | [Home fidelity](home-fidelity.md) |
| Events / category list | [Events A](previews/index.html?round=4&option=events), [Sims A](previews/index.html?round=4&option=list) | [Connected fidelity](pilot-fidelity.md) |
| Event detail / discussion | [Event C](previews/index.html?round=6&option=eventdetail-c), [Discussion C](previews/index.html?round=6&option=discussion-c) | Connected fidelity |
| Deck / question / answer | [Round 09](previews/index.html?round=9) | Connected fidelity |
| Instructors | [Root A](previews/index.html?round=4&option=instructors), [detail round 07 A](previews/index.html?round=7&option=instructordetail-a) | [Remaining native](remaining-native.md) |
| Account / onboarding | [Onboarding A](previews/onboarding.html) | Remaining native |
| More / settings | [First integrated banner, user selection A](previews/more-banners.html?area=more&variants=banner) | Remaining native |
| Premium | [Selected A palette / C composition](previews/premium-selected.html) | Remaining native |
| Dark / enlarged text | [Approved validation](previews/validation.html) | [Validation notes](validation-notes.md), native galleries |

## Design principles

- Preserve Events → phase → category → event, with contextual shortcuts where already supported. The app prioritizes quick reference, preparation, and instructor information; flashcards support that experience.
- Start with an open page and clear alignment. A container must group an interaction, represent an independent submission, or emphasize a useful destination.
- Keep the Home recent-material hierarchy: one highlighted last destination, then open supporting rows. Do not highlight an arbitrary first row elsewhere.
- Use meaningful blue, teal, green, amber, purple, and rating colors. Avoid both arbitrary decoration and a monochrome reset.
- Do not repeat page titles in oversized intro cards, enclose ordinary metrics in nested cards, or add inventory counters without an actionable interpretation.
- Home scrolls vertically, with no horizontal content carousel. Keep the five existing tab labels.

## Palette, type, and measurement

`StudyDesign` is the canonical adaptive palette. `AppTheme` remains a compatibility entry point; its ordinary surfaces and page background use the selected language. Muted informational text uses the canonical secondary foreground for legibility. Existing domain/status colors remain meaningful. Do not introduce an alternate theme or new hex values in a feature to imitate an existing role.

| Role | Light | Dark |
| --- | --- | --- |
| Page | #F5F7FB | #111923 |
| Primary text | #18263B | #E8EEF8 |
| Secondary text | #637086 | #A9B5C7 |
| Accent text | #2867DA | #8FB8FF |
| Solid blue action | #2867DA | #2867DA |
| Surface | #FFFFFF | #1D2736 |
| Separator / card border | #E0E6EE / #E4E9F1 | #34465D |
| Reference fill / text | #E2F1E9 / #235B43 | #203C33 / #A6E0BE |
| Amber fill / text | #FFF0D4 / #8D601B | #443522 / #F1CA79 |
| Teal / purple | #138B83 / #8064C7 | #8BD7BF / #B6A4EF |

Use the system sans-serif font. `designText` is the semantic entry point for new screens; its `DesignTextRole` aliases the existing measured roles to avoid changing approved layouts. `DesignMeasuredType` is the shared scaling engine for those roles and the selected account/membership treatments. `selectedText` is reserved for measured reference-specific typography, not arbitrary sizing in new screens. Home retains its dedicated exact roles.

| Role | Base size / line height | Weight / tracking |
| --- | --- | --- |
| Root title | 30 / 35.5 | Bold / −1 |
| Section heading | 17 / 20 | Bold / −0.3 |
| Destination | 18 / 24.3 | Bold |
| Supporting row / tool | 16 / 21.6 | Bold / −0.25 |
| Body / reading | 14 / 23.1 | Regular |
| Subtitle | 13 / 20.8 | Regular |
| Metadata | 11 / 16.5 | Regular |
| Identifier | 11 / 19 | Bold / 1.1 |
| Question prompt | 28 / 35 | Bold / −0.7 |
| Answer | 15 / 24.75 | Regular |
| Action | 14 / 20 | Semibold |

Screen inset is normally 22pt; account forms use 24pt. Sections generally separate by 26–30pt, supporting rows by 18pt vertical padding. These are defaults, not a universal spacing multiplier. Keep explicit per-screen overrides from the fidelity specifications. Cards normally use 20pt padding and 24pt corners; the reference shortcut uses 20pt corners, controls/icon tiles 13pt, icons approximately 23pt in a 42pt tile. Use one subtle separator, not doubled rules.

Home overrides remain exact: 34pt activity values in equal 38pt line boxes, 23pt featured title, 19pt question, 14pt shortcut heading, 11pt shortcut caption. Keep the small left Home label, blue greeting period, vertical metric divider, and independent caption wrapping. Never vertically center each value-and-caption block separately.

## Reusable recipes

The [screen recipe guide](screen-recipes.md) contains starter code, component choices, state coverage, and the new-screen acceptance checklist. Native implementations live in DesignSystem, with a Debug-only pattern gallery. Reuse the approved screen-specific components when extending their family.

| Recipe | Structure | Containers and emphasis |
| --- | --- | --- |
| Open destination list | Page intro, section heading, icon/title/metadata/disclosure rows | Open rows with separators; highlight only a meaningful primary destination |
| Detail / reading | Identifier if useful, open title/overview, reading sections | Blue/teal heading rule; complete text and nesting; no paragraph cards |
| Grouped settings | Open identity or selected banner; labeled preference groups | One quiet white group for related controls; no card around every row |
| Account / submission form | Open intro, labeled inputs, inline guidance, action | Underlined short fields; bounded multiline editor; no outer form card |
| Review | Open aggregate summary; one surface per independent review | Labeled score pair inside review; never nested score cards |
| Study interaction | Compact context/progress; discrete question surface; answers/actions | Physical stacked flashcards; expandable scrolling for long material |
| Illustrated membership / welcome | Selected blue artwork/header; readable content and actions | Preserve selected hero composition; artwork is decorative and not a generic page template |

## Family-specific invariants

- **Events:** open phase/event rows, clear identifiers and summaries, preserved hierarchy. Event-code pill is a quiet identity cue, not a generic inventory badge. Event overview has a blue rule; briefing guide earns an amber surface.
- **Discussion:** all sections start open and collapse independently; whole heading is the toggle with a small chevron and expanded-state semantics. Preserve nesting and full text. No persisted collapse state or collapse-all feature.
- **Flashcards:** individual preview cards; white physical question/answer cards with subtly different stacked layers, restrained shadows, purple/green top accents. No extra header divider. Ratings remain Missed/Hard/Good/Easy, equal width with 4pt gaps; use two rows when text requires it. Preserve scheduling.
- **Instructors:** All/Sims/Flights segmented filter and prominent Submit Review. Store 1–7 scores; normalize display to one decimal out of ten; map color/descriptor from rounded raw scores. Labels, denominators and seven segments remain present. Color describes temperament/grading style, not overall quality. Missing values remain missing. Detail has open identity and At a glance blue rule, with one white card per review and each review's own grades.
- **More:** integrated full-width blue identity/artwork banner; gold membership module with real status; grouped settings in the existing order. Dark Manage remains light gold #F3DFAD with #62451C text. Do not invent trial-versus-paid status or dates.
- **Onboarding:** selected layered product preview, open fields, native Apple/email actions. Compact callout: “Not sure yet? Start with Echo.” and “You can always update it in Profile settings later.”
- **Premium:** blue A palette/C spacing and illustration, overlapping white timeline, rounded foreground rail within longer soft background rail. No ticket circles/dotted seam. Live StoreKit price/eligibility/duration; Secured by Apple; clear Continue and dismissal. Reminder promise requires verified delivery. Keep native purchase, permission and management handoffs.

## Accessibility, state, and native behavior

Use Dynamic Type, flexible heights, wrapping and vertical scrolling. Do not shrink meaningful text to retain screenshot geometry. Parallel metrics keep value baselines aligned; score pairs and membership controls can stack. Use real accessible labels, selected/expanded states, and at least 44pt action targets. Decorative artwork stays outside the reading order. Keep errors legible with text, not color alone.

General Library title is white in dark mode where highlighted; rating numbers use explicit bright semantic foregrounds. Retain native back gestures, keyboard behavior, tabs, and safe scrolling clearance. App-owned navigation can use compact selected headers; Quick Look, video playback, permission sheets, purchase sheets, alerts, and system editing controls remain native.

Every supported state must use the same language: loading, empty/missing data, errors/retry, offline/download progress, locked/expired, pending/success, and destructive confirmation. Do not fabricate remote states just to complete a screenshot or claim live purchase verification from a fixture.

## Change policy

For each new screen: identify the task and recipe; reuse roles/components; add it to the audit; compare screenshots with the closest approved reference; verify light/dark, large text and navigation; record deviations and test evidence. Request targeted review only for a genuinely new pattern or unresolved visual choice. Keep approved screens stable when shared components change.

Daily goals, mascots, reward currencies, and new tracking are deferred. The flame remains temporary artwork. No annual/lifetime plan or unsupported features are implied by reference imagery.
