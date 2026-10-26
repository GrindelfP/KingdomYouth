# 0020 — Crop fields with a seasonal lifecycle

- **Status:** done
- **Milestone:** M7 — Banished Economy
- **Depends on:** 0019

## Goal
Replace the abstract farm with Banished-style crop fields: planted in spring, grown through summer, harvested in autumn, lost to the first frost if left in the ground.

## Context
Farming is Banished's biggest food source and its most season-driven one. Over-sized fields with too few farmers lose crops to winter; this is a core management decision.

## Scope
- **Crop Field** building: footprint chosen by the player from presets 4x4, 6x6, 8x8 (cycle with `R` or buttons during placement; cost scales), up to 4 farmers.
- Crop choice per field (info panel buttons): Wheat or Cabbage. Changing crop takes effect next spring.
- Per-cell state: `empty → plowed → planted → growing (0..1) → ripe → harvested`.
  - Early Spring – Late Spring: farmers walk to cells and plow/plant them.
  - Growth advances automatically from planting through summer; Cabbage ripens earlier (Late Summer), Wheat later (Early Autumn).
  - Ripe cells are harvested one by one by farmers (each cell yields ~2 of the crop into the field's buffer, hauled to storage).
  - At the start of winter all unharvested cells are lost and reset to empty; toast "Frost destroyed crops at …".
- Field draws cell states clearly (plowed soil, sprout, growing, ripe) with simple shapes; final art comes in 0025.
- Info panel: crop, planted/ripe/harvested counts, workers.
- Retire the old Farm def; save/load per-cell states and crop choice.

## Out of scope
- Orchards, livestock, crop diseases.

## Acceptance criteria
- [x] Over a year a staffed field goes through plant → grow → harvest, producing food into storage.
- [x] An understaffed large field loses unharvested cells at winter.
- [x] Crop type and field size are selectable.
- [x] Save/load round-trips per-cell states.
- [x] Headless run is free of script errors.

## Open questions
- None.

## Implementation notes

**Footprint:** three separate defs share one `farmer.tres` job: `crop_field_4/6/8` (cost 15/30/50 logs, build time 20/35/50 builder-seconds, 4 slots). `BuildingDef.family` (`&"crop_field"`) groups size variants; `BuildController.cycle_size()` (action `build_size`, key `R`, only while placing) jumps to the next def of the same family. The build menu lists the three sizes as separate buttons. `BuildingDef.is_field()` is true for `TargetMode.FIELD` jobs. Save format needs nothing new beyond the def id.

**Walkable fields:** `WorldGrid.set_open(cells, open)` marks occupied cells as still walkable; `Building.setup` opens field cells (construction sites stay blocked). `set_occupied(false)` and `clear_occupancy()` clear the flag.

**CropField (`scripts/buildings/crop_field.gd`, `Building.field`)** is the per-cell state holder, created for field buildings only. API for 0025:
- `size`, `crop`, `pending_crop`; `CROP_IDS` (wheat, cabbage).
- `CellState { EMPTY, PLOWED, PLANTED, GROWING, RIPE, HARVESTED }`; `get_state(cell)`, `get_growth(cell)` (0..1, local cell coordinates 0..size-1), `count(state)`, `planted_count()`.
- Signals `cell_changed(cell)`, `cells_reloaded` (frost reset, save load), `crop_changed`. `Building` redraws itself on these and once per month; `Building._draw_field()` is the placeholder shape drawing (soil, furrows, sprout, growing disc, ripe square or disc, stubble, fence outline) that 0025 replaces.
- Growth is time based: `sow()` stores `TimeManager.get_time_months()` (new helper, month + progress) and `update()` (every 0.25 s and on month change) moves PLANTED to GROWING at 20% growth and to RIPE at 100%. Grow time is 5.5 months for wheat and 4.5 for cabbage, so a cell sown in mid spring ripens in early autumn or late summer.
- `set_pending_crop()` applies immediately only while no cell is planted or later; otherwise `begin_season()` (on `season_changed` to spring) swaps it in. `frost()` (on winter start) resets every cell to EMPTY and returns the number of PLANTED/GROWING/RIPE cells lost; `Building.crops_lost(count)` is forwarded as `BuildController.crops_lost(building, count)` and the HUD toasts "Frost destroyed crops at (x, y): N cells lost."

**Farmer work:** `Worker._find_field_target()` asks `CropField.next_task(from, sowing_season)`; priority is reap ripe cells, then sow plowed cells (spring only), then plow empty cells (spring only), nearest first, with per-cell claims so farmers do not collide (released through `_release_claims`/`_release_field_claim`). A plow is followed directly by a sow on the same cell. Times: plow 2.5 s, sow 2.0 s, reap 6.0 s (all divided by tool speed). A reaped cell yields `outputs[0].amount` = 2 of the field's crop into the field output buffer (capacity 40 for fields, 20 otherwise); `Building.get_output_id()` is the crop for fields. Existing pickup and laborer hauling carry it to storage.

**Removed:** `farm.tres`, `JobDef.seasonal`, `TimeManager.FOOD_MULTIPLIERS`/`food_multiplier()`, the seasonal factor in `Building.work_efficiency()`.

**Save:** `SAVE_VERSION` 8; each building saves `field` (`crop`, `pending`, `states`, `planted_at`). Old saves are rejected.

**Verified headless (time scale 10, ~18 game months, throwaway script):** a 4x4 field with 4 farmers went plowed to planted to growing to ripe to harvested and added about 32 wheat to storage; an 8x8 with 1 farmer planted only about 35 of 64 cells, harvested most, and lost the remaining ripe cells at winter (toast signal fired with count 5); setting cabbage in mid summer left wheat in the ground and switched to cabbage the next spring with fresh cells growing and ripening in late summer; a save round-trip of all building data (field states and planted times) was byte-identical. Size cycling via `cycle_size()` verified. Not exercised interactively: the `R` key, size buttons, crop buttons in the info panel and the drawn field.

**Known limits:** a field built after spring idles until next year. Yield (2 per cell) and times are first-draft balance for 0027; a staffed 4x4 gives about 32 food per year.
