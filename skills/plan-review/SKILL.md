---
name: plan-review
description: "Review Markdown implementation plans for material blockers, contradictions, technical, data, security, operational, testing, and implementation-readiness gaps. Use when a user asks to audit, red-team, validate, or review a new or revised implementation plan before development."
disable-model-invocation: true
argument-hint: "[relative-plan-file-path]"
---

# Plan Review

Perform a complete, evidence-based review of a Markdown implementation plan. The goal is to
identify issues that could materially affect implementation, correctness, security,
maintainability, delivery, or validation—not to maximize the number of observations.

## Plan input

Use `$ARGUMENTS` as the plan source when the skill is invoked with an argument.

- Resolve a relative path from the current workspace and verify it is a regular Markdown file
  before reading it.
- Read the entire referenced file before forming conclusions. If the path does not exist or is
  not a Markdown file, stop and ask for a valid path; do not silently review a different plan.
- If no argument is supplied, use a plan path explicitly provided in the user's message. If the
  user supplied the plan contents directly, review those contents. If no plan source is available,
  ask for one.
- Treat the argument as a path, not as an inline plan description. Quote paths containing spaces
  when invoking the skill.

The top-level reviewer must read the complete plan before forming the overall conclusion. A
delegated leaf reviewer may receive only the raw sections and repository context needed for its
assigned scope; it must not issue an overall verdict or claim that all review passes were completed.

## Review contract

- Read the entire plan before forming conclusions. Do not stop after the first findings.
- Inspect referenced local files, repository instructions, schemas, mockups, and source code when
  they are necessary to verify a claim. Distinguish what the plan states from what the repository
  actually contains.
- Treat the plan's explicit requirements and acceptance criteria as authoritative unless they are
  contradictory, infeasible, or unsafe.
- Report only findings with meaningful impact: incorrect behavior, implementation blockage,
  data loss/corruption, realistic security risk, substantial rework, missing requirements,
  deployment failure, important validation gaps, or a significant undocumented decision.
- Do not report cosmetic preferences, minor wording, speculative edge cases, premature
  optimization, unnecessary abstractions, or issues already adequately handled by the plan.
- Separate confirmed findings from assumptions and open questions. Cite exact sections, task IDs,
  files, commands, or observed behavior whenever possible.
- Never claim absolute completeness. State that all defined passes were completed and whether any
  additional material issues were identified.

## Complexity and sub-agents

Classify the plan before reviewing:

- **Low:** localized change, few dependencies, no material migration/integration/security risk.
  Use 0 sub-agents.
- **Moderate:** multiple components, API/database changes, several dependencies, or non-trivial
  failure and validation requirements. Use 1–2 sub-agents when they add distinct coverage.
- **High:** multiple services, complex migrations, auth, external integrations, concurrency,
  transactions, or backward-compatibility risk. Use 2–4 sub-agents with distinct scopes.
- **Exceptional:** broad cross-system migration or major production/security/compliance impact.
  Use at most 5, only with clearly independent responsibilities.

The top-level reviewer owns complexity classification, delegation, consolidation, and the final
response. The skill is explicitly invoked as a review task, so sub-agent use does not require a
separate confirmation. After classifying the plan, launch the recommended number when delegation
is available. Give each agent a distinct scope and the minimum raw plan/repository context needed
for that scope. Recommended scopes for a High plan are: data/query and transaction behavior,
state/durability and recovery, and delivery/testing/CI. Add a security or requirements scope only
when the plan warrants it.

Every delegated reviewer is a leaf reviewer. The parent must explicitly state this in the delegated
prompt. A leaf reviewer must not spawn, resume, or delegate to descendants; must not reclassify the
whole plan; must review only its assigned scope; and must return concise evidence-backed findings
to the parent rather than a final overall report. If a leaf receives the skill path and plan path,
these leaf rules still take precedence over the normal top-level orchestration rules.

When the assigned scope can be reviewed from excerpts, the parent must pass those raw excerpts and
the minimum referenced files instead of asking the leaf to invoke the full top-level review against
the entire plan path. Pass the full plan path only when the assigned scope genuinely requires it.

If delegation is unavailable, run the same scopes as separate named internal passes. Do not imply
that independent sub-agent coverage occurred: report `0 (delegation unavailable)` and note the
reduced independence in the review summary. For Low plans, use 0 sub-agents. Consolidate overlap
and resolve contradictions before reporting; the main agent owns the final unified review.

