# Event Content Overrides

Use one JSON file per event to hand-author event content without editing generated files.

Flashcards are no longer authored in these event override files. They now live in `Primary Gouge/AppContent/FlashcardsByEvent.json`.

## Workflow

1. Create or update `Primary Gouge/AppContent/EventContentOverrides/<EVENTCODE>.json`.
2. Add or edit:
   - `title`
   - `summary`
   - `overview`
   - `canonicalCoverage`
   - `studyNotes`
   - optional `systemsBrief` for FAM flight events only
3. Author the visible notes as a student-facing briefing aid, not a normalized extraction template.
4. Regenerate the manifest:

```bash
swift Tools/BuildStudyManifest.swift
```

5. Build the app.

Before starting or resuming a category-wide discussion-item pass, read:

- [DiscussionItemAuthoringRules.md](DiscussionItemAuthoringRules.md)
- [DiscussionItemAuthoringRunbook.md](DiscussionItemAuthoringRunbook.md)
- [DiscussionItemAuthoringProgress.md](DiscussionItemAuthoringProgress.md)

For FAM discussion-item generation, grouped section layout and locked baseline behavior are currently driven by [FAMDiscussionAuthoringConfig.json](FAMDiscussionAuthoringConfig.json). Other categories may add their own config files later, but the shared authoring standard still lives in `DiscussionItemAuthoringRules.md`.

## File shape

```json
{
  "code": "FAM4301",
  "title": "OBOGS, Aborts, and Recovery Decisions",
  "summary": "Short event summary shown in cards and lists.",
  "overview": "Longer event overview shown on the event page.",
  "systemsBrief": {
    "headline": "Systems Brief",
    "summary": "Optional dedicated FAM-flight-only NATOPS-style study aid for dense systems briefs.",
    "sections": [
      {
        "title": "How to Brief It",
        "items": [
          { "text": "Start with purpose, then walk the flow path, then explain what cockpit indication changes the answer." }
        ]
      }
    ]
  },
  "canonicalCoverage": {
    "OBOGS and pressurization system": ["OBOGS and Pressurization System"],
    "aborted takeoff": ["Aborted Takeoff"]
  },
  "primaryDocumentTitles": [
    "FAM4301"
  ],
  "studyNotes": {
    "headline": "Discussion Items",
    "summary": "Optional short paragraph introducing the notes.",
    "sections": [
      {
        "title": "OBOGS and Pressurization System",
        "items": [
          {
            "text": "Use the event discussion section for the operational answer students must brief and apply.",
            "children": [
              { "text": "Keep dense system walk-throughs in systemsBrief only when this is an allowed FAM flight event." },
              { "text": "For every other category, keep all discussion-item content inside studyNotes." }
            ]
          }
        ]
      },
      {
        "title": "Required Procedures",
        "items": [
          { "text": "OBOGS and Pressurization System" },
          { "text": "Aborted Takeoff" }
        ]
      }
    ]
  }
}
```

Omit `systemsBrief` entirely for Instruments, VNAV, Formation, Capstone, FAM sims, and any non-FAM-flight event.

## Notes

- `StudyManifest.json` is generated. Do not hand-edit it.
- `EventOverrides.json` still exists for legacy compatibility, but new event authoring should go in this folder.
- Legacy `focusAreas` notes are still supported while older events are being migrated.
- `canonicalCoverage` is required for every authored discussion-item event override and should map each canonical syllabus discussion item to the authored section title or titles where it is substantively covered.
- Use display title case for visible note headlines, section titles, and final `Required Procedures` item text. Keep raw syllabus wording in `canonicalCoverage` keys.
- `systemsBrief` is restricted to FAM flight events with dense NATOPS/system content. Do not add it anywhere else.
- Scaffolded or generated output is only a starting point for source harvesting. The final authored note should read like something a student could actually brief from.
- Flashcard authoring now lives in `FlashcardsByEvent.json`, where cards are grouped by event code and can optionally reference images from `Contents/FlashcardImages/`.
