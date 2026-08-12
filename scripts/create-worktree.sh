#!/usr/bin/env bash
# Creates a git worktree under .claude/worktrees/<slug> for local (non-Docker) dev,
# ready to run via .local/scripts/dev.sh.
#
# This script does the WIRING only: copies gitignored secrets/env files as-is,
# symlinks backend/data back to the main worktree, copies settings.local.json so
# hooks still work inside the new worktree, links local agent skills so Codex has
# the same capabilities in each checkout, and symlinks AGENTS.md/CLAUDE.md back to
# the main checkout. The scripts themselves are NOT copied — they live in .local/,
# which is symlinked below, so every worktree runs the main checkout's copy.
#
# It does NOT install dependencies or build shared — run your project's setup
# script by hand afterwards. Same script repairs an existing checkout later,
# without recreating it.
#
# Finishes by opening the new worktree in its own VS Code window; set NO_CODE=1 to
# skip that.
#
# Usage: .local/scripts/create-worktree.sh <branch-name>
#   e.g. .local/scripts/create-worktree.sh dev/issue-50
#
# To run the servers, from the worktree:
#   .local/scripts/dev.sh              default ports (3000/5173), one at a time
#   .local/scripts/dev.sh --isolated   own hostname + free ports, several at once

set -euo pipefail

# `--show-toplevel` is the *current* working tree, so running this from inside a
# worktree (easy to do — .local/ is symlinked into every one) would
# nest a worktree under a worktree and point every symlink below at the
# intermediate checkout instead of the main one. `--git-common-dir` always
# resolves to the main checkout's .git regardless of where we're standing; the
# `cd`+`pwd` wrapper is required because it returns a path relative to cwd when
# we're already in the main checkout.
REPO_ROOT="$(cd "$(git rev-parse --git-common-dir)/.." && pwd)"
CURRENT_ROOT="$(cd "$(git rev-parse --show-toplevel)" && pwd)"
if [[ "$CURRENT_ROOT" != "$REPO_ROOT" ]]; then
  echo "Error: run this from the main checkout ($REPO_ROOT), not from the worktree at $CURRENT_ROOT." >&2
  exit 1
fi
cd "$REPO_ROOT"

BRANCH="${1:-}"
if [[ -z "$BRANCH" ]]; then
  echo "Usage: $0 <branch-name>" >&2
  exit 1
fi

SLUG="${BRANCH//\//-}"
WORKTREE_DIR="$REPO_ROOT/.claude/worktrees/$SLUG"

if [[ -e "$WORKTREE_DIR" ]]; then
  echo "Error: $WORKTREE_DIR already exists." >&2
  exit 1
fi

mkdir -p "$REPO_ROOT/.claude/worktrees"
git worktree prune

# --- ensure symlinked paths still read as ignored in every worktree -------
# A trailing-slash gitignore pattern (e.g. "node_modules/" in .gitignore) only
# matches a real directory, never a symlink — so without a slash-less entry
# here, the symlinks this script creates would show up as untracked.
GIT_COMMON_DIR="$(git rev-parse --git-common-dir)"
EXCLUDE_FILE="$GIT_COMMON_DIR/info/exclude"
mkdir -p "$(dirname "$EXCLUDE_FILE")"
touch "$EXCLUDE_FILE"
if ! grep -qx "backend/data" "$EXCLUDE_FILE" 2>/dev/null; then
  cat >> "$EXCLUDE_FILE" <<'EOF'

# Worktree tooling (.local/scripts/create-worktree.sh) symlinks these instead
# of copying them; slash-less entries so symlinks match too.
backend/data
.agents/skills
EOF
fi

if ! grep -qx ".agents/skills" "$EXCLUDE_FILE" 2>/dev/null; then
  echo ".agents/skills" >> "$EXCLUDE_FILE"
fi

# Same trailing-slash problem: the existing ".local/" entry matches a real
# directory, so the symlink created below would show up as untracked without a
# slash-less entry as well (verified — it reported "?? .local").
if ! grep -qx ".local" "$EXCLUDE_FILE" 2>/dev/null; then
  echo ".local" >> "$EXCLUDE_FILE"
