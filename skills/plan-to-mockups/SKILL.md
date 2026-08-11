---
name: plan-to-mockups
description: >-
  Turn an implementation plan into a committed set of high-fidelity screen
  mockups — rendered from HTML by a token-driven pipeline, not drawn — with a
  staleness gate, a contact sheet, and a gap ledger.
disable-model-invocation: true
argument-hint: "[plan-file]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Skill
---

Mockups are **rendered, not drawn**. Every screen is HTML built from one token file and one
component stylesheet, shot to PNG by headless Chrome, and **stamped** with a content hash so a
forgotten re-render fails loudly instead of shipping a stale reference. Hand-editing a PNG
accomplishes nothing; changing a token re-renders every screen consistently.

The unit of work is the **matrix** — one row per screen × state, not per screen. A plan that names
twelve screens yields forty-odd mockups, because empty, loading, error, dialog, dark, and
large-text are each their own row.

Two branches: **scratch** (no `mockups/` yet) and **update** (one exists). Step 3 picks.

## 1. Locate and read the plan

Take the argument path if given. Otherwise glob, in order: `plan.md`, `PLAN.md`, `plans/*.md`,
`docs/plan.md`. More than one candidate → ask which.

Read it **whole**, top to bottom. Grepping for "screen" finds the screen list and misses the visual
system, the error catalogue, the accessibility floor, and the domain vocabulary that makes sample
content realistic — all of which the mockups must honour.

Note the section numbers for: visual design system, screen specifications, navigation map, error
catalogue, accessibility. You will cite them by number in `tokens.css` and `assumptions.md`, so the
next reader can check a value against its source.

**Done when** you can name, from the plan alone: the product's one-sentence job, its target
platform and viewport, every screen, and every error state.

## 2. Build the matrix

Write the matrix out — as a table, in your response — *before* any code. Columns:

| id | group | plan ref | title | theme | viewport | note |

- **id** — `NN-kebab-name`, numbered in **flow order**, not spec order. The number is the contact
  sheet's ordering and the PNG's filename.
- **group** — the contact-sheet section: a flow, not a screen (`Launch`, `Active workout`,
  `Errors`, `Dark theme`, `Accessibility`).
- **plan ref** — the plan's own screen ID (`S5`) or error code (`E-06`). Rendered as the caption
  tag, so a reviewer can jump from PNG to spec.
- **note** — one sentence on *why this screen looks the way it does*. Not a description of what is
  visible; the PNG already says that.

Derive rows exhaustively. For each screen spec in the plan, one row per state it names or implies:

- default (populated) · empty · loading/skeleton · error · validation-failure
- each modal, bottom sheet, dropdown, and confirmation dialog it can open
- a selected/hover/focus variant wherever a control's state is not obvious at rest
- desktop **and** mobile widths, if the plan targets both
- a dark-theme row for each *primary* screen (not all of them — 3–5 is the right dose)
- one accessibility row at the largest supported text size, on the densest screen

Add a `00-design-system` row: the token reference sheet. It is a mockup of the system itself.

**Done when** every screen section in the plan maps to at least one row, every state word in every
spec (`Empty:`, `Loading:`, `Error:`, `Validation:`) has its own row, and every error code in the
plan's catalogue is either rendered or listed under "not mocked, and why".

## 3. Survey `mockups/` — pick the branch

Only a directory literally named `mockups/` counts as existing work. A repo may have
`mockups_v1/`, `mockups-archive/`, or other past iterations sitting alongside it — **do not open,
read, or otherwise use these as a reference.** Step 4's direction must come from the plan and
`frontend-design`'s independent judgment; basing it on a prior attempt (even unconsciously, by
having looked at its palette or layout first) defeats the reason that step exists and makes the
result unverifiable as this run's own judgment.

**No `mockups/` directory** → scratch. Scaffold the pipeline per
[`PIPELINE.md`](PIPELINE.md), then continue.

**A `mockups/` directory exists** → update. Read `src/screens.mjs`, `src/tokens.css`, and
`assumptions.md` first, then obey these rules, which exist because the artifacts are generated and
cross-referenced:

- **Never hand-edit a PNG, `index.html`, or `render-stamp.json`.** All three are outputs.
- **Never renumber an existing id.** Plan sections, issues, and other docs link to
  `09-logger.png` by name. A screen that belongs between `06` and `07` becomes `06a-…`. That is
  why the numbering has gaps and letters.
