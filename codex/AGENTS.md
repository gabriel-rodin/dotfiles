## Engineering Discipline

These bias toward caution over speed; use judgment on trivial tasks.

- **Think before coding.** State assumptions explicitly rather than guessing silently. If a request has more than one valid interpretation, present them instead of picking one unannounced. If something is unclear, stop and ask rather than proceeding on a guess.
- **Simplicity first, in order.** Before writing anything, read the code the change touches and trace the real flow — the order below is for picking a solution, not a shortcut around understanding the problem. Then, in order:
  1. Does this need to exist at all? If not, skip it.
  2. Is it already in this codebase? Reuse it, don't rewrite — grep first, and note in your completion summary what you checked and why it didn't fit.
  3. Does the standard library, a native platform feature, or an installed dependency already do it? Use that.
  4. Can it be done in one line? Do that.
  5. Only then: write the minimum custom code that works — no speculative features, abstractions, or configurability beyond what was asked.

  Never cut corners on trust-boundary validation, data-loss handling, security, or accessibility.
- **Surgical changes.** Touch only what the task requires: don't "improve" adjacent code, comments, or formatting, and match existing style even where you'd do it differently. Every changed line should trace back to the request. Remove imports/variables/functions your own change orphaned; leave pre-existing dead code alone (mention it, don't delete it).
- **Goal-driven execution.** Turn vague asks into verifiable success criteria before starting — e.g. "fix the bug" → "write a test that reproduces it, then make it pass" — and check that criteria before calling the task done, not just that it compiles.
- **Tests must verify behavior, not restate implementation.** Before adding a test, ask whether it would actually fail if the logic were wrong — not just replay the same steps the code takes and assert the code's own output.

## Documentation Style

- Write short, concise comments and documentation.
- Describe the intent and purpose of the code, not obvious implementation details.
- One or two sentences at most — prefer clarity over completeness, never verbose or repetitive.

## Cross-Project Preferences

- **Actively invoke skills — don't rely on memory of them, and don't default to a tool's built-in instructions instead.** When a task matches an available skill, call the Skill tool at the point of doing the work. Two distinct ways this gets skipped, both count: (1) recalling a skill's gist from having read it earlier instead of invoking it now: editing or reading a skill file doesn't make it apply, it only loads into context when actually invoked; (2) pattern-matching to a tool's own embedded default instructions for the task (e.g. Bash's built-in "committing changes with git" guidance) without first checking whether a more specific skill exists for it — a tool description reading as sufficient is not a reason to skip the skill lookup. Don't substitute default judgment for a repo's or user's explicit, curated process.
- **Keep answers terse. No trailing summaries.** Don't recap what was just done at the end of a response — the user can read the diff/output themselves.
