# Phased Mode

Treat each selected parent unit as one parent with independently deployable sub-issues. A parent unit is normally a phase. When a plan declares an authoritative delivery partition, release tranche, or MVP/v1 split that cuts across phases, make each non-empty partition/phase slice its own parent unit. Never combine scopes separated by an explicit delivery gate. Use task-bearing sections for child details while honoring any table or section the plan explicitly declares authoritative for membership.

## Build the parent map

Build the complete parent map before surveying or creating issues:

1. Identify explicit task-bearing phases.
2. Identify delivery partitions only when the plan makes their membership or sequencing authoritative.
3. Assign every actionable task or explicitly split task scope to exactly one parent unit.
4. Order partitioned parent units by delivery partition, then by phase order. Keep unpartitioned phases in plan order.
5. Stop when a task scope is missing, assigned twice, or conflicts with an authoritative gate. Do not silently choose between contradictory memberships.

If one task ID has separately deliverable scopes in different partitions, keep the task ID visible in both issues and use the partition/phase parent to distinguish them. If multiple scopes land in the same parent, assign concise stable scope IDs for item-key derivation. A selector naming a partition selects all of its parent units; a selector naming a phase that has multiple partition slices is ambiguous unless the user names the exact partition/phase slice.

## Survey parent units

Before asking which parent units to create, look up every parent unit's exact parent marker in the authoritative all-state marker inventory and classify it:

- no exact match: not started;
- one open match: in progress, with verified closed/total child count;
- one closed match: done only when its explicit exit gate is satisfied;
- multiple matches or an unmarked possible duplicate: needs a decision.

Recommend all eligible not-started and in-progress parent units in parent-map order. Mark a later partition deferred when the plan says it cannot begin before an earlier partition's exit gate; do not recommend it prematurely. Let the user narrow the selection. A supplied selector skips this recommendation but not parent-map, marker, gate, and duplicate checks.

## Build each parent unit

- Use one parent per parent unit and one child per independently mergeable unit.
- Copy the explicit exit gate applicable to that parent unit. When a phase gate spans several partitions, include only criteria attributable to the selected slice and mark any derived slice-level criteria as derived.
- Map a plan-defined priority legend when present; otherwise use existing repository priority labels only when the dependency order makes the priority clear.
- Reuse children only by exact item marker. Ask before mapping an unmarked legacy child.
- Distinguish hard blockers from recommended ordering. Create native `blocked by` relationships only for hard blockers. Keep recommendations in body text only.
- Link parent-unit gates between parent issues and task dependencies between child issues. A cross-unit task dependency points to the exact child, not merely its parent.
- Process selected parent units in order and re-survey the next parent unit after completing the previous one.

The approval summary must cover the complete selected parent-unit set and its hard-dependency graph. Stop if a later parent unit exposes a new duplicate, closed-parent decision, gate conflict, unresolved blocker, or other mutation ambiguity not covered by that approval.

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
[Hard-blocking parent issues and recommended ordering, clearly distinguished, or `None`]

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
[Hard-blocking task issues and recommended ordering, clearly distinguished, or `None`]

## Plan Document
[Verified permalink or plain local path]

<!-- plan-to-issues:issue-content:end=<PARENT_KEY>:<ITEM_KEY> -->
```

Omit unsupported sections, but keep the markers unchanged. Reconcile only the matching generated block and preserve all text outside it.

For a non-native relationship fallback, put `<!-- plan-to-issues:fallback-link=<PARENT_KEY>:<ITEM_KEY>:parent -->` in the parent comment linking the child and `<!-- plan-to-issues:fallback-link=<PARENT_KEY>:<ITEM_KEY>:child -->` in the child comment linking the parent. Reuse or update an exact fallback marker; never add a second comment with the same marker.
