---
name: create-pr
description: Create a pull request with a detailed description when opening a new PR, running `gh pr create`, or when asked to write/draft a PR description. Produces a Summary, distinct Problem, Root Cause, and Fixes sections for bug-fix PRs, feature details for feature PRs, and Testing guidance. Not for editing an existing PR's description after the fact.
---

# Create a PR

## Title

Format: `<type>[optional scope]: <description>`.

| Type       | Purpose                        |
| ---------- | ------------------------------ |
| `feat`     | New feature                    |
| `fix`      | Bug fix                        |
| `docs`     | Documentation only             |
| `style`    | Formatting/style (no logic)    |
| `refactor` | Code refactor (no feature/fix) |
| `perf`     | Performance improvement        |
| `test`     | Add/update tests               |
| `build`    | Build system/dependencies      |
| `ci`       | CI/config changes              |
| `chore`    | Maintenance/misc               |
| `revert`   | Revert commit                  |

- Scope: the area/module the PR mainly touches (e.g. `feat(chat): ...`); omit if the change is repo-wide or scope isn't obvious.
- Description: present tense, imperative mood, under 72 characters.
- Derive type/scope from the diff gathered below, not from any single commit message — a PR's title should summarize the whole branch, not just its last commit.

## Gather context

1. `git log <base>..HEAD --oneline` and `git diff <base>...HEAD` — every commit and file this PR introduces.
2. If the request, issue, PR comment, or commit reference describes an observed scenario, record that scenario verbatim as the behavioral acceptance criterion. Preserve exact actors, controls, sequence, state transition, and missing outcome; do not replace it with a broader or inferred interaction.
3. For every commit or logical fix, map the evidence before writing prose:
   - **Problem**: the user-visible failure and exact reproduction flow.
   - **Root Cause**: the specific pre-change code path or missing state transition proven by the diff; do not infer a race or architectural cause without locating it.
   - **Fixes**: the implemented changes that address that root cause, including the resulting user-visible behavior and regression coverage.
   Inspect referenced commit hashes with `git show <hash>` and compare the parent version when needed; a commit subject alone is not evidence of the problem.
4. Classify the PR by its **overall intent** — the issue or goal the whole branch exists to close — never by tallying individual commit messages. A `fix:` commit that patches a bug introduced earlier in the same branch, while building a feature, is incidental cleanup, not evidence the PR is a bug fix: fold it into the Fixes section like any other change, don't let it trigger Problem/Root Cause/Fixes.
   List out the distinct, genuinely separate, intentional pieces of work the branch closes — each one a bug fix (a pre-existing issue, not one the branch itself introduced) or a feature (new capability) — not a tally of commits, and not fixup commits folded in beside the work they clean up. This list has **one or more** entries; nothing in the process below is specific to exactly two.
   - **Single**: the list has exactly one entry — a pure bug fix or pure feature. Use the single-entry body shape below.
   - **Multiple**: the list has two or more entries, in *any* combination of bug fixes and features — all fixes, all features, or a mix. Use the numbered body shape below regardless of the mix or the count: two bug fixes and zero features follows the exact same numbered structure as one fix plus one feature, or two features plus three fixes. Never let "they're all fixes" or "they're all features" become a reason to fall back to a single flat Problem/Root Cause/Fixes (or single Feature details) section — each entry still gets its own numbered section per the rule below.

## Body sections, in order

1. **Summary** — concise bullet points covering the overall fixes/features. What changed, not how.
2. **Problem** — bug-fix PRs only: state the exact observable symptom and reproduction flow.
3. **Root Cause** — bug-fix PRs only: identify the exact pre-change code path, missing guard, state transition, or persistence behavior responsible.
4. **Fixes** — bug-fix PRs only: explain how the code changes correct the root cause and what regression coverage was added.
   Omit entirely on a pure-feature PR.
5. **Feature details** — feature PRs only: what the feature does, its scope, user-facing behavior. Omit on a pure-fix PR.
6. **Testing** — how to verify: commands to run, and manual steps limited to the happy path — the one test per fix/feature that shows the bug no longer reproduces or the feature works as intended. Don't include manual edge-case checks.

Summary and Testing are always present; Problem, Root Cause, Fixes, and Feature details are included only per the classification above.

### Multiple classification: make the split explicit for the reviewer, at any count

A reviewer opening a multi-piece PR cold has no way to know it bundles several unrelated pieces of work unless the body says so up front — a Problem/Root Cause/Fixes block sitting next to Feature details (or next to another Problem/Root Cause/Fixes block) reads as one narrative, and the fact that the pieces are separable gets lost. This applies at N=2 exactly the same way it applies at N=5 — never collapse back to the single-entry shape just because there happen to be only two entries, and never special-case "two" as if it were the only multi-entry count. For any **Multiple** classification (N ≥ 2 pieces of work):

- Open the body with one line before the Summary stating it bundles N separate changes, naming N explicitly (e.g. "This PR bundles 3 separate, self-contained changes — please review each one.").
- Number every piece of work 1..N in the Summary itself, labeling each by its own kind (`1. **Feature** — ...`, `2. **Bug fix** — ...`, `3. **Bug fix** — ...`), not just as prose bullets. This looks identical whether the mix is fix+feature, all-fix, or all-feature — only the per-entry label changes.
- Give each piece of work its own top-level numbered section using that same number (`## 1. Feature: <name>`, `## 2. Bug fix: <name>`, `## 3. Bug fix: <name>`, ...), with Problem/Root Cause/Fixes nested (as `###`) under each bug-fix section and feature details under each feature section — don't let a flat Problem/Root Cause/Fixes/Feature-details section order stand in for the split, no matter how many pieces there are or whether they're all the same kind.
- In Testing, tag each step with the number(s) of the piece(s) it verifies (`Manual (1): ...`, `Manual (2): ...`, `Manual (3): ...`) so the reviewer can check off each change independently.

This numbering is the default output shape for any classification with two or more pieces of work — not an enhancement to add only if asked, and not something to abandon or simplify once N exceeds two.

## Create the PR

Write the complete Markdown body to a temporary file in the current worktree, then pass it with `--body-file`:

```bash
gh pr create --base <base-branch> --head <head-branch> \
  --title "<type>[scope]: <description>" \
  --body-file .pr-description.md
```

Use `apply_patch` to create `.pr-description.md`, so Markdown headings, bullets, backticks, and actual line breaks are preserved. Remove the temporary file after the PR is created and verified. Do not pass a JSON-escaped body, a body containing literal `\\n`, or Markdown containing backticks inside a double-quoted shell argument: zsh can either preserve the escape sequences as text or execute backtick contents as command substitution.

After creation, verify the rendered body and branches:

```bash
gh pr view <number> --json title,baseRefName,headRefName,body
```

Confirm the output contains real line breaks and the expected Markdown sections before reporting the PR complete. Confirm the target base branch and that the branch is pushed before creating.
