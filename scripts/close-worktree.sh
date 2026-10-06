#!/usr/bin/env bash
# Closes a worktree created by create-worktree.sh: merges its gitignored
# ./plans/ and ./pr-reviews/ folders back into the repo root (these hold
# per-branch design docs / PR review notes that would otherwise be lost when
# the worktree directory is removed), removes the worktree, then deletes the
# local branch it was checked out on. Files already tracked by git (e.g. a
# committed project plan) are skipped -- those are preserved by history/the
# branch merge already, not by this copy-out.
#
# Usage: .local/scripts/close-worktree.sh [branch-name-or-slug] [--force]
#   e.g. .local/scripts/close-worktree.sh dev/issue-50
#
# With no argument it lists the open worktrees and lets you pick one with the
# up/down arrows (or j/k), Enter to confirm, q or ESC to cancel. Needs a TTY; when
# stdin/stdout is not a terminal it prints the usage line instead, so scripted
# callers still fail loudly rather than hanging on input.
#
# Merge targets (never overwrites existing files — numbers around collisions):
#   - plans/<branch>/plan.md — every file under the worktree's plans/ (any
#     depth/name) is consolidated here, oldest-by-mtime first as plan.md, then
#     plan (1).md, plan (2).md, ... so the highest number is always the latest.
#   - pr-reviews/<PR-number>/ — every file from the worktree's matching
#     PR-<number> folder (review.md, followup.md, etc.) merges into the same
#     PR-<number> folder at the repo root; only a colliding filename gets
#     numbered (review.md -> review (1).md), so multiple review passes on the
#     same PR end up together instead of in separate PR-<number> (1) folders.
#
# --force: passed through to `git worktree remove` (drops uncommitted changes
# in the worktree) and uses `git branch -D` instead of -d (deletes even if
# unmerged). Without it, either step failing just prints git's own error and
# leaves the worktree/branch in place so nothing is lost silently -- except
# that branch deletion also succeeds (without --force) when the branch isn't
# merged into HEAD but is fully merged into some other local branch (e.g. a
# stacked branch merged into its parent feature branch).

set -euo pipefail

# `--show-toplevel` is the *current* working tree, so running this from inside a
# worktree would resolve WORKTREE_DIR/plans/pr-reviews against that checkout
# rather than the main one. `--git-common-dir` always resolves to the main
# checkout's .git regardless of where we're standing; the `cd`+`pwd` wrapper is
# required because it returns a path relative to cwd when we're already there.
REPO_ROOT="$(cd "$(git rev-parse --git-common-dir)/.." && pwd)"
CURRENT_ROOT="$(cd "$(git rev-parse --show-toplevel)" && pwd)"
if [[ "$CURRENT_ROOT" != "$REPO_ROOT" ]]; then
  echo "Error: run this from the main checkout ($REPO_ROOT), not from the worktree at $CURRENT_ROOT." >&2
  exit 1
fi
cd "$REPO_ROOT"

INPUT=""
FORCE=""
for arg in "$@"; do
  case "$arg" in
  --force) FORCE="--force" ;; # accepted in either position, so `--force` alone
  *) INPUT="$arg" ;;          # still leaves INPUT empty and opens the picker
  esac
done

