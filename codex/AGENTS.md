## Engineering Discipline

These bias toward caution over speed; use judgment on trivial tasks.

- **Think before coding.** State assumptions explicitly rather than guessing silently. If a request has more than one valid interpretation, present them instead of picking one unannounced. If something is unclear, stop and ask rather than proceeding on a guess.
- **Simplicity first, in order.** Before writing anything, read the code the change touches and trace the real flow — the order below is for picking a solution, not a shortcut around understanding the problem. Then, in order:
  1. Does this need to exist at all? If not, skip it.
  2. Is it already in this codebase? Reuse it, don't rewrite — grep first, and before writing custom code, briefly report in a progress update what you checked and why it didn't fit.
  3. Does the standard library, a native platform feature, or an installed dependency already do it? Use that.
  4. Can it be done clearly in one line? Do that.
  5. Only then: write the minimum custom code that works — no speculative features, abstractions, or configurability beyond what was asked.

  Never cut corners on trust-boundary validation, data-loss handling, security, or accessibility.
- **Surgical changes.** Touch only what the task requires: don't "improve" adjacent code, comments, or formatting, and match existing style even where you'd do it differently. Remove imports/variables/functions your own change orphaned; leave pre-existing dead code alone (mention it, don't delete it).
- **Goal-driven execution.** Turn vague asks into verifiable success criteria before starting — e.g. "fix the bug" → "write a test that reproduces it, then make it pass" — and check that criteria before calling the task done, not just that it compiles.
- **Tests must verify behavior, not restate implementation.** Before adding a test, ask whether it would actually fail if the logic were wrong — not just replay the same steps the code takes and assert the code's own output.

## Code Structure

Apply these rules when writing new code and whenever refactoring.

- Aim for at most 3 levels of nesting per function. Review deeper nesting for guard clauses, `continue`, or function extraction; keep it when flattening would obscure the flow.
- No nested ternaries. For three or more outcomes, use a small function with early returns or a lookup table.
- In JS/TS, lookup tables keyed by external strings (server, URL, storage) must read own keys only (`Object.hasOwn`, or use a `Map`). Plain objects also resolve inherited keys such as `toString`, `constructor`, and `__proto__`.
- Name compound conditions when a predicate explains domain meaning or makes complex logic easier to read. Keep simple, clear conditions inline and avoid double negatives.
- Prefer an enum or separate operations when a boolean parameter makes behavior unclear at the call site, including in private helpers. Clear boolean APIs and stored values such as `setActive(active)` are fine.
- Compare with `true` or `false` only when the value can also be `undefined` or `null`.
- Review functions over 100 lines or 20 branches for separable responsibilities and excessive nesting. Split where it improves understanding, not merely to meet a size threshold.
- Avoid wrappers that only add another name for the same operation. Keep wrappers that serve a concrete purpose, such as adapting an interface or maintaining a public API boundary.
- Keep work after a transaction commit outside the `try` block whose error handler rolls back the transaction.

## Names and Documentation Style

- No comment or doc is better than one that isn't needed — if the code can stand without it, skip it.
- When behavior changes, update names and comments in the same change. Descriptions of the old behavior are bugs.
- Give defensive checks with non-obvious reasons (such as version skew or old clients) a named predicate or a one-line explanation of why they exist.
- When a comment is needed, explain why, usually in 1–2 lines per language. Avoid history narration and restating the code; use longer explanations only when needed to capture a non-obvious contract or safety constraint.
- When extracting a function, move its doc comment with it and check that no doc block is left above the wrong declaration.

## Security

- Treat URL, server, and storage input as untrusted. Verify any claimed proof or token against independently trusted state or cryptographic checks, never against a value from the same untrusted input. Keep locally generated secrets (e.g. PKCE verifiers) where only the legitimate party can supply them.

## Change Sets

- Avoid empty or ineffective commits and churn where a commit merely rewrites the previous commit's work.
- Keep one concern per PR. Do not stack PRs on unmerged ones unless the user asks.
- Refactoring must preserve behavior. Verify it with tests and an independent equivalence review of the diff; keep behavior changes and bug fixes in separate commits/PRs, subject to the explicit commit permission below.

## Cross-Project Preferences

- **Actively invoke skills.** Check for an applicable skill even for routine tasks, and invoke it at the point of doing the work. Do not substitute remembered guidance, merely reading or editing a skill file, or a tool's built-in instructions for the skill's required workflow.
- **Keep answers terse. No trailing summaries.** Don't recap what was just done at the end of a response — the user can read the diff/output themselves.
- **Never stage, commit, or push unless explicitly asked.** Finish the work, leave it in the working tree, and say what changed — the user reviews diffs before they become commits. A request to *do* something ("convert these docs", "fix this bug") is not a request to commit it; an explicit ask means `/git-commit`, "commit this", or similar in that same message. Approval for one commit does not carry over to the next change.
  - **Pushing is a separate permission from committing.** "Commit this" authorizes a commit, not a push; being asked to push once does not authorize the next push. Never combine them in one command (`git commit … && git push`) — that removes the user's chance to see the commit before it becomes public. Commit, stop, report what changed, and wait.