- Route each change to its narrowest source: a colour or spacing value → `tokens.css`; how a
  component looks → `app.css` (style) or `lib.mjs` (markup); one screen's content →
  its entry in `screens.mjs`.
- Keep the existing direction — an update inherits the committed palette, type scale, and
  component vocabulary. Step 4 says when that reopens.
- Reconcile the matrix against `screens.mjs`: rows you added, rows now obsolete, ids unchanged.
  State the diff before writing.

**Done when** you have stated which branch you are on and, on update, listed exactly which files
you intend to touch.

## 4. Set the design direction

**Call the Skill tool on `frontend-design`** — it ships as a plugin, so the plugin-qualified name
is what the Skill tool resolves; the bare `frontend-design` works only if it is installed as a
plain skill. Check the available-skills listing for which form is present. This call is mandatory:
skipping it is precisely why an AI-generated mockup reads as AI-generated. It owns aesthetic
judgement — palette, type pairing, layout concept, the signature element, and interface copy. Do
not re-derive that judgement yourself; this step exists to borrow it.

Brief it and bound it per [`DESIGN-DIRECTION.md`](DESIGN-DIRECTION.md): what the brief must ask
for, the three rules that bound it, and the calibration to fall back on in the one case below.

On the **update** branch this step is skipped — the committed direction stands — unless the plan's
visual section changed, or the update adds a component the existing vocabulary cannot express.

Only if `frontend-design` is absent from the available-skills listing entirely, say so plainly, set
the direction yourself against `DESIGN-DIRECTION.md`'s calibration, and flag in the final report
that the direction is unreviewed.

**Done when** `frontend-design` has been invoked and returned — or you have stated why it
was skipped, naming which of the two exemptions above applies — *and* you can name the palette, the
type scale, the screen and row anatomy, the density figure, and the component vocabulary, marking
each value as plan-verbatim or DERIVED.

## 5. Write the token and component layer

In this order, because each depends on the last:

1. **`src/tokens.css`** — the only place a colour, spacing, or radius value is defined. Both themes.
   Nothing downstream may write a literal hex or pixel gap; if a screen needs one, it is a missing
   token.
2. **`src/app.css`** — the component classes **step 4's direction actually named**, and no others.
3. **`src/lib.mjs`** — the icon set plus every shared markup helper, exported as functions: the
   window or screen chrome this product has, the repeated row and card types, and the overlays.

**Build the vocabulary the direction found, not a standard kit.** There is deliberately no
checklist here. "Cards, buttons, inputs, chips, sheets, tabs, status bar, nav bar" is the generic
application kit, and writing it out in advance is how a mockup acquires pill chips it did not need
and a footer of buttons that repeat the keyboard hints below them. If a component is not in the
direction and no matrix row requires it, it does not get a class. If a matrix row turns out to need
one the direction never anticipated, that is a finding — add it, and say so in the gap ledger.

Anything appearing on two screens is a `lib.mjs` export, not copied markup. This is what makes a
component change a one-line edit instead of a forty-file sweep.

**Then prove the direction on one screen before writing the other forty.** Build the single
densest, most content-bearing screen in the matrix — the one the product lives or dies on — render
it to PNG, and open it with the Read tool. Judge it as a designer, against step 4's calibration and
step 7's checks: count the rows, find the dead bands, compare chrome type to content type. Fix the
direction, not the screen, and look again.

This gate is the difference between one screen done well and forty done adequately. A direction
that is only ever evaluated in the abstract, and is then mass-produced across a whole matrix,
regresses to the defaults every time — and by then the cost of changing it is forty screens, so it
does not get changed.

**Done when** `grep -E '#[0-9a-fA-F]{3,6}' src/app.css src/lib.mjs src/screens.mjs` returns nothing
but token definitions, and you have looked at a rendered PNG of the busiest screen, stated its
visible-row count against the step-4 density figure, and either corrected the token or component
layer as a result or stated plainly why the render already matches the direction.

## 6. Write the screens

`src/screens.mjs`: sample-data constants at the top, then one `add({…})` per matrix row in flow
order.

**Realistic content is a hard requirement.** Sample data comes from the plan's own domain — real
exercise names, plausible weights, a note someone would actually type. Lorem ipsum, `Item 1`,
`John Doe`, and `Lorem` are failures. Numbers must be internally consistent: if a summary says
three sets, three rows exist and their volume adds up.