## Required review passes

Complete every pass below before responding. Revisit the relevant sections after each confirmed
finding to detect dependencies or contradictions exposed by the finding.

### 1. Goal and scope

Check that the objective is clear, the proposed work satisfies it, scope boundaries are explicit,
scope creep is controlled, important requirements are present, and acceptance criteria can
determine completion.

### 2. Internal consistency

Check terminology, names, assumptions, ordering, dependencies, state transitions, interfaces,
acceptance criteria, and behavior across all sections. Look for components described differently,
dependencies used before creation, and fixes that contradict another requirement.

### 3. Technical feasibility

Verify architecture, data flows, APIs, libraries, platform capabilities, integrations, state
machines, concurrency, retries, idempotency, timeouts, and recovery behavior. Use current project
context or authoritative documentation for version-sensitive claims. Do not invent limitations.

### 4. Data and security

Where relevant, check authentication/authorization, input and trust-boundary validation,
secrets, sensitive data, ownership/isolation, database constraints, transaction boundaries,
migration safety, backward compatibility, auditability, injection, information leakage, and
unsafe logging. Report only realistic risks for the proposed feature.

### 5. Failure and operations

Check partial failures, retries, duplicate execution, rollback, deployment and migration order,
rolling compatibility, observability, logging, monitoring, operational recovery, and feature
flags or rollout controls where genuinely needed.

### 6. Testing and validation

Check that the plan has the tests and verification needed for its behavior: unit, integration,
end-to-end, regression, failure-path, permission, migration, manual, device, and acceptance
validation as applicable. Do not demand irrelevant test categories. Verify that tests fail when the
behavior is wrong rather than merely restating implementation.

### 7. Implementation readiness

Check whether a developer can execute the plan without making a material undocumented decision.
Look for missing files, components, interfaces, contracts, schema/dependency/config changes,
ownership, cleanup of obsolete behavior, documentation, rollout, and rollback instructions.

### 8. Adversarial re-review

After the initial passes:

1. Re-read the complete plan from beginning to end.
2. Assume the first findings are incomplete and search for a different class of issue.
3. Re-examine sections related to every finding and test whether its correction exposes another gap.
4. Search for subtle cross-section inconsistencies and unverified assumptions.
5. Remove duplicates, weak/speculative items, and observations with no meaningful impact.

This is one deliberate adversarial pass, not an instruction to loop indefinitely. Stop when the
defined passes are complete, high-confidence blockers are resolved or reported, and deterministic
checks pass.

## Required cross-section checks

Complete the following checks when their subject exists in the plan. These are review artifacts
for the reviewer, not additional sections that must appear in the final response. Do not claim the
review is complete until the applicable checks have been performed.

### Contract closure

For every externally named command, script, file, interface, task, schema object, error code, or
artifact, trace its definition to every caller and acceptance test. Confirm that names, arguments,
ownership, inputs, outputs, failure behavior, and platform scope agree. A command required by the
plan but absent from the plan's scripts or task ownership is a plan gap even when the application
has not been implemented yet.

### Mutable-input durability

When the plan contains editable local state, enumerate every editable field and record its state
owner, persistence path, flush triggers, ordering relative to destructive actions, terminal failure
state, retry behavior, and recovery after restart or reset. Do not infer coverage for notes or other
fields from a registry that names only one editor type. Cross-check the inventory against finish,
background, navigation, removal, and clear-data flows.

### Data and query behavior

For each non-trivial query or derived statistic, verify result cardinality, grouping, ordering,
limits, tie-breakers, null handling, and consistency with the UI wording. Construct at least one
small adversarial dataset when a query uses joins, aggregation, pagination, a limit, or a time
window—for example, one parent with many children and more parents than the requested limit.
Check the required result against the query shape rather than accepting plausible prose.

### Recovery and partial-state behavior

For every recovery, migration, restore, or partial-load path, model clean success, partial success,
unknown or unreadable data, interruption before commit, interruption after commit, retry, discard,
and reset. Identify how the implementation distinguishes recovered data from data not yet known
to be recovered. Destructive operations must not operate on an ambiguous partial snapshot.

### CI and deployment closure

