#!/usr/bin/env bash
# Builds the screens, then renders every one to a @2x PNG in mockups/.
# Usage: bash src/shoot.sh   (from mockups/)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$HERE")"

if [ -z "${CHROME:-}" ]; then
  CHROME="$(ls -d "$HOME"/Library/Caches/ms-playwright/chromium_headless_shell-*/chrome-headless-shell-*/chrome-headless-shell 2>/dev/null | tail -1 || true)"
fi

[ -n "$CHROME" ] && [ -x "$CHROME" ] || {
  echo "Chrome not found — set CHROME=/path/to/chrome, or run: npx playwright install chromium"
  exit 1
}

# Always build first: rendering stale HTML produces PNGs that look freshly
# generated and are not.
node "$HERE/build.mjs"

# Templated so TMPDIR is honoured — bare `mktemp -d` ignores it on macOS.
PROFILE="$(mktemp -d "${TMPDIR:-/tmp}/mockshot.XXXXXX")"
trap 'rm -rf "$PROFILE"' EXIT

while read -r id w h; do
  [ -z "$id" ] && continue
  "$CHROME" \
    --disable-gpu --hide-scrollbars --disable-lcd-text \
    --user-data-dir="$PROFILE" \
    --force-device-scale-factor=2 \
    --window-size="$w,$h" \
    --screenshot="$ROOT/$id.png" \
    "file://$HERE/out/$id.html" >/dev/null 2>&1
  [ -s "$ROOT/$id.png" ] || { echo "render failed: $id"; exit 1; }
  printf '  %s\n' "$id.png"
done < "$HERE/out/manifest.txt"

# Only stamp once every screen rendered, so a partial run can never claim to be current.
# The stamp pairs each screen's source digest with its rendered PNG's own byte hash, so
# check.mjs can tell a hand-edited PNG (source digest matches, PNG bytes don't) from a
# stale one (source digest changed). Paths passed as argv, not spliced into the JS
# source — a path with a quote would break it.
node --input-type=module -e '
import { readFileSync, writeFileSync } from "node:fs";
import { createHash } from "node:crypto";
const [manifestPath, root, stampPath] = process.argv.slice(1);
const manifest = JSON.parse(readFileSync(manifestPath, "utf8"));
const screens = {};
for (const [id, digest] of Object.entries(manifest.screens)) {
  const png = readFileSync(`${root}/${id}.png`);
  screens[id] = { digest, png: createHash("sha256").update(png).digest("hex").slice(0, 16) };
}
writeFileSync(stampPath, JSON.stringify({ meta: manifest.meta, screens }, null, 2) + "\n");
' "$HERE/out/manifest.json" "$ROOT" "$ROOT/render-stamp.json"

echo "done — $(node -p 'Object.keys(require(process.argv[1]).screens).length' "$ROOT/render-stamp.json") screens stamped"
