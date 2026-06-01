# Flashcard Authoring Runbook

Use this runbook when starting or resuming flashcard authoring.

## Fresh-Thread Bootstrap

1. Confirm repo state with `git status --short --branch`.
2. Read:
   - `Primary Gouge/AppContent/FlashcardAuthoringRules.md`
   - `Primary Gouge/AppContent/FlashcardAuthoringProgress.md`
   - `Primary Gouge/AppContent/SyllabusEventReference.json`
3. Resume from the first event marked `pending` or `in_progress`.
4. Read that event's completed override in `Primary Gouge/AppContent/EventContentOverrides/<EVENT>.json`.
5. Confirm the event's canonical discussion item list and current flashcard coverage before authoring.

## One-Event Workflow

Work exactly one event at a time.

1. Gather sources.
   - Start from the completed event override.
   - Use `canonicalCoverage` to map discussion items to visible sections.
   - Use the original source documents only when the completed discussion item is not enough to produce a safe card.
2. Draft cards in `Primary Gouge/AppContent/FlashcardLibrary.json`.
   - Add explicit IDs.
   - Add `eventCoverage` for every covered syllabus item.
   - Add only controlled tags: `maneuvers`, `procedures`, `systems`, `planning`.
3. Rebuild the manifest.
   - Run `swift Tools/BuildStudyManifest.swift`.
   - Inspect `Primary Gouge/AppContent/SyllabusEventAuditReport.json`.
   - Confirm this event is absent from `flashcardCoverageIssues`.
4. Build for testing.
   - Run the existing `xcodebuild ... build-for-testing` command used by the discussion-item pass.
5. Update `FlashcardAuthoringProgress.md`.
   - Mark the event complete only after manifest rebuild, audit inspection, and build-for-testing.
   - Record card count, validation result, build result, and source notes.

## Auto-Continuation Loop

After a completed event passes validation and build-for-testing, immediately continue to the next `pending` event in `FlashcardAuthoringProgress.md`.

For each loop:

1. Select only the first `pending` or `in_progress` event.
2. Author only that event's cards.
3. Run manifest rebuild, audit inspection, and build-for-testing.
4. Update that event's tracker row and the active-pass resume point.
5. Move to the next pending event without asking for approval.

Stop the loop and report status when:

- source material is ambiguous or insufficient
- manifest validation fails
- build-for-testing fails
- coverage remains unresolved for the current event
- the thread is handing off or about to compact

## Compaction Recovery

If a thread compacts or hands off:

- Do not rely on chat memory.
- Read `FlashcardAuthoringProgress.md` first.
- Re-run or inspect the latest `SyllabusEventAuditReport.json`.
- If an event is marked `in_progress`, inspect `FlashcardLibrary.json` and decide whether coverage is complete from source, not tracker text.
- Resume the auto-continuation loop only after the current event has a clean validation/build state.

## Build Expectations

The manifest builder:

- reads only the flat `FlashcardLibrary.json` for authored cards
- generates canonical EP/N/W/C/limits cards from XML
- maps legacy aliases such as `FAM4401` to canonical event codes
- rejects placeholder answers, duplicate authored IDs, invalid event coverage, reserved reference tags, and uncontrolled authored tags
- reports missing event coverage in `flashcardCoverageIssues`
