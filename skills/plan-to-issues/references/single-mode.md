# Single-Issue Mode

Create or reconcile exactly one standalone issue for the whole plan. Do not create sub-issues, hierarchy links, or generated comments.

Use the normal parent marker as the issue identity. Apply only an existing type label; do not add priority or `sub-issue` labels.

Use this body shape:

```markdown
<!-- plan-to-issues:parent=<PARENT_KEY> -->
<!-- plan-to-issues:issue-content:start=<PARENT_KEY> -->

## Overview
[What will change and why]

## Scope
[Implementation scope and important constraints]

## Acceptance Criteria
- [ ] Required behavior is verified
- [ ] Relevant failure behavior is verified
- [ ] Relevant tests pass

## Plan Document
[Verified permalink or plain local path]

<!-- plan-to-issues:issue-content:end=<PARENT_KEY> -->
```

Omit sections unsupported by the plan. Keep the issue self-contained. When reconciling an existing issue, replace only its matching `issue-content` block; preserve legacy bodies without paired markers and report them for review.
