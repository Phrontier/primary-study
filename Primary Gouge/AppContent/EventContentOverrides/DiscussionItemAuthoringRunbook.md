# Discussion Item Authoring Runbook

Use this runbook when starting or resuming any category-wide discussion-item authoring pass. It is designed to survive chat compaction and thread handoff: the next agent should be able to read this file, the progress tracker, and the latest commit history, then continue without relying on prior chat memory.

## Fresh-thread bootstrap

1. Confirm repo state.
   - Run `git status --short --branch`.
   - Check recent commits for the active category.
   - Do not overwrite unrelated user changes.
2. Read the durable authoring sources.
   - `Primary Gouge/AppContent/EventContentOverrides/DiscussionItemAuthoringRules.md`
   - `Primary Gouge/AppContent/EventContentOverrides/README.md`
   - `Primary Gouge/AppContent/EventContentOverrides/DiscussionItemAuthoringProgress.md`
3. Confirm the canonical event set.
   - Read `Primary Gouge/AppContent/SyllabusEventReference.json`.
   - Use `category`, `code`, `shortTitle`, `eventKind`, `media`, `blockCode`, `blockTitle`, and `discussionItems`.
   - Treat the `discussionItems` list as exact required membership and ordering.
4. Confirm the active category source profile.
   - Find local event documents under `Contents/<category folder>`.
   - Identify the category technical authority and supplemental official references.
   - Record any source gaps or conflicts in the progress tracker before authoring.
5. Resume from the tracker.
   - Continue with the first event marked `pending` or `in_progress`.
   - If tracker status and git history disagree, trust the latest committed override plus validation output, then update the tracker.

## One-event workflow

Work exactly one event at a time.

1. Gather sources.
   - Read canonical items from `SyllabusEventReference.json`.
   - Read the local event `.docx` and other event-specific files.
   - Read the category technical authority for procedure, numbers, limits, decision logic, and definitions.
   - Read supplemental official references when the local source is thin or the item is regulatory/planning-heavy.
2. Decide event emphasis.
   - Identify the dominant event purpose before writing `title`, `summary`, `overview`, or `studyNotes.summary`.
   - Decide whether each canonical item gets one visible section or whether a single bundled item needs documented split coverage.
   - Do not group separate canonical items into one visible section unless a locked baseline already allows it.
3. Author the override.
   - Create or update `Primary Gouge/AppContent/EventContentOverrides/<EVENTCODE>.json`.
   - Include `title`, `summary`, `overview`, `primaryDocumentTitles`, `canonicalCoverage`, and `studyNotes`.
   - Add a final `Required Procedures` section with canonical syllabus membership in syllabus order and standardized display capitalization.
   - Add `systemsBrief` only for allowed FAM flight events with dense NATOPS/system content.
   - Do not add `systemsBrief` for Instruments, VNAV, Formation, Capstone, FAM sims, or any non-FAM-flight event.
4. Rebuild and inspect.
   - Run `swift Tools/BuildStudyManifest.swift`.
   - Inspect `Primary Gouge/AppContent/SyllabusEventAuditReport.json`.
   - Confirm no relevant authoring issues were introduced.
5. Build for testing.
   - Run `xcodebuild -scheme 'Primary Gouge' -project 'Primary Gouge.xcodeproj' -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO -derivedDataPath './DerivedData' build-for-testing`.
6. Commit and push.
   - Commit only the completed event override, relevant config/doc updates, regenerated manifest/audit artifacts, and tracker update.
   - Use one commit per completed event unless the user explicitly approves a different batching strategy.
   - Push the branch after the event commit succeeds when the active pass calls for push-per-event.
7. Update the tracker.
   - Mark the event `complete`.
   - Record validation result, build result, source notes, and next event. Use `git log` as the durable source for the final commit hash instead of amending a commit only to write its own hash into the tracker.

## Compaction recovery

If a thread compacts, crashes, or hands off:

- Do not rely on chat memory.
- Read `DiscussionItemAuthoringProgress.md` first.
- Confirm the latest event commit with `git log --oneline -- Primary Gouge/AppContent/EventContentOverrides Tools/BuildStudyManifest.swift`.
- Re-run or inspect the latest `SyllabusEventAuditReport.json` before continuing.
- If an event is marked `in_progress`, inspect the event override and decide whether it is complete by source coverage, not by tracker text alone.
- If the tracker is stale, update it as the first small maintenance change before resuming content work.
- Continue with one event only; do not bulk-regenerate the remaining category after recovery.

## Category source profiles

### Contacts/FAM

- Canonical source: `Primary Gouge/AppContent/SyllabusEventReference.json`
- Category technical authority: `Contact FTI.pdf`
- Local source folder: `Contents/1. FAM (Contacts)`
- Supplemental references: local systems briefs, course rules material, EP/N/W/C XML, NATOPS/expanded checklist when needed
- `systemsBrief`: allowed only for FAM flight events with dense NATOPS/system content

### Instruments

- Canonical source: `Primary Gouge/AppContent/SyllabusEventReference.json`
- Category technical authority: `Pubs/Instrument Navigation FTI  P-765 CH-4.pdf`
- Planning/regulatory authority: `Pubs/Instrument Flight Planning Workbook Rev1.pdf`, `cnaf-3710.7 General NATOPS.pdf`, `KNGP IFG FY25v1.2.pdf`, NATOPS, EP/N/W/C XML, and expanded checklist as required by the item
- Local source folder: `Contents/2. INSTRUMENTS`
- Event-specific sources: local event `.docx`, briefing-guide PDFs, scenario PDFs, 1801/1801C files, jet logs, plates, and DK gouge when useful
- `systemsBrief`: prohibited

### VNAV

- Canonical source: `Primary Gouge/AppContent/SyllabusEventReference.json`
- Category technical authority: confirm before authoring; likely `Navigation FTI.pdf` plus local VNAV docs
- Local source folder: `Contents/3. VNAV`
- Supplemental references: route packets, practice tests, and local gouge after technical authority is confirmed
- `systemsBrief`: prohibited

### Formation

- Canonical source: `Primary Gouge/AppContent/SyllabusEventReference.json`
- Category technical authority: confirm before authoring; likely `Formation FTI.pdf` plus formation supplement
- Local source folder: `Contents/4. FORMS`
- Supplemental references: formation outline, QA study guide, TW-4 formation supplement, and local event docs after technical authority is confirmed
- `systemsBrief`: prohibited

### Capstone

- Canonical source: `Primary Gouge/AppContent/SyllabusEventReference.json`
- Category technical authority: use the event's underlying phase authorities, then confirm any capstone-specific profile or check-event source before authoring
- Local source folder: `Contents/5. CAPSTONE`
- Supplemental references: capstone profiles, local simulator/flight docs, prior completed category overrides where the syllabus makes the event cumulative
- `systemsBrief`: prohibited

## Durable handoff notes

- Keep this runbook category-agnostic. Put active-pass details in `DiscussionItemAuthoringProgress.md`.
- Keep source conflicts, source gaps, and event-specific exceptions in the tracker so the next thread sees them immediately.
- Do not use generated prose as final visible content without manual review.
- Do not do flashcard work during a discussion-item pass unless the user explicitly adds that scope.
