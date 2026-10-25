# 0013 — Save/load system

- **Status:** ready
- **Milestone:** M5 — Persistence
- **Depends on:** 0004, 0006, 0009, 0010, 0011

## Goal
The player can save the current settlement state to disk and reload it later, resuming play exactly where they left off.

## Context
By this point the simulation has real state spread across several autoloads/systems (stockpile, time/season, settlers, buildings, terrain modifications). This ticket defines a serialization contract across all of them rather than ad hoc per-system dumps.

## Scope
- Decide and document a save format (recommend Godot's built-in `ResourceSaver`/`FileAccess` with JSON or a custom binary — JSON is easier to debug during development, recommend starting there).
- Each major system exposes a `to_save_data()` / `from_save_data(data)` pair (or equivalent): resource stockpile (0004), time/season (0011), terrain state if mutable (0002/0009's forest depletion), all buildings (type, position, construction progress, job assignments), all settlers (position, job, needs, home assignment).
- A `SaveManager` autoload orchestrating: collect all systems' data → write to a save file; read a save file → restore all systems in the correct order (terrain/buildings before settlers, since settlers reference them).
- At least one manual save/load trigger (menu button is fine; full UI polish is optional here — functional button is enough).
- Handle the "new game" path cleanly (distinguish from "load game") so this doesn't entangle with 0001's project setup.

## Out of scope
- Multiple save slots/autosave scheduling (a single manual save slot is enough for MVP; expand later if desired).
- Save versioning/migration tooling (acceptable for now that old saves may break across major changes during active development — document this limitation rather than building migration infrastructure prematurely).
- Cloud saves.

## Acceptance criteria
- [ ] Saving writes a complete, loadable representation of: stockpile, time/season, terrain mutations, buildings (with progress/assignments), and settlers (with needs/jobs/home).
- [ ] Loading a save restores the game to an equivalent playable state (settlers resume their jobs, buildings are in the right state, resources match).
- [ ] Starting a new game does not require deleting/ignoring old save data awkwardly.
- [ ] A reasonable round-trip test (save, quit to a fresh scene load, load) is confirmed to work, not just save-then-immediately-load-in-memory.

## Open questions
- JSON vs. Godot binary resources vs. a custom format — recommend JSON for early development transparency; can revisit for performance/size once the game has real scale.
- Save file location — use Godot's `user://` directory per platform convention.
