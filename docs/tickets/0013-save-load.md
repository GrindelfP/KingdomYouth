# 0013 — Save/load system

- **Status:** done
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
- [x] Saving writes a complete, loadable representation of: stockpile, time/season, terrain mutations, buildings (with progress/assignments), and settlers (with needs/jobs/home). (`user://savegame.json`.)
- [x] Loading a save restores the game to an equivalent playable state (settlers resume their jobs, buildings are in the right state, resources match). (Round-trip matched on stock, time, forest, regrowth, buildings, construction progress, settler cells, needs, homes, and jobs.)
- [x] Starting a new game does not require deleting/ignoring old save data awkwardly. (New game resets the autoloads and reloads the scene. The save file is not touched.)
- [x] A reasonable round-trip test (save, quit to a fresh scene load, load) is confirmed to work, not just save-then-immediately-load-in-memory. (Two separate Godot processes: save and quit, then a fresh process loads the file.)

## Decisions
- Format: JSON at `user://savegame.json`, with a `version` field (currently 1). Saves from other versions are refused, which is the accepted limitation for now.
- Each system owns its data: `ResourceStockpile` (amounts array), `TimeManager` (day and elapsed), `WorldGrid` (terrain as a 4096-char code string plus regrowth timers), `BuildController` (buildings and construction sites by definition id and origin), `SettlerManager` (settlers with cell, needs, and home and job origins).
- Settlers reference houses and jobs by building origin, not by object reference. Load order: stock and time, then clear settlers and buildings, then terrain, then buildings, then settlers.
- Occupancy is not saved. It is rebuilt from the buildings and sites when they are restored.
- A settler's walk is saved as its last reached cell. On load it starts from there, idle.
- Trigger: Save and Load buttons in the top bar, plus F5 and F9. `GameBootstrap` performs a deferred load when `SaveManager.pending_load` is set (the scene starts a fresh world first).
- New game: `SaveManager.start_new_game()` resets the stockpile and the clock, clears the pending load, and reloads the scene. The save file is left as it is.

## Open questions
- JSON chosen for development transparency. Revisit for size or speed at scale.
- Save location: `user://` per platform convention, `savegame.json`.
