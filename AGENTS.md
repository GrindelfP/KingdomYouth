# KingdomYouth — AGENTS.md

## Project
- Banished-like settlement/city builder: player starts with a few uncontrollable settlers and builds structures for their life and prosperity.
- Engine: Godot 4.4.1.
- All text, code, commit messages, and docs: English only.

## Engine (verify before assuming)
- `godot` is NOT on PATH. Godot.app is installed at `/Applications/Godot.app` (Godot 4.4.1).
- Run the editor: `open -a Godot` or `/Applications/Godot.app/Contents/MacOS/Godot`.
- Run headless: `/Applications/Godot.app/Contents/MacOS/Godot --headless <args>`.
- Repo is otherwise empty; there are no build/test/lint configs yet — do not invent commands.

## Git workflow (mandatory)
- Commit on every change, even small ones. Never skip a commit.
- When the asked work is done: push to the remote.
- Remote: `origin` = `https://github.com/GrindelfP/KingdomYouth.git` (already configured; repo not yet created on GitHub — push will fail until it exists).
- Commit message prefix in square brackets:
  - `[INIT]` — first commit
  - `[FEATURE]` — starting a new feature
  - `[UPDATE]` — general update
  - `[FIX]` — fix of an issue or bad idea
  - `[BUGFIX]` — fix of a bug (subset of `[FIX]`)
  - `[STABLE]` — polished, fixed version
- Example: `git commit -m "[FEATURE] add settler spawning"`

## Session log (read every new chat)
- File: `docs/session-log.md`. Read it first thing in every session to catch up.
- Append one record per work session, format exactly: `[DATE] - [TIME of record] - [What was done?]`
- Example: `2026-10-24 - 22:14 - initialized repo, wrote AGENTS.md and session log`

## Code style
- Little to no comments in code. If a comment is needed, keep it in English and minimal.
