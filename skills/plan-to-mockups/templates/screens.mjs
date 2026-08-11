// Screen definitions. Screen IDs and error codes refer to the implementation plan.
//
// Import the helpers this product's direction actually produced, once lib.mjs exists.
// There is no standard set — a phone app has a status bar and a tab bar, a desktop tool
// has a window and a footer hint strip, and neither should inherit the other's furniture.
// The example below is inline so this file runs before lib.mjs is written; replace it.

// import { ic, row, window } from './lib.mjs';
// import { sheet } from './sheet.mjs';

export const meta = {
  project: 'PRODUCT — mockups',
  subtitle:
    'N screens covering every screen, state, and recovery path in the implementation plan. '
    + 'Rendered at 390 × 844 @2x. Screen IDs and error codes match the plan.',
  docs: ['design-system.md', 'user-flow.md', 'assumptions.md'],
};

const S = [];
// Set w/h/frame from step 4's direction, not from habit. `frame` is a wrapper class
// name and is opt-in — add `frame: 'phone'` here only if this product is a phone app,
// and omit it for desktop windows and reference sheets. Set the default viewport to
// this product's target (see PIPELINE.md § Viewports); 390 × 844 is the phone one.
const add = (s) => S.push({ w: 390, h: 844, theme: 'light', ...s });

/* ─── sample data ──────────────────────────────────────────────────
   Real domain content, from the plan's own vocabulary. Shared across
   screens so a populated state and its empty state are the same screen
   with the list emptied, not two unrelated designs. */

// const ITEMS = [ … ];

/* ─── S1 … ─────────────────────────────────────────────────────────── */

add({
  id: '01-example',
  group: 'Launch',
  screen: 'S1',
  title: 'Example — replace me',
  note: 'One sentence on why this screen looks the way it does.',
  html: '<p>Replace me — the first real screen comes from the matrix.</p>',
});

export default S;
