# Discussion Item Authoring Rules

These rules are meant to produce student-facing briefing notes, not mechanical source extractions. The app should feel like a strong ready-room study aid: easy to scan, easy to brief from, and complete enough that a student can walk into the event prepared.

## Source precedence

1. `Primary Gouge/AppContent/SyllabusEventReference.json`
   This is the canonical source for required discussion-item membership and required-procedure wording.
2. Local event gouge in `Contents/1. FAM (Contacts)`
   This is the primary source for event flow, local emphasis, numbers, and maneuver detail.
3. `Contact FTI.pdf`
   Use this to fill gaps when local gouge is thin, missing, or obviously incomplete.

If sources conflict, preserve the syllabus membership and prefer the local event gouge unless it is clearly wrong.

## Primary authoring goal

Write each event as a briefing note a flight student could actually use the night before the event.

That means:

- organize around event-meaningful sections, not mechanical extraction buckets
- prefer short declarative bullets over long paragraphs
- keep enough detail to help the student pass, but not so much that the page becomes a dump
- select and condense source detail instead of copying every line
- treat duplication as a defect

Readable notes beat exhaustive notes once canonical coverage is satisfied.

## Required event-note shape

Every authored override should include:

- `headline: "Discussion items"`
- a concise non-empty `studyNotes.summary`
- top-level sections that reflect how a student would naturally brief the event
- a final `Required Procedures` section

The `Required Procedures` section must:

- use exact canonical syllabus wording
- preserve syllabus order
- include every canonical discussion item for the event

## Section design

Top-level sections do not need to mirror syllabus item names one-for-one.

Good sections usually:

- combine related items when that makes studying easier
- use titles that describe what the student is actually briefing
- lead with one short orienting bullet, then a few high-value bullets
- use child bullets only when they genuinely improve scanability

Examples of good grouping:

- combine abort logic with maximum braking
- combine runway departure with emergency ground egress
- combine related pattern adjustments under one crosswind section

Avoid:

- empty framework labels
- repeated coaching phrases across many sections
- restating the same fact in multiple sections unless the repetition adds real clarity

## Canonical coverage

Every authored override should include `canonicalCoverage`.

Rules:

- map every canonical syllabus discussion item to the section title or titles where it is substantively covered
- section titles referenced in `canonicalCoverage` must actually exist in `studyNotes.sections`
- if a section title exactly matches the canonical item, map it directly to itself
- do not use `Required Procedures` as the only coverage location unless that section truly contains the substantive content
- for FAM generation, grouped section intent and locked-baseline behavior live in `FAMDiscussionAuthoringConfig.json`

`canonicalCoverage` exists for traceability and validation. It should not drive the visible structure of the notes.

## Emergency-procedure rule

If a discussion item is an emergency procedure:

- include both the procedure content and the associated `N/W/Cs`
- preserve source-backed `WARNING`, `CAUTION`, and `NOTE` material when it matters to decision making or crew safety
- integrate that material into readable bullets instead of turning the section into a verbatim XML mirror
- prefer canonical EP and N/W/C wording when the XML reference already provides the safety-critical phrasing

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