Compose states from the *same* data. The empty state and the populated state are the same screen
with the list emptied, not two unrelated designs.

**Done when** every matrix row has an entry and `node src/build.mjs` reports the expected count.

## 7. Build, look, critique

```bash
cd mockups
node src/build.mjs        # fast, no browser — preview src/out/<id>.html
```

Then **look at the output**, do not assume it. Render a representative sample to PNG and open them
with the Read tool — the image comes back visually. Pick at least: the densest screen, one empty
state, one dialog, one dark row.

Critique what you see against the plan, not against your intent: tap targets below the floor, text
that overflows its container, a skeleton that does not match the layout it stands in for, a dialog
whose scrim does not read, contrast that fails in dark. Fix in the source, rebuild, look again.

Then run these, which are checkable rather than a matter of taste, and which catch the drift step 4
warns about:

- **Count the visible rows** on the densest list screen and say the number. Compare it to step 4's
  density figure. Five where the plan's quick-pick binds nine is a failed screen, not a tight one.
  Row height is almost always the cause, and almost always a line of metadata that could be folded
  into another line or dropped.
- **Find the dead bands.** Every horizontal band must earn its height. A footer of large buttons
  repeating the hint bar, a detail pane a third empty, a header holding only a title — each is
  height the list should have had. A sparse pane usually wants more of what the plan already knows
  about the thing on screen — provenance, size, state, counts — not more padding.
- **Compare chrome type against content type** in the render. If they are the same size, the
  furniture is competing with the user's data. Chrome should read as smaller and quieter.
- **Check glyph coverage.** `␣`, `⎋` and similar render as empty boxes in most UI font stacks —
  they exist in the mono stack and often not in the sans. Use words, or verify in the PNG.
- **Check that real content wraps.** Anything holding a path, URL, log line or code needs
  `overflow-wrap: anywhere`, or a long line runs under the pane edge where only a render shows it.
- **Check a tall reference sheet is not clipped.** `overflow: hidden` on the body means a canvas
  one section too short truncates in silence. Confirm the last section is present in the PNG.

**Done when** you have viewed rendered output, stated the visible-row count, and either corrected
something you saw or stated plainly that the checks above found nothing to fix.

## 8. Shoot and stamp

```bash
bash src/shoot.sh         # builds, then renders every screen @2x, then stamps
node src/check.mjs        # must print ✓
```

`shoot.sh` builds first, so it can never render stale HTML, and it writes `render-stamp.json` only
after **every** screen succeeds — a partial run cannot claim to be current.

**Done when** `check.mjs` exits zero.

## 9. Write the three companion documents

`index.html` links these; they are part of the deliverable, not optional extras.

- **`design-system.md`** — colour, type, spacing, elevation, every component, the icon set, and the
  accessibility floor. Reference material a developer reads while building, with token names.
- **`user-flow.md`** — the navigation model, each primary journey as an ordered walk naming the
  screen ids it passes through, the failure paths, and the design decisions worth defending.
- **`assumptions.md`** — the **gap ledger**, and the most valuable of the three. One numbered entry
  per decision the plan did not make, each stating: the **gap** (what the plan leaves open, with
  its section number), what was **assumed**, and the **consequence** if the assumption is wrong.
  Follow it with two sections: surfaces the plan specifies but the mockups deliberately do not
  render, and questions still open.

Every `/* DERIVED */` token has a ledger entry. So does every place a mockup departs from the plan.

**Done when** a reader who has the plan but not this conversation can tell which mockup decisions
are binding and which are proposals.

## 10. Close the loop

Write `mockups/README.md`: how to look at them, how to regenerate, what is committed and why, and
the screen table. [`PIPELINE.md`](PIPELINE.md) specifies its contents.

Then report, in your response:

- the matrix as built, with counts per group
- which ledger entries need the user's decision, phrased as answerable questions
- the exact commands to review locally

Offer — do not perform unasked — to link the mockups back into the plan, adding a *Rendered:*
line to each screen spec naming its PNGs. That edits a file outside `mockups/`, so it needs a yes.

**Done when** `node src/check.mjs` passes, `git status` shows changes confined to `mockups/`, and
the open questions are stated as questions.
