# The pipeline

Scaffold for a fresh `mockups/`. Copy [`templates/`](templates/) into `mockups/src/` — the four
marked *template* below are project-agnostic and stay unchanged; `tokens.css`, `app.css`, and
`screens.mjs` arrive as empty starters you fill in, and `lib.mjs` you write from scratch. The
starters are deliberately contentless: a component kit shipped in advance is how a mockup acquires
components it never needed. As copied, the scaffold builds and shoots a placeholder screen, so the
pipeline is verifiable before any design work exists.

```
mockups/
├── index.html          contact sheet (generated — never hand-edited)
├── *.png               one per screen, plus the design-system sheet (generated, committed)
├── render-stamp.json   content hash per screen, written by shoot.sh (committed)
├── README.md
├── design-system.md
├── user-flow.md
├── assumptions.md      the gap ledger
└── src/
    ├── tokens.css      ← starter    the only place a colour or spacing value is defined
    ├── app.css         ← starter    component classes
    ├── lib.mjs         ← project    icon set + shared markup helpers (no template — write it)
    ├── screens.mjs     ← starter    one entry per screen; exports `meta` and the screen array
    ├── sheet.mjs       ← project    the design-system reference sheet (optional)
    ├── render.mjs      ← template   page template + hashing
    ├── build.mjs       ← template   src/out/*.html + index.html + manifests
    ├── shoot.sh        ← template   builds, renders every PNG, then stamps
    ├── check.mjs       ← template   fails if a committed PNG is stale
    └── out/            generated (gitignored)
```

Add `mockups/src/out/` to the repo's `.gitignore`.

## The screen object

`screens.mjs` default-exports an array of these. `add()` supplies the defaults.

```js
add({
  id: '09-logger',            // filename, and its order in the contact sheet
  group: 'Active workout',    // contact-sheet section
  screen: 'S5',               // plan reference, shown as the caption tag
  title: 'Logger — the core screen',
  note: 'Why this screen looks the way it does.',
  theme: 'light',             // or 'dark'
  html: `…`,
  // w, h        override the default viewport
  // frame       wrapper class name — 'phone' for a device frame. Opt-in: omit it for
  //             desktop windows and reference sheets, and do not set a default that
  //             assumes a platform the product does not have.
});
```

It also named-exports `meta`, which titles the contact sheet:

```js
export const meta = {
  project: 'Product name — mockups',
  subtitle: 'One sentence: what this set covers and at what size.',
  docs: ['design-system.md', 'user-flow.md', 'assumptions.md'],
};
```

## Viewports

Set the default in `add()`; override per screen with `w` / `h`.

| Target | Size | Frame |
|---|---|---|
| Phone | 390 × 844 | `frame: 'phone'` — device frame, status bar, home indicator |
| Tablet | 834 × 1112 | frame optional |
| Desktop, full-window | 1440 × 900 | omit `frame` |
| Desktop, floating panel | canvas ~1.2× the window, so the window sits on a rendered desktop | omit `frame` |
| Reference sheet | tall, e.g. 1100 × 2400 | omit `frame` |

Rendering is `--force-device-scale-factor=2`, so a 390 × 844 screen ships as a 780 × 1688 PNG.

A floating, always-on-top window gets a canvas larger than itself with the desktop drawn behind it.
Rendered on a blank page it misrepresents the only context it ever appears in. Keep whatever stands
in for the app underneath abstract — never legible content competing with the mockup.

A plan targeting both phone and desktop gets both rows for each screen whose layout genuinely
differs — not a mechanical doubling of the matrix.

## Why `build.mjs` rejects unfilled tokens

`--bg-canvas: ;` is valid CSS that resolves to nothing, so a token left blank in `tokens.css` shows
up as a missing background in one render and nowhere else. `build.mjs` refuses to build while any
remain and names them. A token this product does not need gets deleted, not left empty.

## Why the stamp exists

`build.mjs` and `shoot.sh` are separate steps, and `src/out/` is gitignored, so a source edit
without a re-render leaves a stale PNG that is invisible in review. `render.mjs` is the single
source of truth for what a screen's HTML is, so `build.mjs` and `check.mjs` can never disagree
about what a PNG should have been rendered from.

The digest covers markup, theme, and canvas size; the stylesheets are hashed separately because
they are shared — a token change must invalidate every screen at once. Content hashes rather than
mtimes: a fresh clone stamps every file with the checkout time, so mtime comparison is worthless in
CI, which is exactly where this needs to work.

`check.mjs` exits non-zero on drift and catches three cases: a screen whose markup changed, a
screen with no PNG, and a stamp entry for a screen that no longer exists. It works as a pre-commit
hook or a CI gate.

## What is committed, and why

`src/out/` is ignored — a pure intermediate that rebuilds in under a second with no browser.

The PNGs and `index.html` **are** committed despite being generated. They render inline in GitHub
and in PR review, which is the whole point of a design reference: nobody should need Node and a
headless Chrome to look at a screen. They are also not reproducible across platforms when the
markup uses a system font stack — `-apple-system` resolves to SF Pro on macOS and to something else
everywhere else, so a Linux CI would render visibly different type.

Nothing regenerates them automatically. Iterate with `node src/build.mjs` and a browser; re-shoot
only when the committed references should move.

## Chrome

`shoot.sh` defaults to Playwright's bundled headless shell and accepts an override:

```bash
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" bash src/shoot.sh
```

If neither exists, install one: `npx playwright install chromium`.

On macOS, Chrome cannot start inside a restrictive command sandbox — it dies with
`bootstrap_check_in … Permission denied (1100)` before writing anything, and the loop reports only
a missing PNG. Run `shoot.sh` outside the sandbox. Note it in the project README, since the next
person hits it too.

## README.md contents

Written last, and it is the entry point for everyone who did not build this:

1. What this is, how many screens, at what size, generated from what.
2. A table linking the three companion documents, marking the gap ledger **read first**.
3. **Look at them** — `open index.html` (works over `file://`; a `python3 -m http.server` fallback
   for browsers that block local file access), plus how to open one PNG and one live HTML page.
4. **Regenerate** — the three commands, and which to run while iterating.
5. **Staleness** — what the stamp is for and what `check.mjs` output looks like.
6. **Making changes** — the routing table: token → `tokens.css`; component → `app.css` /
   `lib.mjs`; one screen's content → `screens.mjs`; a new screen → another `add({…})`.
7. The layout tree above, and what is committed and why.
8. The screen table, grouped.
