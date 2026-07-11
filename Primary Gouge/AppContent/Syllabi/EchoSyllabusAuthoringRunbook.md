# Echo Syllabus Authoring Runbook

This directory contains the generated Echo syllabus overlay and its audit trail. Delta remains the shared content library; do not copy Delta overrides or flashcards into Echo merely because an event code changed.

## Source and generation

- Canonical source: local ignored `Pubs/1542.166E T-6B JPT Curriculum - Apr 2026.pdf`
- Technical authorities: the existing Contact, Instrument Navigation, Navigation, and Formation FTIs plus the same NATOPS, EP/N/W/C, limits, planning, and local references used by Delta
- Existing written gouge: event DOCX and briefing-guide files under `Contents/`

Generate and validate with:

```bash
swift Tools/BuildSyllabusEventReference.swift \
  "Pubs/1542.166E T-6B JPT Curriculum - Apr 2026.pdf" \
  "Primary Gouge/AppContent/Syllabi/EchoEventReference.json" echo
python3 Tools/BuildEchoTrack.py
```

The first command must produce 87 ordered FAM/I/N/F events. The second command fails when canonical events, discussion coverage, card IDs, titles/descriptions, Required Procedures, source sequence, solo/checkride classification, or track boundaries are invalid.

## Reuse policy

1. Reuse a complete Delta event only when the Echo discussion-item membership is equivalent.
2. When Echo redistributes a Delta event, import only sections and cards mapped to the applicable Echo items.
3. If one Delta section covered multiple items, give Echo separate presentations when the new syllabus benefits from the split.
4. Keep existing stable card IDs so mastery follows the knowledge across tracks.
5. Create an `echo-` card only when no existing card independently and accurately covers the Echo item.
6. EP, N/W/C, and limits cards remain canonical shared references; never paraphrase them into replacement cards.
7. Do not accept fuzzy similarity as authority. Event candidates and semantic aliases in `BuildEchoTrack.py` are reviewed authoring decisions.

## Required review

- Compare `EchoDeltaCrosswalk.json` with both syllabus references.
- Confirm each `new`, `explicit`, `alias`, or split presentation against the controlling source.
- Inspect `EchoSyllabusAuditReport.json`; all issue arrays must be empty.
- Review titles, summaries, overviews, notes, Required Procedures, deck membership, source documents, and event ordering in the app.
- Run build-for-testing and the unit tests after every meaningful authoring change.

## Current baseline

- 87 canonical Echo events
- 462 canonical Echo discussion items; current baseline reuses 427 and authors 35 new item presentations/cards
- Ground School events: FAM1301 and F1201
- No Echo Capstone phase
- Solo events: FAM4501 and FAM4801
- Checkrides: FAM4490, FAM4790, I4490, and F4290
- Delta event IDs remain unchanged; Echo event IDs are track-prefixed
- Flashcard progress is shared; event progress is track-specific
