---
name: plan-to-issues
description: Convert a completed plan into right-sized GitHub issues without implementing it. Use when explicitly asked to create or reconcile GitHub issues from a repository-relative plan file path or plan text, either as one standalone issue or as phased parent and sub-issues.
---

# Plan to Issues

Create self-contained GitHub issues that another session can implement without reading the source plan. Keep each implementation issue independently mergeable.

## Read the plan

Accept one of these sources as the first argument:

- a repository-relative path to any plan file; the filename is not fixed (for example, `plans/<plan-description>.md`); or
- plan text supplied by the user.

Resolve a relative path from the repository root and verify it is a regular file before reading it. Treat an optional second argument as a phase selector. Preserve quoted arguments. Stop when the source is missing or ambiguous, the file does not exist, or the selector matches zero or multiple phases.

Read the whole plan. Prefer its detailed task breakdown over repeated summaries, tables, or background sections. Ignore previously generated issue-result sections.

## Choose the issue shape

- Use **single mode** for one cohesive deliverable that belongs in one issue. Read [single-mode.md](references/single-mode.md).
- Use **phased mode** when the plan defines two or more actionable phases. Read [phased-mode.md](references/phased-mode.md).
- For a large unphased plan containing several independently deliverable outcomes, read [phase-synthesis.md](references/phase-synthesis.md), propose phases, and obtain approval for the phase map before creating issues.

Do not split a plan because it is long. Use cohesion, dependencies, and independently deliverable outcomes. Ask when the structure is genuinely ambiguous.

## Identify generated issues

Derive stable, search-safe keys:

- `SOURCE_KEY`: a short SHA-256 of the normalized repository-relative file path, normalized absolute external path, or exact plan text;
- `PARENT_KEY`: `SOURCE_KEY` in single mode, or `SOURCE_KEY` plus a short hash of the phase name in phased mode;
- `ITEM_KEY`: the plan's stable task ID, a normalized heading slug, or a short hash of the exact item text.

Put `<!-- plan-to-issues:parent=<PARENT_KEY> -->` in every standalone or parent issue and `<!-- plan-to-issues:item=<PARENT_KEY>:<ITEM_KEY> -->` in every sub-issue. Use paired `*-content:start/end=<key>` markers around generated body sections that may be updated later.

Search all issue states for the exact marker before creating anything. Fetch candidate bodies and compare the full marker; a title match alone is only a duplicate warning. Stop for user direction if multiple exact matches exist or a similar unmarked issue may be the same work. Ask before reopening or replacing a closed match.

## Prepare the issue set

Keep preparation read-only:

1. Resolve `owner/name` with `gh repo view` and list existing labels.
2. Inspect recent issues to match the repository's language and style.
3. Select labels only from existing repository labels; never create labels in this workflow.
4. Map every actionable plan item exactly once. Merge tightly coupled tasks that cannot be shipped independently and record necessary ordering between otherwise independent issues.
5. Draft the complete issue set with no placeholders.

Use concise English titles under 70 characters. Each implementation issue must state:

- purpose and scope;
- concrete files or components when the plan identifies them;
- verifiable acceptance criteria, including relevant failure behavior and tests; and
- dependencies or recommended ordering.

Keep a hierarchy parent focused on the phase outcome and exit criteria. Put detailed implementation guidance in sub-issues; use comments only for substantial background that would otherwise obscure the issue body.

Link a repository plan file only when it is tracked, unchanged from a commit available on the remote, and addressable by a commit permalink. Otherwise include the local path as plain text.

## Confirm before mutation

Show the proposed mode, create/reuse action, titles, labels, dependencies, and issue count. For phased plans, show the selected phases and their existing GitHub status. Call out possible duplicates and closed matches. Wait for explicit approval before creating, reopening, editing, commenting on, or linking issues.

## Create or reconcile

After approval:

1. Re-fetch every exact marker and issue state before mutation.
2. Create or reuse the standalone/parent issue. Record its number and URL immediately.
3. In phased mode, reconcile each item marker before creating the child. Create children sequentially with `gh issue create --parent` when supported, and verify the relationship after each mutation.
4. If `--parent` is unavailable, create the child, then use `gh issue edit --add-sub-issue`; fall back to the GitHub sub-issues REST endpoint only when necessary.
5. If native linking still fails, add reciprocal marker-bearing comments and the existing `sub-issue` label when available. Verify both comments and report the fallback.
6. Update generated issue content only inside matching paired markers. Preserve all user-authored text and unmarked legacy content.
7. Re-fetch all affected issues, comments, and relationships before reporting success.

Run mutations sequentially. If a command fails, record all known issue numbers and URLs, stop before the next mutation, and report the exact marker and resume point. Before retrying any create or comment operation, search its marker again because a timed-out command may have succeeded.

## Report

List every issue URL and distinguish created from reused issues. Report verification of comments and native or fallback relationships. Do not claim a complete hierarchy when any relationship remains unverified.
