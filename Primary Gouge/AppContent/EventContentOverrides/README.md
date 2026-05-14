# Event Content Overrides

Use one JSON file per event to hand-author event content without editing generated files.

Flashcards are no longer authored in these event override files. They now live in `Primary Gouge/AppContent/FlashcardsByEvent.json`.

## Workflow

1. Create or update `Primary Gouge/AppContent/EventContentOverrides/<EVENTCODE>.json`
2. Add or edit:
   - `title`
   - `summary`
   - `overview`
   - `canonicalCoverage`
   - `studyNotes`
   Author the visible notes as a student-facing briefing aid, not a normalized extraction template.
3. Regenerate the manifest:

```bash
swift Tools/BuildStudyManifest.swift
```

4. Build the app.

## File shape

```json
{
  "code": "FAM2101",
  "title": "Cockpit Familiarization",
  "summary": "Short event summary shown in cards and lists.",
  "overview": "Longer event overview shown on the event page.",
  "canonicalCoverage": {
    "Before Exterior Inspection": ["Before Exterior Inspection"],
    "Engine Start (Auto)": ["Engine Start (Auto)"]
  },
  "primaryDocumentTitles": [
    "FAM 2101 Briefing guide 1542.166D"
  ],
  "studyNotes": {
    "headline": "Discussion items",
    "summary": "Optional short paragraph introducing the notes.",
    "sections": [
      {
        "title": "Checklist Challenge-Action-Response Format",
        "items": [
          {
            "text": "All checklists are run using challenge-action-response.",
            "children": [
              { "text": "Challenge: BAT switch" },
              { "text": "Action: Verify or move switch" },
              { "text": "Response: On" }
            ]
          },
          {
            "text": "For a required check, physically touch or visually verify the item before responding."
          }
        ]
      },
      {
        "title": "Required Procedures",
        "items": [
          { "text": "Before Exterior Inspection" },
          { "text": "Engine Start (Auto)" },
          { "text": "Before Landing Checklist" }
        ]
      }
    ]
  },
  "flashcardDeckTitle": "FAM2101 Discussion Item Flashcards",
  "flashcardDeckSummary": "Optional custom deck summary for this event."
}
```

See [DiscussionItemAuthoringRules.md](/Users/conwaybolt/Library/CloudStorage/OneDrive-Personal/Documents/Projects/Development/Primary%20Gouge/Primary%20Gouge/AppContent/EventContentOverrides/DiscussionItemAuthoringRules.md) for the canonical discussion-item authoring standard and validation rules.

## Notes

- `StudyManifest.json` is generated. Do not hand-edit it.
- `EventOverrides.json` still exists for legacy compatibility, but new event authoring should go in this folder.
- Legacy `focusAreas` notes are still supported while older events are being migrated.
- `canonicalCoverage` is required for FAM event overrides and should map each canonical syllabus discussion item to the authored section title or titles where it is substantively covered.
- Scaffolded or generated output is only a starting point for source harvesting. The final authored note should read like something a student could actually brief from.
- Flashcard authoring now lives in `FlashcardsByEvent.json`, where cards are grouped by event code and can optionally reference images from `Contents/FlashcardImages/`.
