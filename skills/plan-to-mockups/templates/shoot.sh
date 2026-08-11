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
cp "$HERE/out/manifest.json" "$ROOT/render-stamp.json"

# Path passed as argv, not spliced into the JS source — a path with a quote would break it.
echo "done — $(node -p 'Object.keys(require(process.argv[1]).screens).length' "$ROOT/render-stamp.json") screens stamped"
