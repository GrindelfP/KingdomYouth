# 0018 — Raw production buildings & work areas

- **Status:** done
- **Milestone:** M7 — Banished Economy
- **Depends on:** 0017

## Goal
Add Banished's raw-resource producers, each with a visible work radius, so the player chooses locations by what nature is nearby.

## Context
Banished's gatherers, hunters, foresters and fishermen are the backbone of an early town; their output depends on what is inside their work circle. Trees must be renewable and managed, otherwise wood runs out.

## Scope
- `JobDef` extensions: `work_radius` (tiles), `outputs` (array of `{id, amount, chance}` or similar), `placement_rule` (none / near_water / near_rock), `winter_factor`.
- Trees become managed per-cell state in `WorldGrid` (forest cells): `growth` stage 0 sapling, 1 young, 2 mature. Only mature trees can be cut. Trees grow one stage per ~2 months except in winter. Natural forest starts mature. Cutting leaves grass (stump state optional) instead of a timer regrow. Replace the old `REGROW_TIME` logic.
- Buildings (all through the existing BuildingDef/JobDef data):
  - **Forester's Lodge** (2x2, radius 8, 2 workers): cuts mature trees (logs 3 per tree) and plants saplings on empty grass in radius, aiming to keep forest density; does nothing to occupied cells.
  - **Gatherer's Hut** (2x2, radius 8, 2 workers): collects berries and mushrooms from forest cells in radius; yield scales with forest cell count; no work in winter.
  - **Hunting Cabin** (2x2, radius 10, 2 workers): venison from forest cells in radius; fewer forest cells = slower; works year-round at reduced winter rate. (Animals are abstract — no deer entities.)
  - **Fishing Dock** (2x2, must touch water, 2 workers): fish; reduced in winter.
  - **Quarry** (3x3, needs ≥ 4 rock cells within radius 3, 3 workers): stone.
  - **Mine** (3x3, needs ≥ 4 rock cells within radius 3, 3 workers): iron.
  - Retire the old **Woodcutter's Lodge** (its role becomes firewood in 0019); the old farm stays until 0020.
- Placement preview and selection show the work radius as a translucent circle; placement errors explain unmet rules ("must be next to water").
- Info panel shows trees/forest cells in radius and production per month estimate is optional.
- Costs (logs/stone) and build times set to sensible values; document them in the ticket on completion.
- Save/load: tree growth states.

## Out of scope
- Animal entities, overhunting simulation. Final art for trees/buildings (0024/0025).

## Acceptance criteria
- [x] All six buildings can be built, staffed and produce their goods into storage via hauling.
- [x] Foresters keep a forest alive over several years; without them forest recedes.
- [x] Work radius is visible when placing and when selected.
- [x] Placement rules for dock/quarry/mine are enforced with clear messages.
- [x] Save/load round-trips tree growth.
- [x] Headless run is free of script errors.

## Open questions
- None.

## Implementation notes

**JobDef (data-driven):** `outputs` (array of `{id, amount, chance}`, replaces `output_id/output_amount`; helpers `output_total()`, `primary_output()`), `target_mode` (`ACCESS` = work from a building edge cell, `FOREST_CELL` = walk to a random forest cell in radius, `FORESTER` = plant/cut logic), `work_radius` (tiles, circle measured from `Structure.get_work_center()`), `density_cells` (forest tiles in radius for 100% speed, 0 = no scaling), `winter_factor` (speed multiplier in winter, 0 = no work), `seasonal` (kept for the farm until 0020), `placement_rule` (`NONE`, `NEAR_WATER`, `NEAR_ROCK`) with `rule_radius`/`rule_min_cells`, `plant_time`, `forest_density`. `Building.work_efficiency()` combines density, winter and seasonal factors; work duration is `work_time / efficiency`.

**Trees (WorldGrid):** per-cell state kept in `_trees` (cell -> stage) and `_tree_age` (months in the current stage, immature only). Forest terrain tiles remain the ground tile for all stages; natural forest starts mature. A stage takes `MONTHS_PER_STAGE = 2` months and does not advance in winter (sapling to mature = 4 non-winter months). API for 0024: `get_tree_stage(cell)` (`NO_TREE = -1`, `STAGE_SAPLING/YOUNG/MATURE` = 0/1/2), `get_tree_cells()`, signals `trees_changed(cell)` (plant, cut, stage change) and `trees_reloaded` (after save load). Also `cut_tree`, `plant_sapling`, `can_plant`, `get_cells_in_radius`, `count_terrain_in_radius`, `count_trees_in_radius`. `REGROW_TIME`, `deplete_forest` and `get_terrain_cells` were removed. Cutting leaves grass (no stump).

**Forester:** counts trees and free grass in radius; plants while density (trees / (trees + plantable grass)) is below 0.6, otherwise cuts a mature tree for 3 logs. Hence logs are only produced when trees are available, and the forest settles near 60% density.

**Buildings (cost / build time / work_time / yield / workers):**
- Forester's Lodge 2x2: 20 logs / 15 s / 6 s per cut (3 s per plant) / 3 logs per tree / 2, radius 8.
- Gatherer's Hut 2x2: 15 logs / 12 s / 5 s / 2 berries + 1 mushroom (50%) / 2, radius 8, full speed at 40 forest tiles, no winter work.
- Hunting Cabin 2x2: 25 logs / 18 s / 12 s / 4 venison / 2, radius 10, full speed at 60 forest tiles, winter factor 0.5.
- Fishing Dock 2x2: 30 logs / 20 s / 8 s / 3 fish / 2, must touch water, winter factor 0.5.
- Quarry 3x3: 30 logs / 25 s / 10 s / 2 stone / 3, needs >= 4 rock tiles within 3.
- Mine 3x3: 40 logs + 20 stone / 30 s / 14 s / 2 iron / 3, needs >= 4 rock tiles within 3.

**UI:** `BuildController` draws a translucent work-radius circle for the placement preview and for the selected building or site (`set_highlight`, driven by `JobController`). Placement errors: "must be next to water", "needs 4 rock tiles within 3 tiles (found N)". Info panel shows forest tiles / tree counts / rock tiles in range and the current work rate.

**Other:** old Woodcutter's Lodge and its job were deleted. `SAVE_VERSION` is 6 (trees saved as `[x, y, stage, age]` for immature trees only; old saves are rejected). `BuildController.from_save_data` skips unknown building ids. With the woodcutter gone nothing cuts trees except foresters, so the "forest recedes" criterion only holds in the sense that logs stop; no building clears forest on its own.

**Verified headless (throwaway scripts):** all six buildings placed at programmatically found valid spots, staffed, and delivered goods into storage over ~50 simulated months; forester kept ~60 trees in its radius stable; dock/quarry rule rejection counted across the whole map; sapling growth timing (stage 1 after 2 months, mature after 4, frozen in winter); save/load round-trip of tree states.