fi

# --- create the worktree ---------------------------------------------------
git fetch origin --quiet || true

if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  git worktree add "$WORKTREE_DIR" "$BRANCH"
elif git show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
  git worktree add -b "$BRANCH" "$WORKTREE_DIR" "origin/$BRANCH"
else
  git worktree add -b "$BRANCH" "$WORKTREE_DIR"
fi

# --- symlink backend/data (shared MySQL instance means DB rows referencing
# audio messages must resolve to the same files across every worktree) -----
if [[ -d "$REPO_ROOT/backend/data" ]]; then
  ln -s "$REPO_ROOT/backend/data" "$WORKTREE_DIR/backend/data"
fi

# --- copy gitignored .claude scripts/settings (needed for hooks) ----------
mkdir -p "$WORKTREE_DIR/.claude"
[[ -f "$REPO_ROOT/.claude/settings.local.json" ]] && cp "$REPO_ROOT/.claude/settings.local.json" "$WORKTREE_DIR/.claude/"

# --- symlink agents/skills (read-only config; keeps worktree in sync with
# any later edits in the main checkout instead of going stale). Guarded with
# `! -e` on the destination too: if the target repo tracks a path we'd
# otherwise symlink over, `git worktree add` already created a real file
# there, and `ln -s` would fail (fatal under `set -e`, aborting before the
# VS Code launch below ever runs) ------------------------------------------
[[ -d "$REPO_ROOT/.claude/agents" && ! -e "$WORKTREE_DIR/.claude/agents" ]] && ln -s "$REPO_ROOT/.claude/agents" "$WORKTREE_DIR/.claude/agents"
[[ -d "$REPO_ROOT/.claude/skills" && ! -e "$WORKTREE_DIR/.claude/skills" ]] && ln -s "$REPO_ROOT/.claude/skills" "$WORKTREE_DIR/.claude/skills"

# --- symlink AGENTS.md/CLAUDE.md/.npmrc (gitignored, personal; not brought in
# by `git worktree add` since they're untracked, so every worktree needs its
# own link back to stay in sync with the main checkout. REPO_ROOT/CLAUDE.md is
# itself just a symlink to AGENTS.md, so both worktree links point at
# REPO_ROOT/AGENTS.md directly). Same for backend/frontend's own AGENTS.md/
# CLAUDE.md -------------------
[[ -f "$REPO_ROOT/AGENTS.md" && ! -e "$WORKTREE_DIR/AGENTS.md" ]] && ln -s "$REPO_ROOT/AGENTS.md" "$WORKTREE_DIR/AGENTS.md"
[[ -f "$REPO_ROOT/AGENTS.md" && ! -e "$WORKTREE_DIR/CLAUDE.md" ]] && ln -s "$REPO_ROOT/AGENTS.md" "$WORKTREE_DIR/CLAUDE.md"
[[ -f "$REPO_ROOT/backend/AGENTS.md" && ! -e "$WORKTREE_DIR/backend/AGENTS.md" ]] && ln -s "$REPO_ROOT/backend/AGENTS.md" "$WORKTREE_DIR/backend/AGENTS.md"
[[ -f "$REPO_ROOT/backend/AGENTS.md" && ! -e "$WORKTREE_DIR/backend/CLAUDE.md" ]] && ln -s "$REPO_ROOT/backend/AGENTS.md" "$WORKTREE_DIR/backend/CLAUDE.md"
[[ -f "$REPO_ROOT/frontend/AGENTS.md" && ! -e "$WORKTREE_DIR/frontend/AGENTS.md" ]] && ln -s "$REPO_ROOT/frontend/AGENTS.md" "$WORKTREE_DIR/frontend/AGENTS.md"
[[ -f "$REPO_ROOT/frontend/AGENTS.md" && ! -e "$WORKTREE_DIR/frontend/CLAUDE.md" ]] && ln -s "$REPO_ROOT/frontend/AGENTS.md" "$WORKTREE_DIR/frontend/CLAUDE.md"
[[ -f "$REPO_ROOT/.npmrc" && ! -e "$WORKTREE_DIR/.npmrc" ]] && ln -s "$REPO_ROOT/.npmrc" "$WORKTREE_DIR/.npmrc"

