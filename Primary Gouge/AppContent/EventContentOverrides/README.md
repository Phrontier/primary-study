# Event Content Overrides

Use one JSON file per event to hand-author event content without editing generated files.

## Workflow

1. Create or update `Primary Gouge/AppContent/EventContentOverrides/<EVENTCODE>.json`
2. Add or edit:
   - `title`
   - `summary`
   - `overview`
   - `studyNotes`
   - `flashcards`
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
  "flashcardDeckSummary": "Optional custom deck summary for this event.",
  "flashcards": [
    {
      "prompt": "What is the point of the blind cockpit check in FAM2101?",
      "answer": "It builds location memory and switch confidence so procedures are not just verbal.",
      "studyCategories": ["sims"],
      "tags": ["checklists"],
      "kind": "standard",
      "requiresVerbatim": false
    }
  ]
}
```

## Notes

- `StudyManifest.json` is generated. Do not hand-edit it.
- `EventOverrides.json` still exists for legacy compatibility, but new event authoring should go in this folder.
- Legacy `focusAreas` notes are still supported while older events are being migrated.
- Inline `flashcards` in an event file are merged into the main flashcard library automatically during manifest generation.
- If `eventCodes` is omitted on an inline flashcard, it defaults to the parent event code.
- If `id` is omitted on an inline flashcard, the builder generates one for you.
