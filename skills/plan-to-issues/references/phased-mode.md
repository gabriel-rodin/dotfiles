# Phased Mode

Treat each selected phase as one parent with independently deployable sub-issues. Use the phase's task-bearing section, not repeated overview tables, as the source of child items.

## Survey phases

Before asking which phases to create, look up every phase's exact parent marker in the authoritative all-state marker inventory and classify it:

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

## Use canonical bodies

Use this parent body shape:

```markdown
<!-- plan-to-issues:parent=<PARENT_KEY> -->
<!-- plan-to-issues:phase-content:start=<PARENT_KEY> -->

## Outcome
[Phase outcome and boundaries]

## Exit Criteria
- [ ] Verifiable phase-level result

## Dependencies
[Required earlier phases or `None`]

## Plan Document
[Verified permalink or plain local path]

<!-- plan-to-issues:phase-content:end=<PARENT_KEY> -->
```

Use this child body shape:

```markdown
<!-- plan-to-issues:item=<PARENT_KEY>:<ITEM_KEY> -->
<!-- plan-to-issues:issue-content:start=<PARENT_KEY>:<ITEM_KEY> -->

## Overview
[What will change and why]

## Scope
[Implementation scope, files or components, and constraints]

## Acceptance Criteria
- [ ] Required behavior is verified
- [ ] Relevant failure behavior is verified
- [ ] Relevant tests pass

## Dependencies
[Blocking issues, recommended ordering, or `None`]

## Plan Document
[Verified permalink or plain local path]

<!-- plan-to-issues:issue-content:end=<PARENT_KEY>:<ITEM_KEY> -->
```

Omit unsupported sections, but keep the markers unchanged. Reconcile only the matching generated block and preserve all text outside it.

For a non-native relationship fallback, put `<!-- plan-to-issues:fallback-link=<PARENT_KEY>:<ITEM_KEY>:parent -->` in the parent comment linking the child and `<!-- plan-to-issues:fallback-link=<PARENT_KEY>:<ITEM_KEY>:child -->` in the child comment linking the parent. Reuse or update an exact fallback marker; never add a second comment with the same marker.
