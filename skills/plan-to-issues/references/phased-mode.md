# Phased Mode

Treat each selected phase as one parent with independently deployable sub-issues. Use the phase's task-bearing section, not repeated overview tables, as the source of child items.

## Survey phases

Before asking which phases to create, search every phase's exact parent marker across all issue states and classify it:

- no exact match: not started;
- one open match: in progress, with verified closed/total child count;
- one closed match: done only when its explicit exit gate is satisfied;
- multiple matches or an unmarked possible duplicate: needs a decision.

Recommend all not-started and in-progress phases in plan order. Let the user narrow the selection. A supplied phase selector skips this recommendation but not marker and duplicate checks.

## Build each phase

- Use one parent per phase and one child per independently mergeable unit.
- Copy an explicit phase exit gate into the parent. Mark synthesized exit criteria as derived.
- Map a plan-defined priority legend when present; otherwise use existing repository priority labels only when the dependency order makes the priority clear.
- Reuse children only by exact item marker. Ask before mapping an unmarked legacy child.
- Process selected phases in order and re-survey the next phase after completing the previous one.

The approval summary must cover the complete selected phase set. Stop if a later phase exposes a new duplicate, closed-parent decision, or other mutation ambiguity not covered by that approval.
