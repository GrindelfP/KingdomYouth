# 0009 — Core production buildings (woodcutter's lodge, storage barn, farm)

- **Status:** done
- **Milestone:** M2 — Core Simulation Loop
- **Depends on:** 0004, 0005, 0008

## Goal
A minimal but complete production chain exists: settlers can gather wood and grow food, closing the core resource loop the rest of the systems depend on.

## Context
This ticket is where 0004 (stockpile), 0005 (construction), and 0008 (jobs) come together into actual content. Keep the building roster to the smallest set that makes the loop feel real: one wood source, one food source, one storage building.

## Scope
- **Woodcutter's Lodge**: provides 1+ woodcutter job slots. Assigned settlers walk to a nearby forest tile (per 0002), harvest wood (converts/depletes the forest tile or a wood-node on it — decide and document the mechanic), and deposit wood into the stockpile (0004).
- **Farm**: a fixed-footprint building/plot that provides 1+ farmer job slots. Produces food over time on a tick (season-independent for now, since seasons land in 0011 — but structure the production rate as a single tunable value so 0011 can later multiply it by a season factor without rework).
- **Storage Barn** (or equivalent "stockpile" building): for MVP, this can simply be required for the stockpile (0004) to function at all, or purely cosmetic/flavor if 0004's stockpile is unconditionally global — decide which, document it, and keep it consistent with 0004's actual implementation.
- Each building defined via the `BuildingDef` resource pattern from 0005, with correct resource costs and job slot counts.
- Forest tile depletion/regrowth (if harvesting consumes the tile): define whether forest tiles regrow over time or are finite — pick the simpler option for MVP (recommend: regrowth over a long timer, so the player can't permanently deforest by accident during early testing).

## Out of scope
- Multiple food types (hunting, fishing, orchards) — only one farm type for MVP.
- Building-level storage capacity/limits.
- Visual harvesting animations beyond placeholder feedback.

## Acceptance criteria
- [x] Woodcutter's Lodge can be built, staffed, and reliably produces wood into the stockpile over time. (Real-time run with 2 woodcutters: wood 25 → 47 in ~55 s.)
- [x] Farm can be built, staffed, and reliably produces food into the stockpile over time. (Same run, 2 farmers: food 20 → 63.)
- [x] Storage Barn's role (gating stockpile capacity, or purely flavor) is implemented consistently with how it's documented. (Flavor only; see decisions.)
- [x] Forest tiles behave consistently under repeated harvesting per the decided depletion/regrowth rule (no crashes, no permanently broken tiles). (Depleted tiles regrow after 120 s; an occupied tile waits until free.)
- [x] A full playthrough is possible: build these three buildings, assign settlers, and watch wood/food accumulate without manual intervention beyond initial setup. (Lodge and farm built, 4 settlers assigned, wood and food rose. The storage barn is a stub, not needed for the loop.)

## Decisions
- Buildings are data: `resources/buildings/woodcutters_lodge.tres` (2x2, 10 wood, 5 s build, 2 woodcutter slots), `resources/buildings/farm.tres` (3x3, 15 wood, 8 s build, 3 farmer slots), and the existing `storage_barn.tres` (2x2, 10 wood). Jobs are `resources/jobs/woodcutter.tres` and `resources/jobs/farmer.tres`.
- Woodcutter: harvests the nearest reachable forest tile. Each completed harvest gives 2 wood. The forest tile is depleted to grass and regrows to forest after 120 s. Depletion and regrowth live in `WorldGrid` (`deplete_forest`, `_process`). Regrowth waits while a building occupies the tile.
- Farm: the farmer works at an access cell next to the farm. Each completed harvest gives 3 food. The single tunable rate is the job's `work_time` (6 s); seasons (0011) can scale it later.
- Storage Barn: flavor only. The stockpile (0004) is global and unconditional, so the barn gates nothing.
- Each harvest gives output only on completion, so cancellation cannot duplicate or lose partial output.

## Open questions
- Does wood harvesting deplete/remove the forest tile (turning it to grass) with regrowth over time, or is it an infinite-yield node? Recommend depletion + slow regrowth, since it's closer to the Banished reference and gives forestry/sustainability tension later (forester's lodge replanting) without extra work now.
- Exact production/consumption numbers — placeholder values, tune after playtesting the full loop.