Trace each required CI or release step from trigger to checkout, dependency installation, build
command, exact artifact, test invocation, timeout, log/result transport, and uploaded output. Verify
that the tested binary is built from the intended revision and that every claimed platform has an
actual execution or artifact path. A prose step without an executable command or owned script is
not implementation-ready.

### Revision verification

Treat review logs and “resolved” tables as historical claims, not evidence. Review the current
plan independently before using the log for comparison. For each changed or previously resolved
finding, re-check the original failure condition, all downstream consumers, and any new contract
introduced by the correction. Classify it as resolved, partially resolved, unresolved, or newly
introduced. Generated-asset freshness checks prove asset-to-source agreement, not source-to-plan
agreement; verify both when mockups or generated files are normative.

## Repository and reference checks

When the plan references a repository, use read-only inspection to verify relevant claims. Prefer
fast text/file searches and existing project validation commands. Check, as applicable:

- Markdown links, referenced files, mockup IDs, screenshots, and generated-asset freshness.
- Section, requirement, task, dependency, schema, migration, and error-code references.
- Dependency graphs for unknown nodes, missing prerequisites, and cycles.
- Existing implementation, tests, configuration, and repository-specific instructions.

For planned commands and validation scripts, distinguish a missing implementation from a missing
plan contract. If the plan already requires the command to run in CI or release validation, the
command's definition and ownership must be specified even in a pre-implementation repository.

Do not mistake a pre-implementation repository's missing application code or planned validation
script for a confirmed defect. Mark it as unverified unless the plan requires it to exist now.
When a review log, changelog, quoted example, or historical audit intentionally names a corrected
identifier, do not report it as a live dangling reference; either exclude it from the check or
label it historical.

## Revised plans

For an updated plan, read the complete new version. Compare it with prior findings when available,
but do not repeat resolved findings. Classify results as:

- resolved;
- partially resolved;
- unresolved; or
- newly introduced.

Do not use the revision log as a substitute for the independent current review. A correction can
leave neighboring consumers stale or introduce a new contradiction; apply the cross-section checks
to each material revision.

Run all eight passes and the adversarial re-review again. Review only needs to repeat after a
material revision or a newly discovered blocker—not merely because a new session is available.

## Finding threshold and severity

Report a finding only if it can cause incorrect behavior, block safe implementation, lose or
corrupt data, create a realistic security risk, leave an important requirement unimplemented,
create a substantial testing gap, cause production/deployment failure, create an architectural
contradiction, require significant undocumented judgment, or cause likely rework.

Use only these severities:

- **Critical:** likely severe security exposure, data loss, production failure, or fundamentally
  invalid implementation.
- **Blocker:** implementation cannot proceed safely or correctly until resolved.
- **High:** likely incorrect behavior, major rework, broken integration, or significant operational
  failure.
- **Medium:** material gap that should be resolved before or during implementation without
  invalidating the whole plan.

Do not include Low findings unless the user explicitly requests style-level exhaustiveness.
Consolidate symptoms with the same root cause under one finding.

## Required response

Use this structure and omit empty severity sections:

# Plan Review

## Review Summary

- **Overall assessment:** Ready, Ready with Corrections, Needs Revision, or Blocked
- **Plan complexity:** Low, Moderate, High, or Exceptional
- **Sub-agents used:** number
- Briefly identify the most important risk areas and state that all defined passes were completed.
  If the recommended sub-agents were unavailable, state that explicitly and identify the internal
  scopes used instead.

## Critical Findings

## Blockers

## High-Priority Findings

## Medium-Priority Findings

For every finding, use:

### Short descriptive title

- **Severity:** Critical / Blocker / High / Medium
- **Plan reference:** exact section, task, step, or quoted phrase
- **Issue:** what is wrong or missing
- **Impact:** what can realistically happen
- **Required correction:** the smallest sufficient correction

## Open Questions

Include only questions whose answers are necessary to define safe behavior. For each, explain why
the answer matters, which plan area depends on it, and whether implementation can proceed without
it. Do not include optional discussion questions.

## Missing Validation

List only important absent tests or verification steps needed to protect the proposed behavior.

## Final Verdict

State whether the plan can proceed, which findings must be resolved first, and whether another
review is necessary after revision. If no material issue remains, say so directly while retaining
any accepted Medium findings separately.
