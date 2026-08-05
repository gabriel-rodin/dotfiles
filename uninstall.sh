#!/usr/bin/env bash
# Removes symlinks created by install.sh, restoring any .bak backups it made.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

unlink_dst() {
  local dst="$1"
  if [ -L "$dst" ]; then
    local target
    target="$(cd "$(dirname "$dst")" && cd "$(dirname "$(readlink "$dst")")" && pwd)/$(basename "$(readlink "$dst")")" 2>/dev/null || target=""
    case "$target" in
      "$DOTFILES_DIR"/*)
        rm "$dst"
        echo "Removed $dst"
        ;;
      *)
        echo "Skipped $dst (not linked into $DOTFILES_DIR)"
        return
        ;;
    esac
  elif [ -e "$dst" ]; then
    echo "Skipped $dst (not a symlink)"
    return
  else
    return
  fi

  if [ -e "$dst.bak" ]; then
    mv "$dst.bak" "$dst"
    echo "Restored $dst.bak -> $dst"
  fi
}

unlink_dst "$HOME/.claude/CLAUDE.md"
unlink_dst "$HOME/.codex/AGENTS.md"

for skill_dir in "$DOTFILES_DIR"/claude/skills/*/; do
  [ -d "$skill_dir" ] || continue
  name="$(basename "$skill_dir")"
  unlink_dst "$HOME/.claude/skills/$name"
done

for skill_dir in "$DOTFILES_DIR"/codex/skills/*/; do
  [ -d "$skill_dir" ] || continue
  name="$(basename "$skill_dir")"
  unlink_dst "$HOME/.codex/skills/$name"
done

for skill_dir in "$DOTFILES_DIR"/skills/*/; do
  [ -d "$skill_dir" ] || continue
  name="$(basename "$skill_dir")"
  unlink_dst "$HOME/.claude/skills/$name"
  unlink_dst "$HOME/.agents/skills/$name"
done
