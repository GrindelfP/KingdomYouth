# 0014 — Seasons-only calendar & game speed

- **Status:** ready
- **Milestone:** M6 — Seasons & Time
- **Depends on:** 0011

## Goal
Remove the day/night cycle completely and replace the day counter with a Banished-style month/season/year calendar, plus pause and speed controls.

## Context
Owner decision (2026-10-26): no day/night cycle, only seasons cycling. Banished uses 12 months grouped into 4 seasons ("Early Spring", "Mid Spring", "Late Spring", ...). Speed controls are part of the Banished loop: players pause to plan and fast-forward through quiet stretches.

## Scope
- Delete `scripts/world/day_night_tint.gd` and the `DayNight` node in `scenes/world/world.tscn`. No time-of-day lighting anywhere.
- `TimeManager`: replace `day` with `month` (0-based absolute month counter). 12 months per year, 3 per season, `SECONDS_PER_MONTH := 60.0` at 1x.
  - API: `get_month_in_year()`, `get_month_name()` ("Early Spring" … "Late Winter"), `get_season()`, `get_season_name()`, `get_year()` (starts at 1), `get_month_progress()` (0..1).
  - Signals: `month_changed(month)`, `season_changed(season)`, `year_changed(year)`. Remove `day_changed` and `get_time_of_day()` and update all callers.
  - Keep `food_multiplier()` and `is_cold()` semantics.
- Game speed: `TimeManager.set_speed(index)` over `[0 (paused), 1, 2, 5]` implemented with `Engine.time_scale` (paused = `get_tree().paused` is NOT used; use time_scale 0 so UI stays responsive). Signal `speed_changed(index)`.
  - Input actions: `toggle_pause` (Space), `speed_1` (1), `speed_2` (2), `speed_3` (3). Note: check `build_cycle`/other existing bindings for key conflicts and rebind those if needed.
  - Camera pan/zoom must stay usable while paused (use unscaled delta in camera controller: divide by `Engine.time_scale` when > 0, or use real time).
- HUD: time label shows e.g. `Mid Summer, Year 2`; add speed buttons (`||`, `>`, `>>`, `>>>`) with the active one highlighted.
- Save/load: time saves `{month, elapsed}`; bump `SAVE_VERSION` to 2. Old saves may be rejected with a toast.

## Out of scope
- Weather events. Seasonal visuals (snow, foliage) — 0024.

## Acceptance criteria
- [ ] No day/night tint exists; the scene runs with no references to removed code.
- [ ] Calendar advances month by month; seasons change every 3 months; year increments after Late Winter.
- [ ] Space pauses/unpauses; 1/2/3 select speeds; HUD buttons do the same and show the active speed.
- [ ] Camera works while paused.
- [ ] Save/load round-trips month and elapsed time.
- [ ] Headless run is free of script errors.

## Open questions
- None.