# --- symlink local Codex skills (keeps worktree Codex capabilities in sync)
if [[ -d "$REPO_ROOT/.agents/skills" && ! -e "$WORKTREE_DIR/.agents/skills" ]]; then
  mkdir -p "$WORKTREE_DIR/.agents"
  ln -s "$REPO_ROOT/.agents/skills" "$WORKTREE_DIR/.agents/skills"
fi

# --- symlink .local (personal working files; linked rather than copied so
# later edits in the main checkout reach every existing worktree) ---------
[[ -d "$REPO_ROOT/.local" && ! -e "$WORKTREE_DIR/.local" ]] && ln -s "$REPO_ROOT/.local" "$WORKTREE_DIR/.local"

# --- symlink .vscode/settings.json so worktree windows inherit the main
# checkout's editor config and stay in sync with later edits there.
#
# The FILE is linked, not the .vscode directory: the ignore rule is
# ".gitignore:28 -> .vscode/settings.json", a file pattern, which matches a
# symlink at that path. A directory symlink is not matched by it and shows up as
# "?? .vscode" (verified). Linking the file also avoids a blanket ".vscode" entry
# in info/exclude, which would hide any launch.json/extensions.json the team may
# track under .vscode/ later (nothing is tracked there today).
if [[ -f "$REPO_ROOT/.vscode/settings.json" && ! -e "$WORKTREE_DIR/.vscode/settings.json" ]]; then
  mkdir -p "$WORKTREE_DIR/.vscode"
  ln -s "$REPO_ROOT/.vscode/settings.json" "$WORKTREE_DIR/.vscode/settings.json"
fi


# --- copy gitignored secrets/env files as-is (same default ports as main) -
[[ -f "$REPO_ROOT/.env" ]] && cp "$REPO_ROOT/.env" "$WORKTREE_DIR/.env"
[[ -f "$REPO_ROOT/backend/.env" ]] && cp "$REPO_ROOT/backend/.env" "$WORKTREE_DIR/backend/.env"

MEDIA_ENV_SRC="$REPO_ROOT/media-processing/.env"
[[ -f "$MEDIA_ENV_SRC" ]] || MEDIA_ENV_SRC="$REPO_ROOT/media-processing/.env.example"
[[ -f "$MEDIA_ENV_SRC" ]] && cp "$MEDIA_ENV_SRC" "$WORKTREE_DIR/media-processing/.env"

# NOTE: dependencies are deliberately NOT installed here. setup-checkout.sh is
# run by hand (see the printed steps below) so this script stays fast and never
# spends a minute on npm without being asked. The wiring above is complete, which
# is what lets that step run afterwards: the .npmrc symlink already exists, so
# npm honours its cache=.npm-cache instead of the global cache.

echo ""
echo "Worktree created: $WORKTREE_DIR"
echo "Branch:           $BRANCH"
echo "No node_modules yet — run your project's setup script by hand."
echo ""
echo "To close it later, from $REPO_ROOT:"
echo "  .local/scripts/close-worktree.sh $BRANCH"
echo ""

# --- open the worktree in its own VS Code window -----------------------------
# A SEPARATE window per checkout matters here: this worktree lives inside the
# main repo, so a single window covering both would watch and index two full
# copies of the monorepo (plus two node_modules) and get killed. The main
# checkout's .vscode/settings.json excludes .claude/worktrees for that reason;
# rooting a window at the worktree itself keeps each window to one tree.
# `command -v` guard: `code` is absent if the VS Code shell command was never
# installed, and set -e would otherwise abort here after all the real work.
if [[ -z "${NO_CODE:-}" ]] && command -v code >/dev/null 2>&1; then
  code "$WORKTREE_DIR"
else
  if [[ -z "${NO_CODE:-}" ]]; then
    echo "Skipped opening VS Code: no 'code' command on PATH."
    echo "(VS Code > Command Palette > 'Shell Command: Install code command in PATH')"
  fi
fi
echo ""
