# Reusable native screen recipes

Use with [design language](design-language.md) and [coverage matrix](screen-audit.md). Recipes are compositional starting points, not a requirement that every screen look like Home.

## Pick a recipe

| Task | Start with | Keep specific |
| --- | --- | --- |
| Browse destinations | `AppScrollScreen`, `DesignPageIntro`, `SectionHeader`, `ToolCard` or `StudyDestinationRow` | Open rows, identifiers, semantic icon colors and lock/disclosure cues |
| Read detail/source text | `DesignReadingSection`, `designText(.body)` | Full text/nesting; one rule per section; discussion disclosure behavior |
| Preferences | Selected More grouped settings or native `List` with selected background/type | Related controls share a surface; native toggles, pickers and reordering remain native |
| Enter account/submission data | `DesignFormSection`, native inputs, inline validation, `StudyActionButton` | Underlined short fields, bounded multiline editor; no outer form card |
| Show independent review | `SelectedSurface`, `SelectedInstructorScores` | Individual review grades/text/report; no nested score cards |
| Answer a study question | Individual surface plus natural-height answer controls | Flashcards retain their stack/accent; quizzes retain answer semantics and result state |
| Welcome / membership | Existing selected account/Premium components | Illustration, rail, live price/eligibility, reminder and native handoffs |
| Empty/error | `DesignStateView`, owned retry/action | Explain what happened and next step; do not invent data or embed implementation diagnostics |

## Starter: destination screen

```swift
struct ExampleDestinations: View {
    var body: some View {
        AppScrollScreen {
            DesignPageIntro(title: "Reference", subtitle: "Choose material for your event.")
            DesignReadingSection(title: "Preparation", accent: StudyDesign.blue) {
                NavigationLink {
                    ExistingDestination() // Keep the existing data and access-gate contract.
                } label: {
                    ToolCard(title: "Briefing guide", subtitle: "FAM2101",
                             icon: "doc.text", accent: StudyDesign.amberInk)
                }.buttonStyle(.plain)
            }
        }.detailNavigationChrome(title: "Reference")
    }
}
```

`ExistingDestination` is a placeholder for a real destination, not a generated model or new API. A tab root uses an in-content title and `.pilotNavigation()` rather than reserving a large system navigation title. Approved connected screens retain `PilotPage`/`PilotBackHeader` for their exact compact layout. Utility screens can retain the native inline back bar. Do not hide a sheet's dismiss control or sacrifice interactive back navigation to match a screenshot.

## Typography and surfaces

Use `designText(.title/.section/.tool/.body/.metadata/.action)` and the canonical `StudyDesign` palette. The historical `pilotText` name remains source compatible with identical measurements. `DesignMeasuredType` also powers selected form/membership type, preserving their distinct line-box policy. Home's exact metrics and spacing stay in `HomeDesign`.

Use `SelectedSurface` for an independent interaction/review, `DesignReadingSection` for open content, and a colored `StudyDestinationRow` only when its destination deserves emphasis. `HeroCard` is a compatibility name now drawing an open introduction; `InsetListRow`/`ToolCard` now draw open rows with separators. Existing `SectionContainer` remains a bounded surface, not the default wrapper for a page. Don't introduce new uses of old summary/metric wrappers without checking whether the open recipe is more appropriate.

## Debug reference

Launch a **Debug** build with `--ui-testing --ui-testing-signed-in --design-pattern-gallery`. The gallery is not available in Release. It demonstrates normal and long destinations, disclosure, form inputs, a discrete surface, missing data and error presentation. Its sample action is appearance-only; it does not purchase, grant access, save account data, or contact a backend.

## New-screen acceptance checklist

1. Identify its primary task, existing route/data/access policy, and closest recipe/reference.
2. Add an entry to the coverage matrix with entry path, supported states, gaps, and validation status.
3. Build from shared components, retaining family-specific detail. No arbitrary font scale, universal card wrapper, or new theme.
4. Capture at 393 × 852 logical size with normal text and comparable content. Compare title/section positions, baselines, line heights, separators, borders, accents and shadows against the closest approved screen. Record deliberate native differences.
5. Verify dark mode, largest accessibility text, narrow phone/iPad, long labels, keyboard, navigation/gestures and bottom clearance. Check VoiceOver labels/order and expanded/selected states; color cannot carry meaning alone.
6. Exercise supported empty/error/loading/offline/locked/destructive states through isolated fixtures or existing behavior. Never use fake entitlements or alter production data for screenshots.
7. Run affected tests and approved-screen regressions after shared changes. Add durable screenshots and concise evidence to the gallery/audit. Request targeted review for new patterns, and mark awaiting review until approved.

The primary `AppScrollScreen` scroll view exposes `design-content-scroll` for navigation tests. When a keyboard is open, start dismissal gestures in visible form content; full-screen swipes can hit the keyboard or a nested suggestion strip instead. Selector tests must assert the actual sheet title and enabled preconditions.
