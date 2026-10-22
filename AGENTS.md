# Primary Gouge development guidance

## UI work

- Read `Design/product-brief.md`, `Design/design-language.md`, and `Design/screen-recipes.md` before creating or changing UI. Check `Design/screen-audit.md` for the route and reference.
- The selected previews and linked native fidelity measurements are the visual specification. Preserve approved spacing, typography, separators, accents, shadows, and hierarchy; do not merely reproduce the elements.
- Reuse `StudyDesign`, `designText`, and the existing screen-family components. `AppTheme` and `pilotText` are compatibility names, not separate design directions. Do not add another theme, arbitrary font scale, or generic card wrapper.
- Default to open composition and meaningful color. Cards group independent interactions/reviews; do not enclose ordinary metadata in nested cards.
- New screens inherit the closest recipe. Add the route/states to the audit, capture a visual comparison, and record verification. New patterns require targeted visual review; existing patterns do not require generating three alternatives.
- Validate Dynamic Type, dark mode, small-phone/iPad layout, keyboard behavior, VoiceOver semantics, safe scrolling and navigation. Preserve native system purchase, permission, media and document interfaces.
- Keep real data, access gates, scheduling, privacy and persistence behavior unchanged in visual-only work. Do not invent metrics, reviews, trial eligibility, prices, or backend states.
- Debug design fixtures/gallery must be excluded from Release and must never grant access or perform purchases.

## Local validation

The OneDrive checkout can stall Xcode's coordinated project reads. If this occurs, build an up-to-date local snapshot under `/tmp`; the workspace remains authoritative. Keep generated build results outside the repository and summarize durable evidence under `Design/`. Do not treat simulator/mock purchase checks as real-device StoreKit verification.
