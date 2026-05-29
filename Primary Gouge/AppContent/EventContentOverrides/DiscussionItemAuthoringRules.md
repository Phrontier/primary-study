# Discussion Item Authoring Rules

These rules are meant to produce student-facing briefing notes, not mechanical source extractions. The app should feel like a strong ready-room study aid: easy to scan, easy to brief from, and complete enough that a student can walk into the event prepared.

These rules apply to every syllabus category that receives authored discussion-item overrides: Contacts/FAM, Instruments, VNAV, Formation, and Capstone. Category-specific tooling may still have category-specific filenames or validation coverage, but the authoring standard is shared unless this document says otherwise.

## Source precedence

Use this hierarchy for every event:

1. `Primary Gouge/AppContent/SyllabusEventReference.json`
   This is the canonical source for required discussion-item membership and required-procedure wording.
2. Category technical authority
   Use the controlling FTI, NATOPS, CNAF, SOP, IFG, XML EP/N/W/C reference, or other official publication that governs the procedure, limits, definitions, speeds, altitudes, setup, standards, and safety framing.
3. Local event documents in `Contents/`
   Use local event `.docx`, briefing guides, scenarios, grade sheets, worksheets, jet logs, and route packets for sortie emphasis, brief flow, and clearer student-facing explanations.
4. Supplemental official references
   Use additional official references only when they clarify or complete the event without contradicting the category technical authority.

If sources conflict:

- preserve the syllabus membership from `SyllabusEventReference.json`
- use the category technical authority for procedure, numbers, limits, definitions, and decision logic
- keep local event material when it explains the same technically correct idea more clearly
- keep local sortie-emphasis points when they do not contradict the technical authority
- if the conflict cannot be reconciled cleanly, stop and surface it before authoring the final event note

## Primary authoring goal

Write each event as a briefing note a flight student could actually use the night before the event.

That means:

- organize around event-meaningful sections, not mechanical extraction buckets
- prefer short declarative bullets over long paragraphs
- keep enough detail to help the student pass, but not so much that the page becomes a dump
- select and condense source detail instead of copying every line
- treat duplication as a defect

Readable notes beat exhaustive notes once canonical coverage is satisfied, but readability does not permit changing source-backed procedures, numbers, limits, or decision logic.

The voice should be accurate and textbook-style, not conversational instructor banter.

Avoid phrases such as:

- `the whole game is`
- `know the limit before you need it`
- `cleanest pure roll in the block`
- broad block talk like `in this block` when a specific maneuver, system, procedure, planning task, or emergency decision is what actually matters

Before drafting any event, identify the dominant event purpose.

- confirm what the event is primarily about before writing the title, overview, summary, or `studyNotes.summary`
- if the event is maneuver-heavy, lead with the maneuver block, not the supporting knowledge items
- if the event is planning-heavy, lead with the planning product and decision chain, not a pile of references
- if the event is emergency-heavy, lead with recognition, immediate action, N/W/Cs, and branch logic

## Required event-note shape

Every authored override should include:

- `headline: "Discussion Items"`
- a concise non-empty `studyNotes.summary`
- top-level sections that reflect how a student would naturally brief the event
- a final `Required Procedures` section

Visible note headlines, section titles, and the display text inside the final `Required Procedures` section should use standard display title case. Older authored events may still use legacy casing until they are intentionally polished, but new or reopened events should use the preferred capitalization.

The `Required Procedures` section must:

- preserve exact canonical syllabus membership and meaning
- preserve syllabus order
- display each item with standardized capitalization
- include every canonical discussion item for the event

Keep exact raw syllabus wording in `canonicalCoverage` keys so traceability remains stable even when visible display text is title-cased.

## Systems-brief policy

`systemsBrief` is allowed only for FAM flight events with dense NATOPS/system content that deserves a separate memorization lane.

Do not author `systemsBrief` for:

- Instruments
- VNAV
- Formation
- Capstone
- FAM sims
- any other non-FAM-flight event

For allowed FAM flight events, `systemsBrief` should:

- keep the event `Discussion Items` section focused on what the student must explain, recognize, and do in the event
- carry the dense subsystem, flow-path, limit, cockpit-indication, or failure-cue memorization separately
- use the FTI and NATOPS-style local systems brief as the technical backbone
- help the student succeed in the brief, not just restate component names

Good FAM-flight systems-brief structure usually includes:

- how to brief the system successfully
- system purpose and major subsystems
- flow path or control logic
- cockpit indications, limits, and failure cues
- the traps that change the operational answer

## Section design

Default to one visible section per canonical syllabus discussion item.

Allowed exceptions:

- a previously approved locked baseline event may keep an older grouped structure until it is intentionally reopened
- a single canonical item may split into multiple visible sections only when the item itself bundles clearly distinct subjects and the split is declared in authoring config or documented in the event tracker

Inside a single item section, it is fine to break the content into smaller study chunks when that helps readability.
Examples:

