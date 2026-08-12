---
name: plan-to-mockups
description: >-
  Convert a user-supplied relative Markdown plan, usually under plans/*.md, into high-fidelity
  UI mockups in mockups/ using the frontend-design skill. Use when the user gives a plan path and
  wants rendered HTML and PNG mockups for the screens and states in that plan.
disable-model-invocation: true
argument-hint: "[plan-file]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Skill, Agent
---

# Plan to mockups

Turn one implementation plan into a small, reviewable set of rendered mockups. Treat the plan as
product truth and `frontend-design` as the design lead.

## Input

Use the supplied path exactly as a path relative to the repository root, for example:
`plans/clipboard-history.md`.

- Require one Markdown plan path; do not glob for another plan or silently choose among candidates.
- Read the entire file before designing.
- If the path is missing, absolute, outside the repository, or does not exist, stop and ask for a
  corrected relative path.

## Workflow

1. Extract the brief from the plan: product job, audience, target platform and viewports, named
   screens, journeys, explicit states and interactions, content vocabulary, and visual or
   accessibility constraints. Explicit plan values override derived design choices.

2. Invoke `frontend-design` before writing the mockups. Give it the extracted brief and the plan's
   constraints. Follow its brainstorm → critique → revise process and use the resulting direction
   for the palette, typography, layout, component vocabulary, and signature element. Keep the
   direction specific to the product; do not fill gaps with a generic dashboard or marketing-page
   kit.

   **Design light mode first.** Treat light mode as the canonical base for palette, typography,
   layout, components, and every required screen/state. Complete and review the light-mode set
   before creating any dark-mode variants. Dark mode is a secondary token pass derived from the
   approved light system, never the default starting point or a substitute for required light
   screens. This ordering still applies when the plan ultimately requires dark mode or the final
   product defaults to the system theme.

3. Build the mockups in `mockups/`.

   - If `mockups/` does not exist, scaffold it from this skill's `templates/` files. Create the
     project-specific `tokens.css`, `app.css`, `lib.mjs`, and `screens.mjs` needed by the renderer.
   - If it exists, read its source files first and extend the current direction. Preserve existing
     screen IDs unless the plan clearly removes a screen.
   - Create one screen entry for each named screen and each state the plan explicitly describes or
     that is necessary to make its flow understandable. Do not manufacture an exhaustive state
     matrix.
   - Keep every required screen entry light-themed in the initial set. Add dark variants only after
     that light set is complete and reviewed. Give each dark entry a distinct ID and set
     `variantOf` to the earlier canonical light screen's ID; the renderer rejects a dark entry
     without that earlier light counterpart.
   - Use realistic, plan-specific content. Reuse shared markup helpers for repeated UI, keep
     design values in tokens, and mark unavoidable assumptions briefly in `mockups/assumptions.md`.
   - Keep changes inside `mockups/` unless the user explicitly asks for another file to change.
     Never hand-edit generated PNGs, `index.html`, or `render-stamp.json`.

4. Build and review the result from `mockups/`:

   ```bash
   node src/build.mjs
   bash src/shoot.sh
   node src/check.mjs
   ```

   Inspect the generated contact sheet and at least one representative PNG, checking that the
   plan's screens are present, content is readable, text does not overflow, target viewports work,
   focus/contrast are usable, and the visual direction is distinctive rather than default. Fix
   source files and rerun the commands when the render exposes a problem.

Leave the rendered PNGs, contact sheet, source files, and successful render stamp in `mockups/`.
Report the supplied plan path, the screens rendered, and any unresolved assumption or rendering
blocker.
