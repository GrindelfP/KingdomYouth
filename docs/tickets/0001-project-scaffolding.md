# 0001 — Project scaffolding & Godot project setup

- **Status:** ready
- **Milestone:** M0 — Project & Tooling Setup
- **Depends on:** none

## Goal
Create a working Godot 4.4.1 project with a folder structure that the rest of the roadmap can build into, committed to git with a proper `.gitignore`.

## Context
The repo currently has only `AGENTS.md`/`CLAUDE.md` and `docs/`. There is no `project.godot` yet. Godot is not on `PATH`; it must be run from `/Applications/Godot.app`.

## Scope
- Create the Godot project at the repo root (`project.godot`), targeting Godot 4.4.1, GL compatibility or Forward+ renderer (decide and record the choice).
- Add a `.gitignore` tuned for Godot (`.godot/`, `*.translation`, export artifacts, OS cruft).
- Establish top-level folder structure under the project, e.g.:
  - `scenes/` (world, ui, entities, buildings — subfolders as needed)
  - `scripts/` (GDScript, mirroring `scenes/` where it helps)
  - `assets/` (art, audio placeholders)
  - `resources/` (Godot `.tres` resource definitions: building defs, resource defs)
- Set project name, default window size, and a placeholder main scene (can be an empty/boot scene for now).
- Verify the project opens and runs headless without errors (`--headless --quit` smoke check).

## Out of scope
- Any gameplay scene content (covered by 0002+).
- Art/audio assets beyond placeholders.
- CI/export pipeline setup.

## Acceptance criteria
- [ ] `project.godot` exists at repo root and opens in Godot 4.4.1 without errors.
- [ ] Folder structure above exists (even if some folders only contain a `.gitkeep`).
- [ ] `.gitignore` excludes `.godot/` and other generated files; git status is clean after an editor session.
- [ ] A headless run (`Godot --headless --quit`) exits cleanly.
- [ ] Committed with `[INIT]` or `[FEATURE]` prefix per the git workflow in `CLAUDE.md`.

## Open questions
- Forward+ vs Mobile vs Compatibility renderer — pick based on target hardware once known; default to Forward+ unless there's a reason not to.
- Decided: the game is 2D, top-down, tile-grid based (see `docs/roadmap.md` note and ticket 0002). This ticket should set up the project in 2D mode accordingly.

