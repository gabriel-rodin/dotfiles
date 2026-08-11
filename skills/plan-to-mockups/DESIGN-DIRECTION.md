# Setting the design direction

Reference for step 4 of [`SKILL.md`](SKILL.md) — what to ask `frontend-design` for, the
calibration to use if it is not installed, and the rules that bound its answer.

## Borrow all of it, not just the palette

The failure mode this step exists to prevent is asking `frontend-design` for colour and
type, then quietly making every *structural* decision yourself in step 5 — row height, what a row
contains, how chrome relates to content, which controls exist at all. Those decide whether the
result looks designed far more than the hex values do. So the brief must ask for, and the answer
must name:

- **Screen anatomy** — the bands a window is made of, and what each one is worth its height for.
- **Row anatomy** — for any list-shaped product, the single most repeated element in the whole set:
  how many lines, what is on each, what is omitted, and how tall.
- **Density** — how many rows or items are visible at the default size (see the third rule below).
- **Chrome-versus-content hierarchy** — which type is furniture and which is the user's own data,
  and how a glance tells them apart.
- **The component vocabulary this product actually needs** — which is a finding, not a checklist.
  A dense keyboard-first tool may legitimately have no buttons and no chips anywhere; a footer of
  keyboard hints can replace both.
- **The signature element**, and what it encodes. If the product has one repeated slot that could
  carry meaning, decide what meaning earns it — and prefer the signal that *differs* row to row.
  A state that reads the same on 95% of rows is wallpaper, however important the fact is; put that
  one in a badge on the exceptions and give the slot to something with more entropy.

## Calibration, if `frontend-design` is not installed

Avoid the three looks AI design defaults to regardless of subject: cream background with a
high-contrast serif and a terracotta accent; near-black with one acid-green or vermilion accent;
broadsheet hairline rules with zero radius and dense columns.

**Layout has defaults too, and they are less discussed than the palette ones.** An application
mockup tells on itself through spacing long before colour. The signature: rows tall enough that a
list shows five items where the product shows ten; filters drawn as outlined pill chips with icons;
a band of large primary buttons duplicating shortcuts the hint bar already states; a detail pane a
third empty because it holds a title and one field; chrome set at the same size as content so the
furniture competes with the data. Each is individually defensible, which is why they survive
review. Together they are the whole difference between "an AI drew an app" and "this is the tool".

The opposite instinct is the one to reach for in professional software: information per pixel, and
chrome that is unmistakably subordinate to the user's own data. *How* it is made subordinate —
size, weight, case, colour, face — should differ per product. That there is a visible hierarchy
between furniture and content is not optional.

## What the skill returns, and what bounds it

It sets direction; it does not write the mockups. The palette, type scale, and component
vocabulary it returns become `tokens.css` and `app.css` in step 5 — the pipeline still owns every
file, and no screen is built until the tokens exist.

Bound it with these rules before it starts:

- **Plan values are transcribed verbatim.** Where the plan fixes a hex, a type step, a spacing
  base, or a radius, that value is law and `frontend-design` does not get a vote on it.
  Transcribe it into `tokens.css` unchanged, with the plan's section number in a comment.
- **Additions are marked DERIVED.** Anything the mockups need that the plan never specified — a
  tint, a skeleton grey, a scrim, a per-category palette — is a proposal, not a fact. Mark it
  `/* DERIVED */` in `tokens.css` and give it an entry in the gap ledger (step 9).
- **The palette is designed light-first.** `[data-theme='light']` carries the direction's real
  intent — it is what the whole matrix renders in bar the handful of dark rows — and dark restates
  it (step 5). Where the plan's visual section names a dark interface, that is a plan value like any
  other: transcribe it, and record the polarity in the gap ledger so a reader knows it came from the
  plan rather than from taste.
- **Density is a constraint, not a preference.** Work out, from the plan, how much has to fit —
  a virtualized list, a 50-row page, a quick-pick shortcut that numbers nine visible items, a
  latency target that only makes sense at scale — and give it the number before it starts. A dense
  professional tool drawn at consumer spacing is wrong the way a wrong hex is wrong, and much
  harder to notice afterwards.

Feed it a brief distilled from the plan: the product's job, its audience, the platform, the
brand-personality section if the plan has one, and the verbatim constraints above.
