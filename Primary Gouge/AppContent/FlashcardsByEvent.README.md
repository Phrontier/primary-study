# Flashcards By Event Legacy Source

`FlashcardsByEvent.json` is retained as legacy reference material only.

The active source of truth is now the flat master library:

- `Primary Gouge/AppContent/FlashcardLibrary.json`
- `Primary Gouge/AppContent/FlashcardAuthoringRules.md`
- `Primary Gouge/AppContent/FlashcardAuthoringRunbook.md`
- `Primary Gouge/AppContent/FlashcardAuthoringProgress.md`

Do not copy cards from this file forward automatically. Use it only as a historical reference while authoring cards from the completed discussion-item overrides.

## Workflow

1. Edit `Primary Gouge/AppContent/FlashcardLibrary.json`
2. Add any optional image files to `Contents/FlashcardImages/`
3. Regenerate the manifest:

```bash
swift Tools/BuildStudyManifest.swift
```

4. Build the app

## Legacy File Shape

```json
{
  "events": {
    "FAM3102": {
      "deckTitle": "FAM3102 Discussion Item Flashcards",
      "deckSummary": "Optional custom deck summary.",
      "cards": [
        {
          "prompt": "What is the purpose of the break?",
          "answer": "It sets up spacing, energy, and configuration for a stable pattern.",
          "tags": ["maneuvers"],
          "studyCategories": ["sims"],
          "alsoIncludeInEvents": ["FAM4102"],
          "image": "pattern/break-example.jpg"
        }
      ]
    }
  },
  "libraryCards": [
    {
      "prompt": "Abort Start Procedure",
      "answer": "1. PCL - OFF or STARTER switch - AUTO/RESET",
      "tags": ["ep"],
      "kind": "ep"
    }
  ]
}
```

## Notes

- The manifest builder no longer reads this grouped file.
- Legacy event aliases should map to canonical event codes in the flat source.
- Flashcard images still render on the answer side only when referenced by the flat source.
