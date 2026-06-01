# Flashcard Authoring Rules

These rules govern the flat master flashcard source at `Primary Gouge/AppContent/FlashcardLibrary.json`.

## Source Precedence

Use the completed discussion-item override as the primary source for event flashcards:

1. `Primary Gouge/AppContent/EventContentOverrides/<EVENT>.json`
2. `Primary Gouge/AppContent/SyllabusEventReference.json`
3. The category technical authority and local event documents already cited by the completed discussion item
4. XML reference cards for EPs, N/W/Cs, and limits

Do not invent numbers, procedures, limits, minima, weather rules, local rules, or emergency decision logic. If the discussion item is thin or ambiguous, stop and record the source gap in `FlashcardAuthoringProgress.md`.

## Card Shape

Flashcards should test useful recall, not isolated trivia.

- Ask for a complete usable flow when the subject is a procedure.
- Do not create cards like "What is step 3 of the abort EP?"
- Split dense discussion items only when each card is still independently useful.
- Keep normal answers concise, usually 2-5 bullets.
- Avoid multi-paragraph answers unless the card is explicitly a verbatim reference card.
- Do not duplicate a canonical EP/N/W/C or limit card with paraphrased wording.

## Required Coverage

Every canonical discussion item for an authored event must be covered by one or more flashcards through `eventCoverage`.

Use exact canonical wording from `SyllabusEventReference.json` inside `eventCoverage.discussionItems`. The visible prompt may use better flashcard phrasing.

When a syllabus item is itself a canonical EP, the XML EP card and companion N/W/C card may satisfy coverage. Event-specific procedure context may still get an authored card when it adds formation, instrument, planning, or sortie logic.

## Verbatim References

EPs, N/W/Cs, and limits are generated from XML and are not authored manually in `FlashcardLibrary.json`.

- EP cards keep `ep` tag and `kind: ep`.
- N/W/C cards keep `nwc` tag.
- Limit cards keep `limits` tag.
- Reference card prompts are display-capitalized by the manifest builder.
- Reference answers remain verbatim from XML.

## Tags

Authored cards may use only this small controlled tag set:

- `maneuvers`
- `procedures`
- `systems`
- `planning`

The manifest builder automatically adds event code, category, event kind, and `discussion-item` tags from `eventCoverage`.

## Quality Bar

Before marking an event complete:

- no card has `Answer pending generation.`
- each card has a stable explicit `id`
- each card maps to the correct canonical discussion item
- procedure answers include the full useful flow
- EP/N/W/C/limits wording comes from XML, not paraphrase
- deck size is large enough to cover the event but small enough to study in one sitting
