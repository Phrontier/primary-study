# App-wide rollout validation

Updated October 19, 2026. See [screen audit](screen-audit.md), [current language](design-language.md), [recipes](screen-recipes.md), and the [native gallery](previews/design-rollout.html).

## Implementation result

The selected language now backs app-owned utility screens as well as the approved core screens. Shared legacy entry points use the canonical page/surface palette, open introductions and rows, quieter borders, and explicit scaled typography. Short form inputs use underlines; articles use open reading sections. Quiz/practice questions and answers expand instead of shrinking into a fixed viewport. Quiz categories and practice modes no longer sit inside a second enclosing card. Ground-school inventory metrics were removed from its introduction. My Reviews reuses the selected score pair.

`DesignMeasuredType` centralizes scaling while preserving the selected families' differing line-box policies. `designText` is the forward-facing semantic entry point, with historical names kept source compatible. Muted informational text uses the canonical secondary foreground. Semantic action fills choose readable black/white text; a model-level contrast check covers primary, accent, success, warning and danger fills in both appearances.

The Debug-only native pattern gallery demonstrates normal, long, missing-data and error examples. The repository guidance and recipe guide require the audit/reference/comparison workflow for future screens. App APIs, persistence, backend, pricing, access policy and scheduling were not changed in this pass.

## Recorded evidence

| Check | Result / evidence |
| --- | --- |
| Full deterministic suite | 106 tests passed in `design-rollout-final.xcresult`; adding the semantic-action contrast check produced 107 passing tests in `design-rollout-dark.xcresult` |
| Full UI regression run | 20 of 21 checks passed in `design-rollout-final.xcresult`; the sole failure expected the previous welcome branding text. The updated test asserts the approved heading, email/Apple actions and absence of signed-in tabs; it passed in `design-rollout-followup.xcresult` |
| Home preservation | App-content pixels are identical to the approved native capture in the comparison region, logical y=90–740; status/tab chrome excluded. Side-by-side, overlay and machine-readable comparison are saved in the gallery |
| Connected events/study | Normal and largest-text navigation, discussion disclosure, deck, reveal and rating flow passed after shared typography changes |
| Extended utilities | Search, General Library, Profile, Notifications, FAQ, feature form, My Reviews, stats, recent briefs/decks, Version and quiz entry passed in standard and largest text, light and dark |
| Resource/practice | Ground school → Contact 1 → Full Test → incorrect answer; native source PDF entry; General Library → video download state passed. No remote download or purchase was performed |
| Final quiz layout | Dedicated normal/largest-text checks passed after removing the outer category container; same checks passed in dark mode |
| Review form/selectors | Form → squadron → event → enabled Chill Factor → actual Select Chill Factor sheet → Close passed. This asserts the selector navigation title rather than merely finding the parent's Close button |
| Compact phone | Pattern gallery and extended utility walkthrough passed on the 375 × 667 simulator |
| iPad | Pattern gallery and selected instructor/More/Premium/settings flow passed on iPad mini, 744 × 1133; first automation startup was slow |
| Dark mode | 107 models and five targeted UI checks passed; final quiz/selector refresh also passed in `design-rollout-final-dark.xcresult` |
| Release device build | Unsigned Release build succeeded. Binary inspection found neither the Debug gallery type nor its launch flag |
| Static checks | `git diff --check`, generated-gallery image/link existence, and browser filtering/layout inspection are recorded with the final handoff |

Full xcresult bundles and build logs are under `/tmp` and may be removed by the OS. Exported screenshots, capture manifests and Home comparison are durable under `previews/screenshots/design-rollout/`. Final-source confirmations are appended below.

## Test corrections and scope of verification

The first broader walkthrough tried to switch tabs while Search's keyboard was open. Search now dismisses on submit and the walkthrough submits the query before switching. The old welcome-copy assertion was updated to the locked design; account-gate assertions remain.

The original selector smoke check was insufficient: the parent's Close button could satisfy it. The replacement selects squadron/event and requires the actual selector title. Initial attempts scrolled the suggestion strip or began over the keyboard; the final test targets the named main scroll view and starts its dismissal gesture in visible content. No backend review is submitted.

Screenshots prove rendered states, not every alternate branch. Source inspection covers supported loading, missing, error, offline, locked and destructive states; only the named exercised states are runtime-verified. Real-device VoiceOver reading order, external account/email/Apple deletion, remote moderation writes, StoreKit lifecycle verification and delivered trial reminders remain release checks. The local StoreKit integration test still fails with an unavailable storefront/product; it is excluded from the deterministic pass and is not reported as passed.

## Native differences and review

Native navigation bars remain on utility screens; approved compact headers remain on the core families. Lists preserve native reordering, pickers and keyboard editing. Quick Look, AVKit, Apple sign-in, purchase/management/permission sheets and destructive alerts remain native. Actual data and enlarged layouts can differ from fictional static samples.

Home and the connected event/study native pass remain approved. The other selected native families and this app-wide extension await user visual review. No App Store upload/submission or production configuration change was made.

## Reproduce gallery generation

Export attachments with `xcrun xcresulttool export attachments --path RUN.xcresult --output-path DIR`, then run `Design/scripts/build-rollout-gallery.py` with repeated `--capture light=DIR`, `--capture dark=DIR`, `--capture compact=DIR`, or `--capture ipad=DIR`. Use the bundled artifact Python runtime with Pillow; this adds no app dependency. Later captures overwrite matching screen/appearance entries. Appearance is an explicit input; dimensions come from capture/device scale. Keep the main reference simulator light when taking reference captures.

## Final-source confirmation

- `design-rollout-final-models.xcresult`: all 107 deterministic tests and the actual review/selector walkthrough passed after the final text-token adjustment.
- `design-rollout-final-light.xcresult`: all four targeted light-mode quiz (normal/largest), resource/practice and actual selector checks passed.
- `design-rollout-final-dark.xcresult`: all three targeted dark quiz (normal/largest) and actual selector checks passed.
- `/tmp/design-rollout-release-final.log`: unsigned Release device build passed after the named-scroll-view and text-token refinements.
- The gallery script compiles using an external `/tmp` cache; `git diff --check` passes.

Swift source fingerprint: `645b395e8e9b63e0390d51557f28b19884874d78802e796c7fc4e488183d54ed` across 70 files. Capture/run manifests retain device/test identifiers.

### Complete-content confirmation

The initial temporary Xcode snapshot contained empty Contents folders. The workspace resources were present. The complete 414 MB content tree was copied into the local build snapshot; all 114 manifest-referenced bundled paths are now present in the simulator app. `design-rollout-resources-complete.xcresult` passed the practice flow and actual EP NWCs native reader, explicitly rejecting the missing-document state. The earlier failure-state capture is labeled Document unavailable, not a successful reader. `/tmp/design-rollout-release-complete.log` confirms the unsigned Release build with the complete content tree. The refreshed compact quiz check also passed in `design-rollout-compact-quiz-final.xcresult`.

Quick Look verification: its first frame can be blank while PDF pages load asynchronously. `design-rollout-pdf-render.xcresult` captured the rendered first page and native page control, and the refreshed gallery shows that frame. The maintained resource test now explicitly waits for the native Page Label control instead of treating the navigation title as page-render proof. No document-viewer code was changed.

Final reader assertion passed in `design-rollout-pdf-final.xcresult` (actual Page Label control required). Final gallery: 159 captures, zero missing capture files or local links; browser appearance filtering works and the page has no horizontal overflow. The final Release binary excludes the Debug gallery type/flag and contains the reference PDF.
