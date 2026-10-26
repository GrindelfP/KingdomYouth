# 0027 — Integration, balance pass & docs for v0.2

- **Status:** done
- **Milestone:** M10 — v0.2 Release
- **Depends on:** 0014–0026

## Goal
Make v0.2 a coherent, playable whole: everything saves and loads, a reasonable player survives the first winters, and the docs describe the new game.

## Context
Tickets 0014–0026 each change core systems; this ticket checks they work together and tunes the numbers.

## Scope
- Save/load: one end-to-end round-trip covering storage, sites, professions, trees, roads, fields, households, families, tools, calendar. Saves from older versions are rejected with a toast.
- Automated soak run: a throwaway headless script that starts a new game, builds a sensible starter town programmatically (houses, gatherer, forester, woodcutter, fields, storage), runs at high time scale for 3 game years, and prints population, food, firewood per season. Fix crashes, stuck settlers, and leaks it reveals. Do not commit the script unless it is useful as a repeatable check (if kept, put it under `tools/`).
- Balance: tune costs, yields, consumption so that the starter town survives the first winter only with some planning, and unplanned play (no firewood, no food buildings) fails within ~2 years. Record final numbers in a table in `docs/balance.md`.
- Docs: update `docs/tutorial.md` (new loop, professions, storage, seasons, speed keys), `README.md` features/controls, and `docs/roadmap.md` status.

## Out of scope
- New features.

## Acceptance criteria
- [x] Soak run completes 3 years with no script errors.
- [x] Save/load round-trip verified across two processes.
- [x] `docs/balance.md`, tutorial and README updated.

## Open questions
- None.

## Implementation notes
- **Soak** (`tools/soak/`, run as a scene because autoloads are not visible to `-s` scripts): `soak_test.gd` builds a starter town through `planner.gd` (affordability-checked queue, spot search near the map centre with a one-tile margin, staffing, builders cut to 1 at month 6, woodcutter paused above 120 firewood), runs at time scale 10 with `--fixed-fps 30` and prints one row per season. Modes `planned`, `nowood`, `neglect`; 3 years take about 10 s. It also reports settlers that stand still while travelling (none found) and long-idle settlers (only farmers and gatherers in the off season).
- **Balance** (details and tables in `docs/balance.md`): hunger 0.7 to 1.0 per second, heating 1 firewood per 20 s to per 10 s, warmth drain 1.0 to 1.5 and cold damage 0.5 to 1.5 per second. Planned town survives 3 years with food at 0 in storage in the second spring, no deaths; no woodcutter means extinction by month 23; no production at all means extinction by month 11.
- **Bugs fixed**: `NatureLayer._set_ghost_alpha` touched ghost sprites freed when their tree was cut during a season fade (script errors every frame); `SettlerManager.clear_settlers` freed the tooltip `CanvasLayer` too, so every load broke settler hover with a script error each frame (it now frees only `Settler` nodes).
- **Save/load**: `tools/soak/roundtrip_test.gd` saves a 14-month town (roads, a construction site, households, fields, tools) in one process and, in a second process, loads it and compares a digest of settlers, buildings, sites, stock, trees and roads (0 of 8 sections differ). `SaveManager` now has `save_path` (tests do not touch the real save) and `last_error`; the HUD shows "This save is from an older version of the game (vN, current vM)..." for older saves, and separate messages for newer, damaged, and missing saves. `SAVE_VERSION` stays 10.
- **HUD**: `BuildingMenu` is now a slim bar of category tabs at the bottom (about 40 px) with a pop-up of thumbnail buttons; `B` opens (last category) or closes it, a pick or `Esc` closes it, and `B` also leaves placing and demolish modes. `BuildController` no longer handles `build_toggle`. Captured frames at 1280x720 (default town, Food page open, profession panel plus settler panel plus pop-up): the professions panel (to y 485), info panel (top right) and the pop-up (from y 535) do not overlap, and toasts stay in the top centre.
- **Theme**: `resources/ui/theme.tres` is not written by any generator (`tools/art/gen_ui.gd` only writes the PNGs under `assets/art/ui/`), so it is hand-maintained and regenerating art cannot lose the SmallButton font size.
- **Remaining limits**: growth is capped by family size (a house holds one family); the top bar food counts storage only, while houses hold their own food; the planner needs to cut builders and staffing like a player would, because there are only 6 adults at the start; interactive key and click wiring for the menu was reasoned about and checked through frames, not through synthesized input.
