# Connected SwiftUI design pilot

> App-wide extension: see [current design language](design-language.md), [screen recipes](screen-recipes.md), and [coverage audit](screen-audit.md). This document retains the scope and evidence of its original pass; it is not a restriction on the authorized app-wide rollout.

**Status:** Implemented October 14, 2026; native verification recorded below.

This pilot implements the approved Home → Events → phase → category event list → event detail → discussion reading / flashcard deck → question / answer flow. The HTML studies remain the visual references. This is the first connected native slice of the redesign.

The Home screenshots below document the initial pilot. The subsequent [Home fidelity review](home-fidelity.md) supersedes them for Home. The measured [connected pilot fidelity pass](pilot-fidelity.md) supersedes this initial implementation for event browsing, reading, and flashcards.

## What changed

- Open page introductions and destination rows replace repeated enclosing cards and inventory counters.
- Home uses aligned activity numbers, a highlighted last destination, quieter recent rows, a discrete daily question card, and the green emergency-reference shortcut after it.
- Event details use a code pill, a blue overview rule, open study-tool rows, and an amber briefing-guide shortcut after the tools.
- Discussion sections default expanded and toggle independently through their whole heading, with expanded/collapsed accessibility values. Nested content remains intact.
- Decks retain individual white card previews. Study cards retain tap-to-reveal behavior and a physical stack, with purple/green top edges. Rating controls use four columns normally and two from XXXL text upward.

## Native component map

The pilot is scoped through `Primary Gouge/DesignSystem/StudyDesign.swift`, leaving the existing global theme in place for later rollout areas.

| Approved element | Native implementation |
| --- | --- |
| Semantic light/dark palette | `StudyDesign` |
| Open scrolling page, 22pt horizontal insets | `StudyScreen` |
| Page title and optional identifier pill | `StudyHeading` |
| Discrete question / card / featured surface | `StudySurface` |
| Open destination and highlighted shortcut | `StudyDestinationRow` |
| Scannable event code, title and summary | `StudyEventRow` |

Type scales with Dynamic Type. At accessibility text sizes Home's two metrics become full-width stacked groups to avoid breaking captions into narrow columns. Long reading and answer content grows vertically within the page scroll view. Native navigation, tab bars, and safe areas remain platform-managed.

## Live data and behavior

Home's pilot daily metric counts **distinct flashcards in the current training catalog with a saved review date today**, in the local calendar. Repeated ratings of one card still count as one card; this is not a count of review actions. It uses existing progress records and creates no new analytics or persistence format. The final product metric remains open for later review.

Recent destinations are deduplicated from existing saved activity; the featured destination is omitted from the two supporting rows. New accounts see the existing emergency-reference fallback and no invented recent history. The flame is a temporary emoji treatment, matching the approved study's placeholder; final artwork and daily goals remain deferred.

Existing destinations, free/Premium content gating, quiz answers, spaced-repetition scheduling, study-session saving, and reference/image content remain connected. No backend APIs or subscription behavior change. Instructor, More/settings, onboarding, and subscription native screens remain for subsequent rollout.

## Verification

Build and simulator checks use a local temporary source copy because Xcode stalled inside OneDrive's coordinated project read. The workspace remains the source of truth.

- Debug iOS Simulator build passed.
- Connected light-mode UI test passed: Events → Contacts → Sims → FAM2101 → discussion collapse → deck → reveal → Good → next card → Home.
- Existing free-account/Premium access regression test passed.
- Real-data unit test passed: distinct daily reviews, next-day reset, deduplicated history, and omission of the featured recent destination.
- Final dark-mode/largest-accessibility-text connected UI test passed. Home metrics stack at accessibility sizes, answers scroll to the rating controls, and Good advances to the next question.
- Native screenshot evidence is saved under `previews/screenshots/native-pilot/`; light screenshots use the normal text size and dark screenshots use the largest accessibility text size.

This is simulator verification, not an on-device or VoiceOver certification. Final artwork, real-device review, midnight refresh while Home remains continuously open, and other screen families remain outside this pilot.


## Screenshots

These are native iPhone 17 simulator captures, not HTML mockups. Long content may be scrolled to show the interaction being checked.

| Screen | Light / normal text | Dark / largest accessibility text |
| --- | --- | --- |
| Home, no recent history | [View](previews/screenshots/native-pilot/pilot-home-light.png) | [View](previews/screenshots/native-pilot/pilot-home-dark-accessibility.png) |
| Home after study | [View](previews/screenshots/native-pilot/pilot-home-with-history-light.png) | [View](previews/screenshots/native-pilot/pilot-home-with-history-dark-accessibility.png) |
| Events | [View](previews/screenshots/native-pilot/pilot-events-light.png) | [View](previews/screenshots/native-pilot/pilot-events-dark-accessibility.png) |
| Sims event list | [View](previews/screenshots/native-pilot/pilot-event-list-light.png) | [View](previews/screenshots/native-pilot/pilot-event-list-dark-accessibility.png) |
| Event detail | [View](previews/screenshots/native-pilot/pilot-event-detail-light.png) | [View](previews/screenshots/native-pilot/pilot-event-detail-dark-accessibility.png) |
| Discussion expanded | [View](previews/screenshots/native-pilot/pilot-discussion-expanded-light.png) | [View](previews/screenshots/native-pilot/pilot-discussion-expanded-dark-accessibility.png) |
| Discussion collapsed | [View](previews/screenshots/native-pilot/pilot-discussion-collapsed-light.png) | [View](previews/screenshots/native-pilot/pilot-discussion-collapsed-dark-accessibility.png) |
| Deck | [View](previews/screenshots/native-pilot/pilot-deck-light.png) | [View](previews/screenshots/native-pilot/pilot-deck-dark-accessibility.png) |
| Question | [View](previews/screenshots/native-pilot/pilot-question-light.png) | [View](previews/screenshots/native-pilot/pilot-question-dark-accessibility.png) |
| Answer and ratings | [View](previews/screenshots/native-pilot/pilot-answer-light.png) | [View](previews/screenshots/native-pilot/pilot-answer-dark-accessibility.png) |

Final results: connected light flow passed; connected dark/accessibility flow passed; real-data unit test passed; free/Premium access regression passed after restoring the spoken locked-state label on event links. `git diff --check` passed. The wider app has not been rolled out or certified by these focused tests.
