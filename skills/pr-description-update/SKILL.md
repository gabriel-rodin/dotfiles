---
name: pr-description-update
description: Update a GitHub PR title and description from the actual branch diff, preserving exact observed problem scenarios and separating Problem, Root Cause, Fixes, and Testing sections.
---
Update a GitHub pull request description based on the changes in the PR.

## Arguments

```
/pr-description <PR_NUMBER> [--fixes <ISSUE_NUMBERS>]
```

- `PR_NUMBER` (required): The pull request number to update
- `--fixes` (optional): Comma-separated issue numbers that this PR fixes (e.g., `--fixes 123,456`)

Examples:
- `/pr-description 3534`
- `/pr-description 3534 --fixes 123`
- `/pr-description 3534 --fixes 123,456,789`

## Instructions

1. First, gather information about the PR:
   - Use GitHub plugin to get PR details (title, current description, base branch)
   - Use local git to get commits: `git log main..HEAD --oneline`
   - Use local git to get the diff: `git diff main..HEAD`
   - Parse any `--fixes` argument for issue numbers
   - If the user provides a commit hash, issue description, reproduction flow, or correction, inspect that exact evidence before drafting. Use `git show <hash>` and, when necessary, compare `<hash>^` to `<hash>`.

2. Check the existing PR description:
   - If it already has a complete, accurate description that reflects the changes, do nothing
   - If it's missing sections, incomplete, or outdated compared to the actual changes, proceed to update
   - If it only has the template placeholder text, generate a full description

3. Analyze the changes:
   - Understand the purpose of each commit
   - Identify any breaking changes (API changes, removed features, behavior changes)
   - Look for new features, bug fixes, refactoring, or documentation changes
   - Collect issue numbers from:
     - The `--fixes` argument (if provided)
     - Commit messages (patterns like "Fixes #123", "Closes #456", "Resolves #789")
   - Build an evidence map for each logical fix:
     - **Problem**: exact user-visible symptom and reproduction sequence, including which participant, control, action, and missing outcome are involved.
     - **Root Cause**: exact pre-change code path or missing persistence/state transition demonstrated by the diff.
     - **Fixes**: concrete changes that address that root cause and the behavior they restore.
   - Treat user-provided corrections as authoritative acceptance criteria. Do not generalize “press the same control twice” into a mixed-control interaction, and do not describe a generic race when the observed failure is a specific workflow such as re-adding a participant after a missed call without a new ring.

4. Generate or update the PR description with these sections:

## PR Description Format

### Summary (always include)

Brief bullet points describing what changed and why. Focus on the *purpose* and *impact*, not implementation details.

```markdown
## Summary

- Added X to enable Y
- Fixed bug where Z would happen
- Refactored W for better maintainability
```

### Problem (bug fixes)

State the exact observed failure and reproduction flow. Keep separate bullets for separate bugs; do not merge distinct workflows into a vague symptom.

### Root Cause (bug fixes)

Identify the precise pre-change branch, missing guard, missing state transition, or persistence behavior proven by the diff. Avoid unsupported causal language.

### Fixes (bug fixes)

Explain how the implementation corrects each root cause and mention relevant regression coverage. This is the implementation section; it is distinct from Problem and Root Cause.

### Breaking Changes (include only if applicable)

Document any changes that affect existing users or APIs.

```markdown
## Breaking Changes

- `ClassName.method()` now requires a `param` argument
- Removed deprecated `old_function()` - use `new_function()` instead
```

### Testing (include when non-obvious)

How to verify the changes work. Skip for trivial changes. Manual steps are limited to the happy path — the one test per fix/feature that shows the bug no longer reproduces or the feature works as intended; don't include manual edge-case checks.

```markdown
## Testing

- Run `uv run pytest tests/test_feature.py` to verify the fix
- Example usage: `uv run examples/new_feature.py`
```

### Issue links (include if issues are provided or found in commits)

List issues this PR fixes. GitHub will automatically close these issues when the PR is merged. Keep these links separate from the `## Fixes` implementation section.

```markdown
## Issue links

- Fixes #123
- Fixes #456
```

Note: Use "Fixes #X" format (not "Closes" or "Resolves") for consistency. Each issue should be on its own line with "Fixes" to ensure GitHub auto-closes them.

## Guidelines

- **Be concise** - Reviewers should understand the PR in 30 seconds
- **Focus on why** - The diff shows *what* changed, explain *why*
- **Skip empty sections** - Only include sections that have content
- **Use bullet points** - Easier to scan than paragraphs
- **Don't duplicate the diff** - Avoid listing every file or line changed
- **No local-only file references** - Never mention or link paths that are gitignored or otherwise not part of the pushed branch (e.g. `.claude/skills/`, `pr-reviews/`, `plans/`, scratch notes). A reviewer on GitHub can't open them, so citing them as a source ("see `pr-reviews/PR-N/review.md`") is a dead reference. Before adding a path to the description, confirm it's tracked and pushed (`git ls-files --error-unmatch <path>`); if it isn't, describe the content inline instead of pointing at the file.

## Example Output

```markdown
## Summary

- Added `/docstring` skill for documenting Python modules with Google-style docstrings
- Skill finds classes by name and handles conflicts when multiple matches exist
- Skips already-documented code to avoid unnecessary changes

## Testing

/docstring ClassName

## Issue links

- Fixes #123
```

## Checklist

Before updating the PR:

- [ ] Verified existing description needs updating (not already complete)
- [ ] Summary accurately reflects the changes
- [ ] Title names the observable outcomes of all major fixes, not just a commit subject
- [ ] Problem sections match the exact user-provided reproduction flows
- [ ] Root causes are proven by inspecting the relevant pre-change code and diff
- [ ] Fixes explain the implemented correction for each root cause
- [ ] Breaking changes are clearly documented (if any)
- [ ] No unnecessary sections included
- [ ] Description is concise and scannable

## Safe update workflow

Write the complete replacement body to a temporary Markdown file in the current worktree with `apply_patch`, then update the PR with `gh pr edit <number> --body-file <file>`. Do not pass JSON-escaped Markdown, literal `\\n`, or Markdown containing backticks through a double-quoted shell argument. Remove the temporary file after the update.

Verify the final result with `gh pr view <number> --json title,baseRefName,headRefName,body` and confirm the title, real Markdown line breaks, exact Problem/Root Cause/Fixes claims, and expected section headings before reporting completion.