- `Contact Unusual Attitudes` can break into `Nose-High`, `Nose-Low`, and `Inverted`
- `OCF Recovery and Airborne Damaged Aircraft` can break into recognition, recovery, and damaged-aircraft priorities
- `Lost communications (FIH)` can break into VMC, route, altitude, clearance-limit, and recontact logic
- `flight planning (submit a completed DD-1801 and jet log...)` can break into planning products, route/fuel logic, and check-flight traps

Do not combine multiple canonical discussion items into one visible section just because they feel related.
If the syllabus lists separate maneuvers, procedures, planning tasks, or publications, each should get its own section by default.
If one canonical item itself contains two different subjects, split that one item only when the note becomes materially clearer and each visible section still maps back to that same canonical item.

Good sections usually:

- use titles that describe what the student is actually briefing
- lead with one short orienting bullet, then a few high-value bullets
- use child bullets only when they genuinely improve scanability

Examples of good intra-item splitting:

- break an AOA approach into downwind transition, 180/final, and N/W/C reminders
- break a maneuver into entry setup, execution, maneuver-complete cues, and common errors
- break an EP-driven item into recognition, actions, decision logic, and N/W/Cs
- break an instrument approach into setup, approach flow, missed-approach logic, and common errors
- break a planning item into required products, source checks, fuel/weather/minimums logic, and day-of verification

Avoid:

- empty framework labels
- repeated coaching phrases across many sections
- restating the same fact in multiple sections unless the repetition adds real clarity
- consolidating distinct syllabus items into one catch-all section

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
- if the source confidence is weak for a technical item, mark it `manualOnly` in config or record it in the tracker and hand-author it instead of letting a generator improvise

## Canonical coverage

Every authored discussion-item override must include `canonicalCoverage`.

Rules:

- map every canonical syllabus discussion item to the section title or titles where it is substantively covered
- section titles referenced in `canonicalCoverage` must actually exist in `studyNotes.sections`
- if a section title exactly matches the canonical item, map it directly to itself
- if one canonical item is intentionally split across multiple visible sections, declare or document that split and map the canonical item to every visible section it owns
- do not use `Required Procedures` as the only coverage location unless that section truly contains the substantive content
- category-specific generation config may drive grouped section intent and locked-baseline behavior, but `canonicalCoverage` remains the traceability source in the event override

`canonicalCoverage` exists for traceability and validation. It should not drive the visible structure of the notes.

## Location-neutral rule

The app should teach transferable knowledge, not lock the student to one local area.

For local course rules, departures, arrivals, field operations, route names, reporting points, frequencies, and named landmarks:

- keep the operational purpose
- keep the altitude, speed, communication, briefing, and verification logic when it is generally useful
- strip proper nouns, route names, reporting points, local frequencies, and runway-specific local flows unless they are inherently generic or required by the event itself
- tell the student what must still be confirmed from the current local SOP, IFG, route packet, or day-of brief

Examples of what to avoid in reusable notes:

- `Waldron`
- `Rusty departure`
- local reporting-point names
- one-base runway or tower flow treated as universal knowledge

## Emergency-procedure rule

If a discussion item is an emergency procedure or contains emergency-procedure material:

- include both the procedure content and the associated `N/W/Cs`
- preserve source-backed `WARNING`, `CAUTION`, and `NOTE` material when it matters to decision making or crew safety
- integrate that material into readable bullets instead of turning the section into a verbatim XML mirror
- prefer canonical EP and N/W/C wording when the XML reference already provides the safety-critical phrasing
- for cumulative items such as `any emergency procedure`, frame the note as a review method and expected decision tree, not as an invented exhaustive EP list unless the event source clearly defines the list

## Anti-hallucination rule

- Do not invent unsupported numbers, limits, procedures, minima, weather rules, fuel rules, routes, or local requirements.
- Do not replace technical detail with simplified paraphrase if that paraphrase changes the procedure, numbers, or decision logic.
- If a source is thin, say so conservatively instead of fabricating precision.
- It is acceptable to add instructional framing, but factual specifics must trace back to a source.

## Validation expectations

Authored discussion-item overrides should be able to pass these checks as validation is generalized across categories:

- authored notes present for every canonical event in the active category
- correct `headline`
- non-empty `studyNotes.summary`
- no `systemsBrief` except on FAM flight events where it is intentionally required
- `systemsBrief.headline == "Systems Brief"` when used on an allowed FAM flight event
- title-cased `Required Procedures` display text in canonical order
- complete `canonicalCoverage`
- valid referenced section titles
- `N/W/Cs` coverage for EP items
- maneuver sections that include entry-setup framing and maneuver-complete cues
- recovery sections that keep normal recovery flow separate from eject or unrecoverable-aircraft logic
- manual-only technical sections that do not look autogenerated
- event emphasis alignment between the event title, overview, summaries, and actual event purpose

Current build enforcement may still be category-specific until the validation tooling is generalized. It may also accept legacy heading capitalization during migration, but the preferred standard in this document is the target for all new or reopened authored events.
