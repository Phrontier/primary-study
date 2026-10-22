# Primary Gouge — Product brief

**Status:** Working brief — v1  
**Date:** October 14, 2026

This document is the source of truth for redesign intent. It records approved product priorities and constraints, while distinguishing ideas that still need visual exploration. It is not a finalized visual specification. Future references, decisions, and design-language documents should support this brief.

## Product and audience

Primary Gouge helps students currently in aviation training prepare for upcoming events, quickly access relevant study information, and understand what to expect from instructors. Flashcards are an integrated learning aid within that broader preparation experience.

The app should feel useful for recurring, everyday study—not merely like a collection of documents.

## Primary user tasks

1. Find an event and understand how to prepare for it.
2. Look up an instructor and review their scores and feedback.
3. Read discussion items or practice them through flashcards.

## Confirmed requirements and strengths to preserve

- Keep Events → Phase → Category → Event as the main browsing path. Additional shortcuts may be explored alongside it.
- Preserve event pages that begin with a brief overview and lead naturally into important preparation material.
- Preserve meaningful color, particularly review ratings and distinctions between tools or destinations.
- Preserve flashcards that visibly behave like physical cards, with an intuitive question-and-answer relationship when revealing the reverse side.
- Preserve the straightforward instructor browsing and review experience.
- Keep a welcoming introduction, visible streak, continue studying, question of the day, and access to EPs / Limits / N/W/C on Home.
- Prioritize helping returning students resume studying and prepare on Home.
- Home must scroll vertically, with no horizontally scrolling content.
- Support a continuous visual language across light and dark mode.

Preserving these features does not require preserving their current containers, size, or placement.

## Problems to address

- Repeated counters compete for attention without clearly helping users decide what to do.
- Labels such as “Due” may not explain what is due or why it matters in that context.
- Similar library destinations and counts can make the event hierarchy harder to interpret.
- Frequent cards, nested containers, badges, and borders flatten the hierarchy: too many elements look equally important.
- Home has useful ingredients but lacks a compelling composition and clear priority.
- Some color treatments feel decorative rather than meaningful.
- The current presentation relies heavily on text inside rounded containers, leaving limited visual variety.

These are design concerns and user hypotheses; they have not yet been validated through usability testing.

## Desired experience and visual character

The app should feel polished, colorful, approachable, and purposeful. Users should be able to distinguish destinations, actions, reference content, and study states at a glance.

Color should communicate identity, grouping, action, or status. It should retain enough presence to give the app personality.

Layouts should use typography, spacing, alignment, separators, and selective visual elements to organize information. Cards should have a clear purpose—especially for flashcards and discrete interactive content—rather than serve as the default wrapper around everything.

Dense reference pages should support comfortable reading. Event lists should support scanning. Instructor pages should make scores and feedback easy to interpret. These screen types should share a design language while using layouts suited to their tasks.

## Home priorities

Home should primarily help returning students **resume studying and prepare**. Its required content includes:

- A welcoming introduction and visible streak.
- A prominent way to continue studying.
- Question of the day.
- A clearly discoverable EPs / Limits / N/W/C shortcut.

The exact order, size, and treatment of these elements remain open for comparison in static previews. Recent destinations are a candidate addition if they provide useful access beyond a single resume action; they are not yet a committed feature.

The user favors exploring a prominent streak and daily study activity area, plus vertically stacked recent-material tiles with the last studied item highlighted first. The daily measure and exact layout remain undecided. A learner mascot is a future-iteration idea, outside the current redesign.

## Navigation and metrics

Keep the existing event hierarchy as the main browsing path. Explore shortcuts that reduce repeated navigation without making users relearn the structure.

A metric earns prominent placement only if users can understand it and act on it. For each existing counter, ask:

> What decision does this number help the student make here?

Counts that merely describe the content inventory should receive less emphasis or be omitted from that view. Review scheduling information should clearly identify the relevant flashcards and its associated action. Specific metric inclusion and placement remain exploratory.

## References and inspiration

Use selected references for specific qualities: information hierarchy, color, section composition, reading layout, or interaction behavior. Annotate what to borrow and what to avoid rather than treating an entire reference app as the target.

Brilliant and Memorize are potential references for vertically arranged education home screens, based on the user's preferences. Specific screens still need to be selected.

The user-supplied Alan Home screenshot is an additional reference for composition, layout, prominent daily activity, highlighted recent content, bottom navigation, and intentional color. Its role and boundaries are recorded in [references.md](references.md); it must not become the sole design inspiration.

Quizlet and Anki should not define the app's visual identity. Their individual interaction patterns can be considered when useful; their visual styles feel too generic and insufficiently colorful to the user.

Mobbin references are optional for custom event and study layouts. They may be more directly useful for familiar flows such as login, signup, and settings. A reference app does not need to match Primary Gouge's functionality to contribute a useful design idea.

## Decisions to explore through static previews

- Whether to expand continue studying into several recent destinations.
- Which shortcuts provide useful access alongside the event hierarchy.
- The order, prominence, and composition of Home content, including the reference shortcut.
- Which metrics to retain, clarify, demote, or omit, and where to place them.
- Where cards are useful and where open layouts, rows, or separators would improve hierarchy.
- Exact color treatments, typography, spacing, surfaces, borders, depth, icons, and other visual elements.

These are open decisions, not authorization to add features or change production code during exploration.

## Design exploration constraints

- Fast, inexpensive iteration with minimal token usage is a core workflow priority.
- Begin with simple static previews outside the production app.
- Compare a small number of meaningfully different options using identical real content and device dimensions.
- Keep the current design visible as a baseline.
- Review one screen at a time, then test the selected direction across other screen types.
- Make targeted revisions after selection rather than repeatedly reopening the whole design.
- Use a bounded reference set; avoid open-ended inspiration searches.
- Record approved visual examples and short decision notes.
- Defer production implementation and app-wide component changes until the direction is approved.
- Create reference, decision, and design-language documents when they have actual content, rather than establishing speculative rules in advance.

## Success criteria

The redesign succeeds when:

- The user prefers its appearance to the current app while recognizing the personality they wanted preserved.
- Students can identify the main action or destination on each screen.
- Event lists are easier to scan and reference content is comfortable to read.
- Color and metrics have understandable purposes.
- Fewer unnecessary containers improve hierarchy.
- The same visual language works across Home, events, instructors, reference reading, and flashcards in light and dark mode.
- Design decisions can be explored and reviewed through bounded, inexpensive iterations.

The flow is largely worth preserving; presentation and emphasis need exploration. Exact layouts will be resolved through visual comparisons rather than assumed in this brief.

## Approved visual foundation

Refined Home A1 is the approved starting direction: open greeting/activity, aligned equal-size metrics, highlighted last-studied destination, open supporting rows, a white question card, and a green reference shortcut. See [design-language.md](design-language.md) for reproducible rules and [decisions.md](decisions.md) for the reasons. Daily goals remain deferred; companion screens and dark mode require further review.

## Design selection status

The selected Home, Events root, category event list, Instructors root, event detail, instructor detail, and collapsible discussion-reading designs are locked. See the authoritative screen-selection table in [design-language.md](design-language.md). Remaining unreviewed surfaces and dark mode should extend this language; do not reopen approved layouts as part of routine implementation.

The refined flashcard deck overview, question side, and answer side (round 09) are also approved and locked. The design-language selection tables now cover ten light-mode screen targets.

Onboarding A, the reference-faithful blue Premium hybrid, and the first integrated blue-banner More/settings option are now selected. Consult the corresponding locked sections in `design-language.md` for their targets. Next validation is dark mode and larger text before native rollout.
