# Discussion Item Authoring Rules

These rules are meant to produce student-facing briefing notes, not mechanical source extractions. The app should feel like a strong ready-room study aid: easy to scan, easy to brief from, and complete enough that a student can walk into the event prepared.

## Source precedence

1. `Primary Gouge/AppContent/SyllabusEventReference.json`
   This is the canonical source for required discussion-item membership and required-procedure wording.
2. `Contact FTI.pdf`
   This is the technical authority for procedures, definitions, limits, speeds, altitudes, maneuver setup, maneuver-complete criteria, and safety framing across contact events.
3. Local event gouge in `Contents/1. FAM (Contacts)`
   This is the readability and event-flow layer. Use it for sortie emphasis, how the event is commonly briefed, and clearer explanations that make technically correct material easier for a student to absorb.

If sources conflict:

- preserve the syllabus membership from `SyllabusEventReference.json`
- use the FTI for technical procedure, numbers, and definitions
- keep the local gouge when it explains the same technically correct idea more clearly
- keep local sortie-emphasis points when they do not contradict the FTI
- if the conflict cannot be reconciled cleanly, stop and surface it before authoring the final event note

## Primary authoring goal

Write each event as a briefing note a flight student could actually use the night before the event.

That means:

- organize around event-meaningful sections, not mechanical extraction buckets
- prefer short declarative bullets over long paragraphs
- keep enough detail to help the student pass, but not so much that the page becomes a dump
- select and condense source detail instead of copying every line
- treat duplication as a defect

Readable notes beat exhaustive notes once canonical coverage is satisfied, but readability does not permit changing technically correct FTI guidance.

The voice should be accurate and textbook-style, not conversational instructor banter.

Avoid phrases such as:

- `the whole game is`
- `know the limit before you need it`
- `cleanest pure roll in the block`
- broad block talk like `in this block` when a specific maneuver, system, or procedure is what actually matters

Before drafting any event, identify the dominant event purpose.

- confirm what the sortie is primarily about before writing the title, overview, summary, or `studyNotes.summary`
- if the event is maneuver-heavy, lead with the maneuver block, not the supporting knowledge items
- use supporting items like AOA, HUD, or unusual attitudes to explain how they help the primary event purpose, not to redefine the event

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

Default to one visible section per canonical syllabus discussion item.

Allowed exception:

- a previously approved locked baseline event may keep an older grouped structure until it is intentionally reopened
- a single canonical item may split into multiple visible sections only when the item itself bundles clearly distinct subjects and the split is declared in authoring config

Inside a single item section, it is fine to break the content into smaller study chunks when that helps readability.
Examples:

- `Contact Unusual Attitudes` can break into `Nose-High`, `Nose-Low`, and `Inverted`
- `OCF Recovery and Airborne Damaged Aircraft` can break into recognition, recovery, and damaged-aircraft priorities

Do not combine multiple canonical discussion items into one visible section just because they feel related.
If the syllabus lists separate maneuvers, each maneuver should get its own section.
If one canonical item itself contains two different subjects, split that one item only when the note becomes materially clearer and each visible section still maps back to that same canonical item.

Good sections usually:

- use titles that describe what the student is actually briefing
- lead with one short orienting bullet, then a few high-value bullets
- use child bullets only when they genuinely improve scanability

Examples of good intra-item splitting:

- break an AOA approach into downwind transition, 180/final, and N/W/C reminders
- break a maneuver into entry setup, execution, maneuver-complete cues, and common errors
- break an EP-driven item into recognition, actions, decision logic, and N/W/Cs

Avoid:

- empty framework labels
- repeated coaching phrases across many sections
- restating the same fact in multiple sections unless the repetition adds real clarity
- consolidating distinct syllabus maneuvers into one catch-all section

## Maneuver-event checklist

For any maneuver-heavy event:

- manually confirm the event emphasis in the title, overview, summary, and `studyNotes.summary`
- every maneuver section must include:
  - a short orienting lead
  - `Entry setup`
  - `Execution`
  - `Maneuver complete when`
  - `Common errors` or `N/W/C focus` when relevant
- `Entry setup` should capture the student-brief details that usually drive grading:
  - PCL / power setting
  - entry airspeed
  - entry altitude when relevant
  - section line / heading / clear-area / checklist setup when relevant
- keep normal recovery flow separate from emergency or ejection boundaries
- if the source confidence is weak for a systems item, mark it `manualOnly` in config and hand-author it instead of letting the generator improvise

## Canonical coverage

Every authored override should include `canonicalCoverage`.

Rules:

- map every canonical syllabus discussion item to the section title or titles where it is substantively covered
- section titles referenced in `canonicalCoverage` must actually exist in `studyNotes.sections`
- if a section title exactly matches the canonical item, map it directly to itself
- if one canonical item is intentionally split across multiple visible sections, declare that split in config and map the canonical item to every visible section it owns
- do not use `Required Procedures` as the only coverage location unless that section truly contains the substantive content
- for FAM generation, grouped section intent and locked-baseline behavior live in `FAMDiscussionAuthoringConfig.json`

`canonicalCoverage` exists for traceability and validation. It should not drive the visible structure of the notes.

## Location-neutral rule

The app should teach transferable knowledge, not lock the student to one local area.

For local course rules, departures, arrivals, and named landmarks:

- keep the operational purpose
- keep the altitude, speed, communication, and briefing logic when it is generally useful
- strip proper nouns, route names, reporting points, local frequencies, and runway-specific local flows unless they are inherently generic
- tell the student what must still be confirmed from the current local SOP or day-of brief

Examples of what to avoid in reusable notes:

- `Waldron`
- `Rusty departure`
- local reporting-point names
- one-base runway or tower flow treated as universal knowledge

## Emergency-procedure rule

If a discussion item is an emergency procedure:

- include both the procedure content and the associated `N/W/Cs`
- preserve source-backed `WARNING`, `CAUTION`, and `NOTE` material when it matters to decision making or crew safety
- integrate that material into readable bullets instead of turning the section into a verbatim XML mirror
- prefer canonical EP and N/W/C wording when the XML reference already provides the safety-critical phrasing

## Anti-hallucination rule

- Do not invent unsupported numbers, limits, or procedures.
- Do not replace FTI technical detail with simplified paraphrase if that paraphrase changes the procedure, numbers, or decision logic.
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
- maneuver sections that are missing entry-setup framing or maneuver-complete cues
- recovery sections that incorrectly mix eject logic into the normal recovery flow
- manual-only systems sections that still look autogenerated
- event emphasis drift between the event title / overview / summaries and the actual sortie purpose
