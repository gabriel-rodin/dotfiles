// Renders every screen to a standalone HTML file, plus a browsable contact sheet.
// Usage: node src/build.mjs   (from mockups/)

import { writeFileSync, readFileSync, mkdirSync, rmSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import screens, { meta } from './screens.mjs';
import { createHash } from 'node:crypto';
import { page, digest, digestStyles } from './render.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const outDir = resolve(here, 'out');

// Captions are prose — an "&" or "<" in a title would otherwise corrupt index.html.
const esc = (v) =>
  String(v ?? '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]);

rmSync(outDir, { recursive: true, force: true });
mkdirSync(outDir, { recursive: true });

// A repeated id would silently overwrite the earlier screen's HTML and PNG with no error.
const seenIds = new Set();
for (const s of screens) {
  if (seenIds.has(s.id)) {
    console.error(`Duplicate screen id "${s.id}" — ids must be unique.`);
    process.exit(1);
  }
  seenIds.add(s.id);
}

const tokensCss = readFileSync(resolve(here, 'tokens.css'), 'utf8');

// An unfilled token (`--bg-canvas: ;`) is valid CSS that resolves to nothing, so it
// fails invisibly in the render. Fail here instead. A token this product does not need
// gets deleted, not left blank.
const unfilled = [...tokensCss.matchAll(/(--[\w-]+)\s*:\s*(?=;)/g)].map((m) => m[1]);
if (unfilled.length) {
  console.error(
    `tokens.css has ${unfilled.length} unfilled token(s):\n  ${unfilled.join('\n  ')}\n\n`
      + 'Give each a value, or delete the ones this product does not need.',
  );
  process.exit(1);
}

// Dark is not automatically derived — a token declared under :root/[data-theme='light']
// but never restated under [data-theme='dark'] silently falls through to the light value,
// so a dark screen looks light with no error anywhere.
const block = (css, selector) => {
  const m = selector.exec(css);
  if (!m) return '';
  const start = css.indexOf('{', m.index);
  const end = css.indexOf('}', start);
  return css.slice(start + 1, end);
};
const tokenNames = (css) => new Set([...css.matchAll(/(--[\w-]+)\s*:/g)].map((m) => m[1]));
const lightNames = tokenNames(block(tokensCss, /\[data-theme=['"]light['"]\]\s*\{/));
const darkNames = tokenNames(block(tokensCss, /\[data-theme=['"]dark['"]\]\s*\{/));
const missingDark = [...lightNames].filter((n) => !darkNames.has(n));
if (missingDark.length) {
  console.error(
    `[data-theme='dark'] is missing ${missingDark.length} token(s) declared for light:\n  ${missingDark.join('\n  ')}\n\n`
      + 'Restate each, even if the value is intentionally identical.',
  );
  process.exit(1);
}

const stylesHash = digestStyles(tokensCss, readFileSync(resolve(here, 'app.css'), 'utf8'));

for (const s of screens) {
  writeFileSync(resolve(outDir, `${s.id}.html`), page(s));
}

// Contact sheet
const groups = [...new Set(screens.map((s) => s.group))];
const section = (g) => {
  const items = screens.filter((s) => s.group === g);
  return `<section>
  <h2>${esc(g)}</h2>
  <div class="grid">
    ${items
      .map(
        (s) => `<figure>
      <a href="${s.id}.png"><img src="${s.id}.png" alt="${esc(s.title)}" loading="lazy"></a>
      <figcaption>
        <span class="tag">${esc(s.screen)}</span>
        <b>${esc(s.title)}</b>
        <span class="file">${s.id}.png</span>
        <p>${esc(s.note)}</p>
      </figcaption>
    </figure>`,
      )
      .join('')}
  </div>
</section>`;
};

const index = `<!doctype html>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${esc(meta.project)}</title>
<link rel="stylesheet" href="src/tokens.css">
<style>
  body{font-family:var(--font);background:var(--bg-canvas);color:var(--text-primary);margin:0;padding:48px 32px 96px}
  .wrap{max-width:1360px;margin:0 auto}
  h1{font-size:30px;letter-spacing:-.02em;margin:0}
  .sub{color:var(--text-secondary);font-size:16px;line-height:24px;margin-top:10px;max-width:62ch}
  .links{margin-top:20px;display:flex;gap:16px;font-size:14px}
  .links a{color:var(--brand-base)}
  h2{font-size:11px;letter-spacing:.09em;text-transform:uppercase;color:var(--text-tertiary);
     margin:56px 0 18px;padding-bottom:10px;border-bottom:1px solid var(--border-subtle)}
  .grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:36px 28px}
  figure{margin:0}
  img{width:100%;display:block;border-radius:14px;border:1px solid var(--border-subtle);background:var(--bg-surface)}
  figcaption{margin-top:12px;font-size:13px;line-height:19px}
  figcaption b{display:block;margin-top:4px;font-size:14px}
  .tag{font-size:10px;letter-spacing:.08em;text-transform:uppercase;color:var(--brand-base);font-weight:700}
  .file{display:block;color:var(--text-tertiary);font-size:11px;margin-top:2px}
  figcaption p{color:var(--text-secondary);margin:8px 0 0}
</style>
<body data-theme="light">
<div class="wrap">
  <h1>${esc(meta.project)}</h1>
  <p class="sub">${esc(meta.subtitle)}</p>
  <div class="links">
    ${(meta.docs || []).map((d) => `<a href="${d}">${esc(d)}</a>`).join('')}
  </div>
  ${groups.map(section).join('')}
</div>
`;
writeFileSync(resolve(here, '..', 'index.html'), index);

// Manifest for the screenshot loop
writeFileSync(
  resolve(outDir, 'manifest.txt'),
  screens.map((s) => `${s.id} ${s.w} ${s.h}`).join('\n') + '\n',
);

// Content stamp. shoot.sh promotes this to ../render-stamp.json after a successful
// render, so check.mjs can tell whether the committed PNGs and index.html match the
// sources. `meta` feeds index.html directly (title, subtitle, doc links) but touches no
// screen's own digest, so it is hashed separately — otherwise editing it would go
// undetected by check.mjs. Deliberately has no timestamp — re-rendering unchanged
// screens must not produce a diff.
writeFileSync(
  resolve(outDir, 'manifest.json'),
  JSON.stringify(
    {
      meta: createHash('sha256').update(JSON.stringify(meta)).digest('hex').slice(0, 16),
      screens: Object.fromEntries(screens.map((s) => [s.id, digest(s, stylesHash)])),
    },
    null,
    2,
  ) + '\n',
);

console.log(`built ${screens.length} screens`);
