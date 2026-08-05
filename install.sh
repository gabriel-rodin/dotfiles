#!/usr/bin/env bash
# Symlinks this repo's claude/, codex/, and skills/ config into their global locations.
# Existing real files/dirs at the target path are backed up with a .bak suffix.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ]; then
    rm "$dst"
  elif [ -e "$dst" ]; then
    mv "$dst" "$dst.bak"
    echo "Backed up existing $dst -> $dst.bak"
  fi
  ln -s "$src" "$dst"
  echo "Linked $dst -> $src"
}

link "$DOTFILES_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
link "$DOTFILES_DIR/codex/AGENTS.md" "$HOME/.codex/AGENTS.md"

for skill_dir in "$DOTFILES_DIR"/claude/skills/*/; do
  [ -d "$skill_dir" ] || continue
  name="$(basename "$skill_dir")"
  link "$DOTFILES_DIR/claude/skills/$name" "$HOME/.claude/skills/$name"
done

for skill_dir in "$DOTFILES_DIR"/codex/skills/*/; do
  [ -d "$skill_dir" ] || continue
  name="$(basename "$skill_dir")"
  link "$DOTFILES_DIR/codex/skills/$name" "$HOME/.codex/skills/$name"
done

# Reusable skills shared by both Claude and Codex.
for skill_dir in "$DOTFILES_DIR"/skills/*/; do
  [ -d "$skill_dir" ] || continue
  name="$(basename "$skill_dir")"
  link "$DOTFILES_DIR/skills/$name" "$HOME/.claude/skills/$name"
  link "$DOTFILES_DIR/skills/$name" "$HOME/.agents/skills/$name"
done

echo
echo "To verify the links:"
echo "  ls -la ~/.claude/CLAUDE.md ~/.codex/AGENTS.md ~/.claude/skills ~/.agents/skills ~/.codex/skills"
echo "or, if you have tree installed:"
echo "  ls -la ~/.claude/CLAUDE.md ~/.codex/AGENTS.md && tree ~/.claude/skills ~/.agents/skills ~/.codex/skills"
