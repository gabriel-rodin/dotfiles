// Fails if any committed PNG no longer matches the source it was rendered from.
// Usage: node src/check.mjs   (from mockups/)
//
// Compares a content hash of every screen against render-stamp.json, which shoot.sh
// writes after a successful render. Content hashes rather than mtimes: a fresh clone
// stamps every file with the checkout time, so mtime comparison is useless in CI —
// which is exactly where this needs to work.

import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import screens, { meta } from './screens.mjs';
import { digest, digestStyles } from './render.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, '..');
const stampPath = resolve(root, 'render-stamp.json');

if (!existsSync(stampPath)) {
  console.error('render-stamp.json is missing. Run: bash src/shoot.sh');
  process.exit(1);
}

const stampFile = JSON.parse(readFileSync(stampPath, 'utf8'));
const stamp = stampFile.screens ?? {};
const stylesHash = digestStyles(
  readFileSync(resolve(here, 'tokens.css'), 'utf8'),
  readFileSync(resolve(here, 'app.css'), 'utf8'),
);

// `meta` (project title, subtitle, doc links) feeds index.html directly but isn't part
// of any screen's own digest, so it needs its own check — otherwise editing it without
// rebuilding leaves index.html stale with no warning.
const metaHash = createHash('sha256').update(JSON.stringify(meta)).digest('hex').slice(0, 16);
const metaStale = stampFile.meta !== metaHash;

const stale = [];
const missing = [];
const tampered = [];

for (const s of screens) {
  const pngPath = resolve(root, `${s.id}.png`);
  if (!existsSync(pngPath)) {
    missing.push(s.id);
    continue;
  }
  const entry = stamp[s.id];
  if (!entry || entry.digest !== digest(s, stylesHash)) {
    stale.push(s.id);
    continue;
  }
  // The digest matches, so the source hasn't changed since the last render — but the
  // committed PNG's own bytes might have been hand-edited afterward. shoot.sh stamps
  // each PNG's hash right after rendering it, so a mismatch here means the file on disk
  // is not what was actually rendered.
  const pngHash = createHash('sha256').update(readFileSync(pngPath)).digest('hex').slice(0, 16);
  if (entry.png !== pngHash) tampered.push(s.id);
}

const known = new Set(screens.map((s) => s.id));
const orphanedStamp = Object.keys(stamp).filter((id) => !known.has(id));
const orphanedFiles = readdirSync(root)
  .filter((f) => f.endsWith('.png'))
  .map((f) => f.slice(0, -4))
  .filter((id) => !known.has(id) && !orphanedStamp.includes(id));
const orphaned = [...new Set([...orphanedStamp, ...orphanedFiles])];

if (!stale.length && !missing.length && !orphaned.length && !tampered.length && !metaStale) {
  console.log(`✓ ${screens.length} PNGs match their sources`);
  process.exit(0);
}

if (missing.length) console.error(`Missing PNG (${missing.length}):\n  ${missing.join('\n  ')}`);
if (stale.length)
  console.error(`Stale — source changed since last render (${stale.length}):\n  ${stale.join('\n  ')}`);
if (tampered.length)
  console.error(
    `Tampered — PNG bytes don't match the last render, though the source is unchanged (${tampered.length}):\n  ${tampered.join('\n  ')}`,
  );
if (orphaned.length)
  console.error(
    `Orphaned — no longer a screen (${orphaned.length}):\n  ${orphaned.join('\n  ')}`,
  );
if (metaStale) console.error('index.html is stale — meta (project/subtitle/docs) changed since the last render.');

console.error('\nRe-render with: bash src/shoot.sh');
process.exit(1);
