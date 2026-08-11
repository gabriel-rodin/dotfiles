// Single source of truth for what a screen's HTML is, so build.mjs and check.mjs
// can never disagree about what a PNG should have been rendered from.

import { createHash } from 'node:crypto';

export function page(s) {
  return `<!doctype html>
<meta charset="utf-8">
<title>${s.title}</title>
<link rel="stylesheet" href="../tokens.css">
<link rel="stylesheet" href="../app.css">
<style>html,body{width:${s.w}px;height:${s.h}px;overflow:hidden}</style>
<body data-theme="${s.theme}">
${s.frame ? `<div class="${s.frame}">${s.html}</div>` : s.html}
`;
}

// Covers everything that changes the pixels: markup, theme, and canvas size.
// The stylesheets are hashed separately by digestStyles() — they are shared, so a
// token change must invalidate every screen at once.
export function digest(s, stylesHash) {
  return createHash('sha256')
    .update(`${s.w}x${s.h}\n${stylesHash}\n`)
    .update(page(s))
    .digest('hex')
    .slice(0, 16);
}

export function digestStyles(tokensCss, appCss) {
  return createHash('sha256').update(tokensCss).update(appCss).digest('hex').slice(0, 16);
}
