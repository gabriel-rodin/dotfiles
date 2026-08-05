# dotfiles

Personal configuration for [Claude Code](https://claude.com/claude-code) and [Codex](https://developers.openai.com/codex), kept in one repo and symlinked out to both tools' global config directories so they share the same instructions and skills instead of drifting apart.

## Layout

```
claude/
  CLAUDE.md            symlink -> ../codex/AGENTS.md (see "One instructions file" below)
  skills/              skills used only by Claude Code
codex/
  AGENTS.md            the real file; shared instructions for both Claude Code and Codex
skills/                skills shared by both Claude Code and Codex
install.sh             symlinks everything into ~/.claude, ~/.codex, ~/.agents
uninstall.sh           removes those symlinks, restoring any .bak backups
```

## One instructions file

Claude Code reads `CLAUDE.md`; Codex reads `AGENTS.md`. Rather than maintain two files that are supposed to say the same thing, `codex/AGENTS.md` is the single real file and `claude/CLAUDE.md` is a symlink to it:

```
claude/CLAUDE.md -> ../codex/AGENTS.md
```

Edit `codex/AGENTS.md`; `claude/CLAUDE.md` picks up the change automatically. `AGENTS.md` was chosen as the canonical file because it's the emerging cross-tool convention (also used by Cursor, OpenCode, etc.), not tied to one vendor.

## Skills: shared vs. tool-specific

Both Claude Code and Codex support **Skills** — folders with a `SKILL.md` (name + description frontmatter, triggers the agent invokes it on, and instructions loaded only once triggered). Where a skill's install location lives depends on whether its content is useful to one tool or both:

- **`skills/`** — reusable content with nothing tool-specific in it (PR descriptions, git commits, frontend design guidance, etc.). Symlinked into *both* `~/.claude/skills/` and `~/.agents/skills/` (a cross-tool skills directory Codex also reads, alongside its own bundled `~/.codex/skills/.system/`).
- **`claude/skills/`** — skills that only make sense for Claude Code: content tied to Claude-specific concepts (e.g. auditing `CLAUDE.md` files), or skills Codex already covers with its own built-in system skill (e.g. skill-authoring guidance — Codex ships its own `skill-creator`, so a second one here would just be redundant/conflicting). Symlinked only into `~/.claude/skills/`.
- **`codex/skills/`** — the Codex-only equivalent, currently empty. Symlinked only into `~/.codex/skills/` if it ever gets one.

### Per-tool invocation control

Claude Code and Codex use different mechanisms to mark a skill as "don't fire automatically, only run when the user explicitly asks for it":

| | Claude Code | Codex |
|---|---|---|
| Mechanism | `disable-model-invocation: true` in `SKILL.md` frontmatter | `policy.allow_implicit_invocation: false` in `agents/openai.yaml` |

Codex only reads the `name` and `description` frontmatter fields — it silently ignores `disable-model-invocation`. Claude Code has no knowledge of `agents/openai.yaml`. So a shared skill that needs this behavior in both tools carries **both** files; each tool reads the one it understands and ignores the other. Neither file conflicts with the other tool — they're per-tool translations of the same intent, not duplicated logic.

### No cross-references between skills

Skills in this repo don't mention each other by name (no "see other-skill for that" pointers), even for legitimate disambiguation. That coupling breaks silently whenever a skill gets renamed or removed — keep disambiguation as a scope boundary in the skill's own description (e.g. "Not for editing an existing PR after the fact") without naming the sibling skill.

## Context7 / `find-docs`

Up-to-date library documentation lookups (via the `ctx7` CLI) are handled entirely by the `find-docs` skill in `skills/`, shared by both tools. There is deliberately **no** always-loaded instructions-file copy of this content (no `<!-- context7 -->` block in `AGENTS.md`, no separate `~/.claude/rules/context7.md`) — a skill's `name`+`description` is already always in context, so a second always-on copy would only add token cost, not reliability. The one caveat: `find-docs`'s current trigger wording is Q&A-shaped ("asks about a library," "questions") rather than implementation-shaped, so it isn't guaranteed to fire on silent "just implement X" requests — invoke it explicitly during implementation work if you want current API syntax verified.

If the `ctx7` CLI's own `setup --claude`/`setup --codex` command is ever re-run, it will likely recreate both the rule file and a real (non-symlinked) skill directory at these paths, undoing this consolidation — recheck for duplicates afterward.

## Install / uninstall

```bash
./install.sh
```

Symlinks:

- `claude/CLAUDE.md` -> `~/.claude/CLAUDE.md`
- `codex/AGENTS.md` -> `~/.codex/AGENTS.md`
- each `claude/skills/<name>` -> `~/.claude/skills/<name>`
- each `codex/skills/<name>` -> `~/.codex/skills/<name>`
- each `skills/<name>` -> `~/.claude/skills/<name>` **and** `~/.agents/skills/<name>`

Safe to re-run any time — it's idempotent (existing symlinks are just relinked). If a target path already holds a real file or directory (not a symlink) — e.g. content some other tool installed there — it's renamed to `<path>.bak` rather than deleted.

To verify the links afterward:

```bash
ls -la ~/.claude/CLAUDE.md ~/.codex/AGENTS.md ~/.claude/skills ~/.agents/skills ~/.codex/skills
```

Add `-G` on macOS to color-code broken symlinks so a dangling one is obvious at a glance.

If you have `tree` installed, it gives a clearer view of the skill directories (run `ls -la` separately for the two files, since `tree` only walks directories):

```bash
ls -la ~/.claude/CLAUDE.md ~/.codex/AGENTS.md
tree ~/.claude/skills ~/.agents/skills ~/.codex/skills
```

```bash
./uninstall.sh
```

Removes every symlink `install.sh` would create, but only if it actually points into this repo (a foreign symlink or a real file at the same path is left alone). Restores any `.bak` backup `install.sh` made.

## Making changes

- Edit `codex/AGENTS.md` directly for instructions — `claude/CLAUDE.md` follows automatically via the symlink.
- Add a new skill under `skills/` if it's useful to both tools, or under `claude/skills/`/`codex/skills/` if it's tool-specific, then run `./install.sh` to link it in.
- After editing a skill or `AGENTS.md`, no reinstall is needed for existing entries — the symlinks already point at the live repo files.
