# Theme and larger-text validation — first pass

**Status:** Proposed dark equivalents and browser text-stress adaptations; awaiting user review. Production code is unchanged.

## Coverage

The gallery at `previews/validation.html` contains 15 selected specimens: Home, Events root, category list, instructor root/detail, event detail, discussion reading, deck/question/answer, onboarding welcome/account/setup, Premium, and More/settings.

Checked each at standard and 130% text in light and dark mode: 60 browser combinations. Automated DOM checks found no horizontal content overflow or primary text/control rectangles outside the phone content width. These checks do not prove absence of every clipping, contrast, or accessibility issue. Representative screenshots were visually inspected for Home, flashcard answer, onboarding welcome, Premium, and More.

## Adaptations

- Dark page background `#111923`, standard surface `#1D2736`, primary text `#E8EEF8`, secondary text `#A9B5C7`, separators `#34465D`.
- Retain prominent blue headers and blue/white primary actions. Use lighter blue for text/icons on dark surfaces; do not turn primary buttons pale blue with white text.
- Keep semantic green, purple, red, amber, and gold roles with dark tinted surfaces and brighter text. Membership stays gold-toned rather than becoming a generic gray card.
- Parallel Home numbers stay aligned; the activity band grows when captions wrap.
- Session metadata wraps at larger text. Answer cards and reading content expand and scroll rather than truncate.
- The standard four-button rating row becomes a two-by-two arrangement at the larger stress size. This is a proposed accessibility adaptation, not a change to the standard locked layout.
- Bottom navigation allows larger labels and a taller bar. Final content retains scroll clearance.

## Limits and next step

The browser modifier is a visual prototype, not production theme code. It uses role/color translation for study purposes; native implementation should use explicit semantic palette tokens. The 130% setting is not an iOS Dynamic Type category. Final contrast verification, accessibility sizes, VoiceOver, device safe areas, and real auth/StoreKit/notification behavior need native testing.

Review dark-mode appearance and large-text adaptations, then build one connected SwiftUI pilot before app-wide rollout. Preserve the selected layouts; document concrete platform-driven changes rather than reopening design exploration.

The browser log also contained one source-less MutationObserver error during frame inspection. The preview sources do not use MutationObserver; it could not be attributed to the app. Successful renders and interaction checks were verified separately, so this pass does not claim a fully clean console audit.

## User approval

The user approved the gallery after the requested dark-mode color corrections. The visual targets are selected for native implementation. Browser validation remains a first pass, with the native limitations above unchanged.


## Connected native pilot — October 14, 2026

The approved Home/event/discussion/flashcard slice has been implemented in SwiftUI. A simulator build, connected light-mode navigation/reveal/rating test, free/Premium regression test, and daily-count/history unit test passed. The same connected flow also passed in dark mode at the largest accessibility text size; it required scrolling through long answers before the lazy rating controls were instantiated. Home metrics stack at accessibility sizes, and rating controls use two columns from XXXL upward. See [native pilot](native-pilot.md) for scope, component mapping, screenshot evidence, and remaining on-device/VoiceOver checks. The previous browser validation remains a visual study, not native test evidence for other screen families.
