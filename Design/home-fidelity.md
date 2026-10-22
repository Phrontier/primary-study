# Home A1 — native fidelity review

**Status:** Approved by the user October 15, 2026; native fidelity benchmark for the remaining pilot.

The selected A1 HTML/CSS is the visual specification. This pass changes Home and its debug capture/test support only. The other pilot screens retain their previous implementation.

## What was restored

- Small left-aligned Home label above the 30pt greeting, with its blue period; the centered system title and reserved bar space are removed on Home.
- Explicit scaled type roles, weights, tracking, and line spacing rather than substituting default SwiftUI text styles.
- A 92pt activity band with a vertical separator, equal 34pt numbers in 38pt rows, and captions that grow below the numbers. At standard text the daily caption breaks after “reviewed,” matching A1. Accessibility text may stack the metrics.
- The featured destination's 23pt title, small code, 22pt interior inset plus border, 20pt action gap, and blue gradient/border.
- Supporting destinations use small codes, bold 16pt titles, 11pt metadata, open rows, and single separators. Actual destinations still come from saved history.
- The daily question keeps its white card, 19pt prompt, 13pt choices, compact letter badges, and small amber heading dot.
- The green shortcut uses its own compact 14pt title and 11pt caption, rather than the larger section-heading role.
- Native tab-bar safe-area clearance is counted once. The browser's 116pt bottom reservation is represented by native safe-area space plus 20pt of content padding.

## Evidence

Comparisons use the exact A1 sample content on a dedicated **393 × 852 logical-point iPhone 14 Pro simulator**. Device captures are preserved at native resolution and normalized to 393 × 852 for comparison. The browser reference is captured at 393 × 852 CSS pixels.

| View | Side by side | 50% overlay |
| --- | --- | --- |
| Top | [Approved A1 / SwiftUI](previews/screenshots/home-fidelity/comparison-top.png) | [Content overlay](previews/screenshots/home-fidelity/overlay-top.png) |
| Bottom | [Approved A1 / SwiftUI](previews/screenshots/home-fidelity/comparison-bottom.png) | [Content overlay](previews/screenshots/home-fidelity/overlay-bottom.png) |

Overlays omit the system status bar and bottom navigation chrome; full comparisons retain both. The bottom pair shows each platform's bottom scroll stop, so it can include a small vertical offset from the different native navigation safe areas. Compare card internals and section spacing as well as absolute placement. Browser captures are supplied by the browser screenshot service and can be compressed; color intent is verified against computed CSS/RGB tokens rather than inferred from compressed pixels.

Native iOS status-bar/Dynamic Island rendering, the existing platform tab bar, SF Symbol shapes, text rasterization, and system scroll effects remain native. The CSS phone-frame shadow is presentation chrome and is not applied to the app screen. The native tab bar retains its system proportions and icons; this pass does not restyle navigation across the app.

## Debug fixture and live behavior

`HomeDesign.swift` contains the Home-only type roles, recent-row treatment, and an A1 fixture inside `#if DEBUG`. The fixture requires **both** `--ui-testing` and `--home-a1-fixture`. It supplies display snapshots only; it does not seed progress, record sample ratings, or save sample daily answers. Release builds exclude it.

Normal launches continue using `homeScreenSnapshot`, real history/daily counts, existing quiz answer handling, and existing content access/navigation. The reference shortcut continues routing through the Events navigation stack. No model, persistence format, API, or subscription changes are included.

## Verification

- Debug simulator build and matched-size Home capture/navigation test passed.
- The existing real free-account/Premium access regression passed.
- Dark mode at normal and largest accessibility text sizes passed the Home capture, shortcut visibility, navigation, and return checks.
- The full emergency-reference shortcut scrolls above the native tab bar at the largest accessibility text size (verified by its frame, not just partial hittability).
- `git diff --check` passed.

The user approved this Home fidelity pass on October 15, 2026. Approval applies to Home; the remaining pilot comparisons are reviewed separately.


## Theme and text captures

| Condition | Top | Bottom |
| --- | --- | --- |
| Dark / normal text | [View](previews/screenshots/home-fidelity/native-dark-top.png) | [View](previews/screenshots/home-fidelity/native-dark-bottom.png) |
| Dark / largest accessibility text | [View](previews/screenshots/home-fidelity/native-dark-accessibility-top.png) | [View](previews/screenshots/home-fidelity/native-dark-accessibility-bottom.png) |

The visual reference's CSS values map to native points at standard text size; accessibility layouts are allowed to expand and stack. The saved full-resolution light captures preserve the simulator's original raster for closer inspection.
