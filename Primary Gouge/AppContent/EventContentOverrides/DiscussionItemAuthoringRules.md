# Discussion Item Authoring Rules

These rules turn event discussion-item authoring into a reusable system instead of a one-off content pass.

## Source precedence

1. `Primary Gouge/AppContent/SyllabusEventReference.json`
   This is the canonical source for required discussion-item membership and required-procedure wording.
2. Local event gouge in `Contents/1. FAM (Contacts)`
   This is the primary content source for event-specific detail, flow, and training emphasis.
3. `Contact FTI.pdf`
   Use this only when the local gouge is thin, missing, or obviously incomplete.

If the sources conflict, preserve the syllabus membership and prefer the local event gouge unless it is clearly wrong.

## Required event-note shape

Every authored event override should include:

- `headline: "Discussion items"`
- a concise non-empty `studyNotes.summary`
- flexible top-level sections when they help the event teach well
- a final `Required Procedures` section

The `Required Procedures` section must:

- use exact canonical syllabus wording
- preserve syllabus order
- include every canonical discussion item for the event

## Canonical coverage

Every authored override should include `canonicalCoverage`.

Rules:

- map every canonical syllabus discussion item to the section title or titles where it is substantively covered
- section titles referenced in `canonicalCoverage` must actually exist in `studyNotes.sections`
- if a section title exactly matches the canonical item, map it directly to itself
- do not use `Required Procedures` as the only coverage location unless the section truly contains the substantive content

## Standard inner structure

Top-level section grouping can vary, but the internal teaching shape should stay consistent.

For knowledge items:

- `Why it matters`
- `Key knowledge`
- `Application`
- `Common errors / grading traps`

For maneuvers or procedures:

- `Purpose`
- `Setup / entry`
- `Execution`
- `Standards / numbers`
- `Common errors / grading traps`

For emergency procedures:

- `Recognition / indications`
- `Immediate actions / procedure`
- `Decision logic`
- `N/W/Cs`

## Emergency-procedure rule

If a discussion item is an emergency procedure:

- include both the procedure content and the associated `N/W/Cs`
- preserve source-backed `WARNING`, `CAUTION`, and `NOTE` material when available
- prefer canonical EP and N/W/C wording when the XML reference already provides it

## Anti-hallucination rule

- Do not invent unsupported numbers, limits, or procedures.
- If a source is thin, say so conservatively instead of fabricating precision.
- It is acceptable to add instructional framing, but factual specifics must trace back to a source.

## Validation expectations

The build validates FAM overrides for:

- authored notes present for every canonical FAM event
- correct `headline`
- non-empty `studyNotes.summary`
- exact `Required Procedures`
- complete `canonicalCoverage`
- valid referenced section titles
- `N/W/Cs` coverage for EP items
