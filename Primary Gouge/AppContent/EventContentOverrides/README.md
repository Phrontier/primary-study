# Event Content Overrides

Use one JSON file per event to hand-author event content without editing generated files.

Flashcards are no longer authored in these event override files. They now live in `Primary Gouge/AppContent/FlashcardsByEvent.json`.

## Workflow

1. Create or update `Primary Gouge/AppContent/EventContentOverrides/<EVENTCODE>.json`
2. Add or edit:
   - `title`
   - `summary`
   - `overview`
   - `studyNotes`
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

## Notes

- `StudyManifest.json` is generated. Do not hand-edit it.
- `EventOverrides.json` still exists for legacy compatibility, but new event authoring should go in this folder.
- Legacy `focusAreas` notes are still supported while older events are being migrated.
- Flashcard authoring now lives in `FlashcardsByEvent.json`, where cards are grouped by event code and can optionally reference images from `Contents/FlashcardImages/`.
