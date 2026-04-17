# Flashcards By Event

`FlashcardsByEvent.json` is the hand-edited source of truth for flashcards.

## Workflow

1. Edit `Primary Gouge/AppContent/FlashcardsByEvent.json`
2. Add any optional image files to `Contents/FlashcardImages/`
3. Regenerate the manifest:

```bash
swift Tools/BuildStudyManifest.swift
```

4. Build the app

## File Shape

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

- Putting a card under an event section automatically maps it to that event deck.
- Use `alsoIncludeInEvents` only when one card belongs in more than one event deck.
- `libraryCards` are optional cards that should live in the general flashcard library without belonging to a specific event deck.
- `image` paths are relative to `Contents/FlashcardImages/`.
- Flashcard images render on the answer side only.
- The build fails for duplicate IDs, unknown event codes, or missing image files.
