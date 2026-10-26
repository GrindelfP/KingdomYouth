# 0018 — Raw production buildings & work areas

- **Status:** ready
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
- [ ] All six buildings can be built, staffed and produce their goods into storage via hauling.
- [ ] Foresters keep a forest alive over several years; without them forest recedes.
- [ ] Work radius is visible when placing and when selected.
- [ ] Placement rules for dock/quarry/mine are enforced with clear messages.
- [ ] Save/load round-trips tree growth.
- [ ] Headless run is free of script errors.

## Open questions
- None.
