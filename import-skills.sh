#!/usr/bin/env bash
# Finds real (non-symlinked) skill directories under ~/.claude/skills, ~/.agents/skills,
# and ~/.codex/skills that some other tool installed directly, lets you pick which ones
# to bring into this repo, and replaces them with symlinks (same pattern as install.sh).
set -euo pipefail

if ! command -v fzf >/dev/null 2>&1; then
  echo "This script needs fzf for the interactive picker. Install it with: brew install fzf" >&2
  exit 1
fi

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CLAUDE_SKILLS="$HOME/.claude/skills"
AGENTS_SKILLS="$HOME/.agents/skills"
CODEX_SKILLS="$HOME/.codex/skills"

# List real (non-symlink) skill dirs under a root: one name per line.
real_skill_names() {
  local root="$1"
  [ -d "$root" ] || return 0
  for entry in "$root"/*/; do
    [ -d "$entry" ] || continue
    local name
    name="$(basename "$entry")"
    case "$name" in
      .*) continue ;;
    esac
    [ -L "${entry%/}" ] && continue
    [ -f "$entry/SKILL.md" ] || continue
    echo "$name"
  done
}

contains() {
  local needle="$1" haystack="$2"
  case " $haystack " in
    *" $needle "*) return 0 ;;
    *) return 1 ;;
  esac
}

claude_names="$(real_skill_names "$CLAUDE_SKILLS" | tr '\n' ' ')"
agents_names="$(real_skill_names "$AGENTS_SKILLS" | tr '\n' ' ')"
codex_names="$(real_skill_names "$CODEX_SKILLS" | tr '\n' ' ')"

all_names="$(printf '%s\n%s\n%s\n' "$claude_names" "$agents_names" "$codex_names" | tr ' ' '\n' | sed '/^$/d' | sort -u)"

if [ -z "$all_names" ]; then
  echo "No unmanaged skills found under ~/.claude/skills, ~/.agents/skills, or ~/.codex/skills."
  exit 0
fi

fzf_lines=()
while IFS= read -r name; do
  [ -n "$name" ] || continue
  found=""
  contains "$name" "$claude_names" && found="$found claude"
  contains "$name" "$agents_names" && found="$found agents"
  contains "$name" "$codex_names" && found="$found codex"
  fzf_lines+=("$name  (found in:$found )")
done <<< "$all_names"

FZF_OPTS=(--height=80% --border --reverse)

selected="$(printf '%s\n' "${fzf_lines[@]}" | fzf "${FZF_OPTS[@]}" --multi \
  --header='↑/↓ to move, Tab or Space to select, Enter to confirm' \
  --prompt='Import into repo> ')"

if [ -z "$selected" ]; then
  echo "Nothing selected."
  exit 0
fi

# Ask a single-choice question via fzf. Prints the chosen option to stdout.
ask() {
  local header="$1"; shift
  printf '%s\n' "$@" | fzf "${FZF_OPTS[@]}" --header="$header" --prompt='> '
}

while IFS= read -r line; do
  [ -n "$line" ] || continue
  name="${line%%  (found in:*}"

  in_claude=false; in_agents=false; in_codex=false
  contains "$name" "$claude_names" && in_claude=true
  contains "$name" "$agents_names" && in_agents=true
  contains "$name" "$codex_names" && in_codex=true

  # Collect every real copy of this skill so we can check for divergent content.
  sources=()
  $in_claude && sources+=("$CLAUDE_SKILLS/$name")
  $in_agents && sources+=("$AGENTS_SKILLS/$name")
  $in_codex && sources+=("$CODEX_SKILLS/$name")

  if [ "${#sources[@]}" -gt 1 ]; then
    first="${sources[0]}"
    for other in "${sources[@]:1}"; do
      if ! diff -rq "$first" "$other" >/dev/null 2>&1; then
        echo "Skipping $name: found in multiple places with different content ($first vs $other). Resolve manually."
        continue 2
      fi
    done
  fi

  # Already spread across more than one location -> shared is the only sensible choice,
  # matching install.sh's shared-skills loop (linked into ~/.claude/skills and ~/.agents/skills).
  # Found in exactly one location -> ask whether to keep it tool-specific or make it shared.
  shared=false
  origin=""
  if [ "${#sources[@]}" -gt 1 ]; then
    shared=true
  elif $in_claude; then
    origin=claude
    choice="$(ask "$name found only in ~/.claude/skills — where should it live?" \
      "claude-only (claude/skills/, linked only into ~/.claude/skills)" \
      "shared (skills/, also linked into ~/.agents/skills)")"
    case "$choice" in
      shared*) shared=true ;;
      claude-only*) shared=false ;;
      *) echo "Skipping $name: no choice made."; continue ;;
    esac
  else
    origin="$($in_agents && echo agents || echo codex)"
    choice="$(ask "$name found only in ~/.$origin/skills — where should it live?" \
      "agents/codex-only (codex/skills/, linked only back into ~/.$origin/skills)" \
      "shared (skills/, also linked into ~/.claude/skills)")"
    case "$choice" in
      shared*) shared=true ;;
      agents/codex-only*) shared=false ;;
      *) echo "Skipping $name: no choice made."; continue ;;
    esac
  fi

  if $shared; then
    dest="$DOTFILES_DIR/skills/$name"
  elif [ "$origin" = "claude" ]; then
    dest="$DOTFILES_DIR/claude/skills/$name"
  else
    dest="$DOTFILES_DIR/codex/skills/$name"
  fi

  if [ -e "$dest" ]; then
    echo "Skipping $name: $dest already exists in the repo."
    continue
  fi

  mkdir -p "$(dirname "$dest")"
  mv "${sources[0]}" "$dest"
  echo "Moved $name -> $dest"

  for src in "${sources[@]:1}"; do
    rm -rf "$src"
  done

  if $shared; then
    mkdir -p "$CLAUDE_SKILLS" "$AGENTS_SKILLS"
    rm -f "$CLAUDE_SKILLS/$name" "$AGENTS_SKILLS/$name"
    ln -s "$dest" "$CLAUDE_SKILLS/$name"
    ln -s "$dest" "$AGENTS_SKILLS/$name"
    echo "Linked $CLAUDE_SKILLS/$name -> $dest"
    echo "Linked $AGENTS_SKILLS/$name -> $dest"
  elif [ "$origin" = "claude" ]; then
    mkdir -p "$CLAUDE_SKILLS"
    rm -f "$CLAUDE_SKILLS/$name"
    ln -s "$dest" "$CLAUDE_SKILLS/$name"
    echo "Linked $CLAUDE_SKILLS/$name -> $dest"
  elif [ "$origin" = "agents" ]; then
    mkdir -p "$AGENTS_SKILLS"
    rm -f "$AGENTS_SKILLS/$name"
    ln -s "$dest" "$AGENTS_SKILLS/$name"
    echo "Linked $AGENTS_SKILLS/$name -> $dest"
  else
    mkdir -p "$CODEX_SKILLS"
    rm -f "$CODEX_SKILLS/$name"
    ln -s "$dest" "$CODEX_SKILLS/$name"
    echo "Linked $CODEX_SKILLS/$name -> $dest"
  fi
done <<< "$selected"

echo
echo "Done. Review with git status in $DOTFILES_DIR, then commit."