# --- no argument: pick a worktree interactively -----------------------------
# Hand-rolled rather than using `select` (numbered, no arrow keys) or fzf (works,
# but adds a dependency this repo's tooling otherwise has none of). Written for
# bash 3.2, the macOS system bash: no mapfile/readarray, no associative arrays.
if [[ -z "$INPUT" ]]; then
  if [[ ! -t 0 || ! -t 1 ]]; then
    echo "Usage: $0 <branch-name-or-slug> [--force]" >&2
    echo "(no TTY, so the interactive picker cannot run — pass the branch name)" >&2
    exit 1
  fi

  # Collect slugs under .claude/worktrees/ that git still knows about. Sorted so
  # the order is stable between runs.
  PICK_SLUGS=()
  PICK_BRANCHES=()
  PICK_LABELS=()
  while IFS= read -r wt; do
    [[ -n "$wt" ]] || continue
    case "$wt" in
    "$REPO_ROOT/.claude/worktrees/"*) ;;
    *) continue ;;
    esac
    slug="${wt##*/}"
    branch="$(git -C "$wt" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
    PICK_SLUGS[${#PICK_SLUGS[@]}]="$slug"
    PICK_BRANCHES[${#PICK_BRANCHES[@]}]="$branch"
    PICK_LABELS[${#PICK_LABELS[@]}]="$(printf '%-28s %s' "$slug" "$branch")"
  done < <(git worktree list --porcelain | awk '/^worktree /{print substr($0,10)}' | sort)

  if [[ ${#PICK_SLUGS[@]} -eq 0 ]]; then
    echo "No worktrees under $REPO_ROOT/.claude/worktrees to close." >&2
    exit 1
  fi

  # The shared parent path is named once here instead of being repeated on every
  # row, where it would cost ~50 columns and discriminate nothing.
  echo "Worktrees in $REPO_ROOT/.claude/worktrees"
  echo "Select one to close (up/down, Enter to confirm, q to cancel)"
  echo ""
  # Header sits outside draw(): it never changes, and the redraw below only jumps
  # back over the list rows, so it stays put. Same 2-space + %-28s layout as the
  # rows so the columns line up. The two values look near-identical for a branch
  # like dev/issue-93 (the directory is just the branch with slashes flattened),
  # which is exactly why they need labelling.
  printf '\033[2m  %-28s %s\033[0m\n' 'DIRECTORY' 'BRANCH'
  sel=0
  draw() {
    local i
    for ((i = 0; i < ${#PICK_LABELS[@]}; i++)); do
      if ((i == sel)); then
        printf '\033[7m> %s\033[0m\n' "${PICK_LABELS[$i]}" # reverse video
      else
        printf '  %s\n' "${PICK_LABELS[$i]}"
      fi
    done
  }
  draw
  while true; do
    IFS= read -rsn1 key || { echo "" && exit 1; }
    case "$key" in
    $'\x1b') # escape: could be a bare ESC or a CSI arrow sequence
      # Integer timeout only: bash 3.2 (macOS system bash) rejects `-t 0.01` with
      # "invalid timeout specification". An arrow returns immediately once its 2
      # remaining bytes arrive; only a lone ESC waits out the second.
      IFS= read -rsn2 -t 1 rest || rest=""
      case "$rest" in
      '[A') ((sel > 0)) && sel=$((sel - 1)) ;;
      '[B') ((sel < ${#PICK_SLUGS[@]} - 1)) && sel=$((sel + 1)) ;;
      '') echo "" && echo "Cancelled." && exit 1 ;;
      esac
      ;;
    'k') ((sel > 0)) && sel=$((sel - 1)) ;; # vi keys, since they cost nothing
    'j') ((sel < ${#PICK_SLUGS[@]} - 1)) && sel=$((sel + 1)) ;;
    'q') echo "" && echo "Cancelled." && exit 1 ;;
    '') break ;; # Enter
    esac
    # Redraw in place: jump back over the list we just printed.
    printf '\033[%dA' "${#PICK_LABELS[@]}"
    draw
  done

  INPUT="${PICK_SLUGS[$sel]}"
  PICKED=1 # gates the dirty-worktree prompt further down: a guided flow asks,
  # whereas an explicitly named branch gets told the flag, like any CLI.
  echo ""

  # Enter acts immediately on a destructive action, so confirm unless --force was
  # given (which already means "skip git's safety checks", so also skip this one).
  if [[ "$FORCE" != "--force" ]]; then
    # Spelled out on separate labelled lines: the directory and the branch differ
    # only by slash-vs-dash, so a single sentence naming both reads as a stutter
    # and hides which one is being deleted.
    echo "Close worktree:  $INPUT"
    echo "Delete branch:   ${PICK_BRANCHES[$sel]}"
    printf 'Proceed? [y/N] '
    IFS= read -r reply || reply=""
    case "$reply" in
    y | Y | yes | YES | Yes) ;;
    *)
      echo "Cancelled."
      exit 1
      ;;
    esac
  fi

  echo "Closing $INPUT ..."
fi

SLUG="${INPUT//\//-}"
WORKTREE_DIR="$REPO_ROOT/.claude/worktrees/$SLUG"

if [[ ! -d "$WORKTREE_DIR" ]]; then
  echo "Error: no worktree found at ${WORKTREE_DIR#"$REPO_ROOT"/}" >&2
  exit 1
fi

BRANCH="$(git -C "$WORKTREE_DIR" rev-parse --abbrev-ref HEAD)"

mtime_of() {
  stat -f %m "$1" 2>/dev/null || stat -c %Y "$1"
}

# A tracked plans/ or pr-reviews/ file (e.g. a committed project plan) is
# already preserved by git history/the branch merge, not by this copy-out --
# which exists only to rescue gitignored per-branch notes before the worktree
# directory disappears. Copying a tracked file too would just leave a stray
# duplicate (plan (1).md) alongside the real, git-tracked copy.
is_tracked() {
  git -C "$WORKTREE_DIR" ls-files --error-unmatch -- "$1" >/dev/null 2>&1
}

# next_available <candidate-path-without-suffix> <extension-including-dot>
# Echoes <candidate><ext> if free, else "<candidate> (1)<ext>", "<candidate> (2)<ext>", ...
next_available() {
  local candidate="$1" ext="$2" n=1
  if [[ ! -e "$candidate$ext" ]]; then
    echo "$candidate$ext"
    return
  fi
  while [[ -e "$candidate ($n)$ext" ]]; do
    n=$((n + 1))
  done
  echo "$candidate ($n)$ext"
}

# --- merge ./plans/ into plans/<branch>/plan.md, plan (1).md, ... ----------
PLANS_SRC="$WORKTREE_DIR/plans"
if [[ -d "$PLANS_SRC" ]]; then
  PLANS_DEST="$REPO_ROOT/plans/$BRANCH"
  mkdir -p "$PLANS_DEST"

  ENTRIES=()
  while IFS= read -r -d '' file; do
    is_tracked "$file" && continue
    ENTRIES+=("$(mtime_of "$file")|$file")
  done < <(find "$PLANS_SRC" -type f -print0)

  if ((${#ENTRIES[@]} > 0)); then
    while IFS='|' read -r _ file; do
      base="$(basename -- "$file")"
      ext=""
      [[ "$base" == *.* ]] && ext=".${base##*.}"
      dest="$(next_available "$PLANS_DEST/plan" "$ext")"
      cp "$file" "$dest"
      echo "Merged plan: ${file#"$WORKTREE_DIR"/} -> ${dest#"$REPO_ROOT"/}"
    done < <(printf '%s\n' "${ENTRIES[@]}" | sort -t'|' -k1,1n)
  fi
fi

# --- merge each pr-reviews/PR-<number>/ folder's files into the same folder,
# numbering only colliding filenames (review.md -> review (1).md) ----------
REVIEWS_SRC="$WORKTREE_DIR/pr-reviews"
if [[ -d "$REVIEWS_SRC" ]]; then
  REVIEWS_DEST_ROOT="$REPO_ROOT/pr-reviews"
  mkdir -p "$REVIEWS_DEST_ROOT"

  while IFS= read -r -d '' pr_dir; do
    pr_name="$(basename -- "$pr_dir")"
    dest_pr_dir="$REVIEWS_DEST_ROOT/$pr_name"
    mkdir -p "$dest_pr_dir"

    while IFS= read -r -d '' file; do
      is_tracked "$file" && continue
      rel="${file#"$pr_dir"/}"
      reldir="$(dirname -- "$rel")"
      base="$(basename -- "$rel")"
      ext=""
      [[ "$base" == *.* ]] && ext=".${base##*.}"
      name="${base%"$ext"}"

      destdir="$dest_pr_dir"
      [[ "$reldir" != "." ]] && destdir="$dest_pr_dir/$reldir"
      mkdir -p "$destdir"

      dest="$(next_available "$destdir/$name" "$ext")"
      cp "$file" "$dest"
      echo "Merged pr-review: ${file#"$WORKTREE_DIR"/} -> ${dest#"$REPO_ROOT"/}"
    done < <(find "$pr_dir" -type f -print0)
  done < <(find "$REVIEWS_SRC" -mindepth 1 -maxdepth 1 -type d -print0)
fi

# --- remove the worktree ----------------------------------------------------
# git refuses to remove a worktree holding modified or untracked files. Rather
# than dying on git's bare "use --force to delete it", show WHAT is dirty and
# offer to force it — by this point plans/ and pr-reviews/ have already been
# merged into the main checkout above, so those docs are safe either way; it is
# any other uncommitted work in the tree that would be lost.
#
# Deliberately NOT setting FORCE here: that would also switch the branch deletion
# below from `git branch -d` to `-D`, skipping its merge check. A dirty worktree
# says nothing about whether the branch is merged, so those stay separate.
if [[ "$FORCE" == "--force" ]]; then
  git worktree remove --force "$WORKTREE_DIR"
elif ! remove_err="$(git worktree remove "$WORKTREE_DIR" 2>&1)"; then
  echo ""
  # Paths shortened to repo-relative: the absolute form is ~70 chars of identical
  # prefix on every line. We already cd'd to $REPO_ROOT, so relative is unambiguous.
  # The strip is applied to git's own message too, not just our own lines.
  remove_msg="${remove_err#fatal: }" # our heading already says it failed
  remove_msg="${remove_msg//$REPO_ROOT\//}"
  # Drop git's trailing ", use --force to delete it": that is advice for someone
  # typing the command, and here we are about to ask instead. The non-TTY branch
  # below prints that instruction itself, where it IS the right next step. A
  # failure for some other reason (locked worktree, etc.) matches nothing and is
  # left verbatim.
  remove_msg="${remove_msg%, use --force to delete it}"

  echo ""
  echo "git would not remove the worktree:"
  echo "  $remove_msg"

  # Only claim it is about dirty files if there actually are some — `remove` can
  # also fail for unrelated reasons, where an empty listing under this heading
  # would just be misleading.
  dirty="$(git -C "$WORKTREE_DIR" status --short 2>/dev/null || true)"
  if [[ -n "$dirty" ]]; then
    echo ""
    # No path here: git's message directly above already named it.
    echo "Uncommitted or untracked files:"
    printf '%s\n' "$dirty" | sed 's/^/  /'
  fi
  echo ""
  # Prompt only when the worktree came from the picker: that flow is guided, and
  # the user never typed a flag so has no reason to know one exists. Naming the
  # branch on the command line is a CLI invocation, so it gets the CLI answer.
  # (The picker path already required a TTY, so no need to re-check for one.)
  if [[ -n "${PICKED:-}" ]]; then
    printf 'Delete it anyway, discarding the above? [y/N] '
    IFS= read -r reply || reply=""
    case "$reply" in
    y | Y | yes | YES | Yes)
      git worktree remove --force "$WORKTREE_DIR"
      ;;
    *)
      echo "Left the worktree in place — nothing removed, branch kept."
      exit 1
      ;;
    esac
  else
    echo "Re-run with --force to delete it and discard them." >&2
    exit 1
  fi
fi
git worktree prune

# --- delete the local branch ------------------------------------------------
if [[ "$FORCE" == "--force" ]]; then
  git branch -D "$BRANCH"
elif ! git branch -d "$BRANCH"; then
  # `-d` only checks merge into current HEAD, so a stacked branch merged into
  # its parent feature branch (not into HEAD) fails here even though no work
  # would be lost. Fall back to checking merge into any local branch before
  # giving up.
  merged_into=""
  while IFS= read -r b; do
    [[ "$b" == "$BRANCH" ]] && continue
    if git merge-base --is-ancestor "$BRANCH" "refs/heads/$b" 2>/dev/null; then
      merged_into="$b"
      break
    fi
  done < <(git for-each-ref --format='%(refname:short)' refs/heads)

  if [[ -z "$merged_into" ]]; then
    exit 1
  fi
  echo "Branch '$BRANCH' isn't merged into HEAD but is fully merged into '$merged_into' -- deleting."
  git branch -D "$BRANCH"
fi

echo ""
echo "Closed worktree $SLUG and deleted local branch $BRANCH."
