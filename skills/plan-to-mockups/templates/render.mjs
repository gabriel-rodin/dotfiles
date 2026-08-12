// Single source of truth for what a screen's HTML is, so build.mjs and check.mjs
// can never disagree about what a PNG should have been rendered from.

import { createHash } from 'node:crypto';

export function page(s) {
  return `<!doctype html>
<meta charset="utf-8">
<title>${s.title}</title>
<link rel="stylesheet" href="../tokens.css">
<link rel="stylesheet" href="../app.css">
<!-- min-height + scroll, not a hard height+overflow:hidden: shoot.sh screenshots only the
     --window-size viewport, so this never changes the PNG, but it lets content taller than s.h
     scroll into view when the file is opened directly — a clipped tall sheet (00-design-system,
     e.g.) is then visible and scrollable instead of silently cut off with no way to see the rest. -->
<style>html,body{width:${s.w}px;min-height:${s.h}px;overflow-y:auto;overflow-x:hidden}</style>
<body data-theme="${s.theme}">
${s.frame ? `<div class="${s.frame}">${s.html}</div>` : s.html}
`;
}

// Covers everything that changes the pixels (markup, theme, canvas size) plus the
// contact-sheet caption fields, which live only in index.html and never touch page(s) —
// without them, editing a caption without re-rendering would pass check.mjs silently.
// The stylesheets are hashed separately by digestStyles() — they are shared, so a
// token change must invalidate every screen at once.
export function digest(s, stylesHash) {
  return createHash('sha256')
    .update(`${s.w}x${s.h}\n${stylesHash}\n`)
    .update(page(s))
    .update(`\n${s.group}\n${s.screen}\n${s.note}\n`)
    .digest('hex')
    .slice(0, 16);
}

export function digestStyles(tokensCss, appCss) {
  return createHash('sha256').update(tokensCss).update(appCss).digest('hex').slice(0, 16);
}
