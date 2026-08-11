// Fails if any committed PNG no longer matches the source it was rendered from.
// Usage: node src/check.mjs   (from mockups/)
//
// Compares a content hash of every screen against render-stamp.json, which shoot.sh
// writes after a successful render. Content hashes rather than mtimes: a fresh clone
// stamps every file with the checkout time, so mtime comparison is useless in CI —
// which is exactly where this needs to work.

import { readFileSync, existsSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import screens from './screens.mjs';
import { digest, digestStyles } from './render.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, '..');
const stampPath = resolve(root, 'render-stamp.json');

if (!existsSync(stampPath)) {
  console.error('render-stamp.json is missing. Run: bash src/shoot.sh');
  process.exit(1);
}

const stamp = JSON.parse(readFileSync(stampPath, 'utf8')).screens ?? {};
const stylesHash = digestStyles(
  readFileSync(resolve(here, 'tokens.css'), 'utf8'),
  readFileSync(resolve(here, 'app.css'), 'utf8'),
);

const stale = [];
const missing = [];

for (const s of screens) {
  if (!existsSync(resolve(root, `${s.id}.png`))) missing.push(s.id);
  else if (stamp[s.id] !== digest(s, stylesHash)) stale.push(s.id);
}

const known = new Set(screens.map((s) => s.id));
const orphaned = Object.keys(stamp).filter((id) => !known.has(id));

if (!stale.length && !missing.length && !orphaned.length) {
  console.log(`✓ ${screens.length} PNGs match their sources`);
  process.exit(0);
}

if (missing.length) console.error(`Missing PNG (${missing.length}):\n  ${missing.join('\n  ')}`);
if (stale.length)
  console.error(`Stale — source changed since last render (${stale.length}):\n  ${stale.join('\n  ')}`);
if (orphaned.length)
  console.error(
    `Orphaned — in the stamp but no longer a screen (${orphaned.length}):\n  ${orphaned.join('\n  ')}`,
  );

console.error('\nRe-render with: bash src/shoot.sh');
process.exit(1);
