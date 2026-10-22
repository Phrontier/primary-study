# Connected pilot fidelity pass

**Status:** Implemented and verified October 15, 2026; approved by the user. Home was approved October 15, 2026; the connected pilot was approved after comparison.

The selected HTML/CSS studies are the visual specification. This pass refines the existing Events → phase → Sims → event → discussion / deck → study flow. It introduces no new visual direction. Instructor, onboarding, More, and subscription implementation remain outside this pass.

## Measured specification

All measurements below are points at normal text size, corresponding to CSS pixels in the 393 × 852 reference. Typography scales with Dynamic Type; long content expands vertically.

| Element | Specification |
| --- | --- |
| Page | 22 horizontal inset; 18 top inset below the system safe area |
| Back header | 13pt label, 17pt arrow; 23pt layout height with a minimum 44pt touch target; 20pt after it |
| Page title | 30pt bold, −1pt tracking, 35.5pt minimum line box |
| Section heading | 17pt bold, −0.3pt tracking, 20pt line box |
| Event identifier | 11pt bold, 1.1pt tracking; contextual pills use an 8pt corner radius |
| Root destination | 18pt bold; 46pt tinted icon tile; 23pt vertical inset; open separator rows |
| Event list | 11pt identifier, 18pt title, 13pt summary; 22pt vertical inset; no enclosing cards |
| Event overview | 14pt text / 22.4pt leading; 3pt blue rule; 18pt content inset |
| Discussion reading | 14pt text / 23.1pt leading; teal section rule; default-expanded collapsible headings |
| Deck previews | Individual 24pt-radius surfaces, 21pt inset, 16pt bold question and 12pt excerpt |
| Study header | 22pt bold title, compact identifier pill, 5pt purple progress track; no extra separator |
| Physical study card | 24pt radius, 24pt horizontal content inset, 5pt curved top accent, two subtly different offset stack layers |
| Question / answer | 28pt bold / 35pt leading; 15pt regular / 24.75pt leading |
| Rating controls | Four equal columns, 4pt gaps, 11pt corners, minimum 44pt height; two columns at larger sizes |

Purple marks the question face; green marks the answer face. Rating controls retain distinct red, amber, blue, and green foregrounds, tints, and borders. Shadows are restrained, with the stack layers providing most of the physical-card effect. Surface and text colors have explicit light/dark equivalents.

`PilotTypography.swift` contains explicit type roles, scrolling page/back-header composition, and the native interactive-back bridge. `StudyDesign.swift` contains the pilot palette and shared rows. Screen-specific spacing lives with the corresponding screen rather than applying one universal section gap.

## Comparison limits

System status bars, native tab bars, SF Symbol outlines, text rasterization, and system scroll effects remain native. Comparison overlays exclude system chrome. The browser reference uses curated sample content: its fifth phase and some later Sims entries do not match the actual catalog. Native views preserve real catalog content and actual library document titles. These data differences must not be mistaken for typography or layout regressions.

Home remains the separately approved benchmark in [Home fidelity](home-fidelity.md).

## Review artifacts

Open `previews/pilot-fidelity.html` (served at `http://127.0.0.1:8765/pilot-fidelity.html`) for the complete comparison gallery. The left image is the selected preview; the right image is native SwiftUI. Full-resolution native captures and 50% overlays are included for each screen.

| Screen | Side by side | Overlay |
| --- | --- | --- |
| Events | [Compare](previews/screenshots/pilot-fidelity/comparison-events.png) | [Overlay](previews/screenshots/pilot-fidelity/overlay-events.png) |
| Sims list | [Compare](previews/screenshots/pilot-fidelity/comparison-list.png) | [Overlay](previews/screenshots/pilot-fidelity/overlay-list.png) |
| Event detail | [Compare](previews/screenshots/pilot-fidelity/comparison-event.png) | [Overlay](previews/screenshots/pilot-fidelity/overlay-event.png) |
| Discussion | [Compare](previews/screenshots/pilot-fidelity/comparison-discussion.png) | [Overlay](previews/screenshots/pilot-fidelity/overlay-discussion.png) |
| Deck | [Compare](previews/screenshots/pilot-fidelity/comparison-deck.png) | [Overlay](previews/screenshots/pilot-fidelity/overlay-deck.png) |
| Question | [Compare](previews/screenshots/pilot-fidelity/comparison-question.png) | [Overlay](previews/screenshots/pilot-fidelity/overlay-question.png) |
| Answer | [Compare](previews/screenshots/pilot-fidelity/comparison-answer.png) | [Overlay](previews/screenshots/pilot-fidelity/overlay-answer.png) |

Overlays crop to y=59…756 at 393 × 852, excluding the status and tab bars. Full comparisons retain native system chrome. Browser captures may be compressed; color specifications come from CSS values rather than sampled screenshot pixels. The native system font can wrap words differently from the browser font fallback even at the same measured size and leading. The discussion heading is an example; body paragraph rhythm and section boundaries are preserved.

The answer's top comparison intentionally shows the initial scroll position. A separate [controls capture](previews/screenshots/pilot-fidelity/native-answer-controls-light.png) shows all rating controls above the native tab bar. Long content remains scrollable rather than compressing the card to fit one screen.

At accessibility sizes, root destination icons move above full-width titles, the study header stacks, content grows vertically, and rating controls use two columns. No fixed preview height is imposed on reading or answers.

## Behavior and scope

The compact custom headers use normal SwiftUI dismissal and preserve the native navigation controller's interactive pop behavior, including iOS 26's content-area pop recognizer. UI verification checks a real edge swipe returns from event detail to the Sims heading before reopening the event.

No model, persistence, backend, review scheduling, or access policy changes were made in this fidelity pass. The existing real catalog and saved review flow remain connected. The Home fixture is still Home-only; these screenshots use the existing isolated UI-test account and catalog rather than inserting preview sample content into the data model.


## Verification results

- Matched-size iPhone 14 Pro simulator build and connected light flow passed.
- Native edge swipe returned from event detail to the Sims heading; custom Back also passed throughout the flow.
- Discussion collapse, deck entry, reveal, Good rating, next-card advance, and return to Home passed.
- Free-account/Premium access regression passed, including FAM2101/FAM2102 access and FAM2103 lock enforcement.
- Dark mode at normal and largest accessibility text sizes passed the connected flow.
- All four rating controls were verified hittable and fully above the tab bar, with an 8pt clearance, after scrolling in light, dark, and dark/largest text.
- `git diff --check` passed. Builds used a local temporary source copy to avoid OneDrive coordinated-read stalls; the workspace remains the source of truth.

Results: `/tmp/pilot-fidelity-approved-shapes.xcresult` (light and access regression) and `/tmp/pilot-fidelity-dark-final.xcresult` (dark normal/largest text). Normal light captures remain valid after the final accessibility-only root-row rearrangement. Simulator checks do not replace real-device or VoiceOver review.

The user approved these native comparisons and authorized implementing the remaining selected screen families.
