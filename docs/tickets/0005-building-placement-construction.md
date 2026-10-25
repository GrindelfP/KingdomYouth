# 0005 — Building placement & construction system

- **Status:** done
- **Milestone:** M2 — Core Simulation Loop
- **Depends on:** 0002, 0003, 0004

## Goal
The player can select a building type, see a placement preview, confirm placement on a valid tile, pay its resource cost, and watch it go from a construction site to a finished building (consuming settler labor, see 0006/0008 for the labor side).

## Context
This is one of the two core interaction loops in Banished-likes (the other being job assignment). For MVP, keep buildings as single-tile or small fixed-footprint structures snapped to the grid from 0002.

## Scope
- A `BuildingDef` resource (`.tres`) describing: id/name, footprint (tile size), resource cost, construction time/labor required, buildable-tile rules (reuses 0002's `is_buildable`).
- Placement flow: enter "placing" mode for a chosen building, ghost preview follows the cursor (valid = green-ish, invalid = red-ish feedback), click to confirm.
- On confirm: validate tiles are buildable and unoccupied, deduct resource cost via 0004, spawn a "construction site" instance occupying those tiles (blocks further building there, blocks walkability or not — decide and document).
- Construction progress: either time-based alone, or requiring a settler with the "builder" job (0008) to be present — for MVP, a simple time-based or labor-tick model is enough; don't over-build this before 0008 exists.
- On completion: replace the construction site with the finished building scene/instance.
- Prevent overlapping placements and placements outside map bounds.

## Out of scope
- Building upgrades/demolition (can be a fast-follow ticket later, not blocking MVP).
- Rotation of non-square footprints (skip if all MVP buildings are square/1x1 or symmetric).
- Multiple simultaneous construction sites queued with priority (fine to let the player queue several; no need for a priority system yet).

## Acceptance criteria
- [x] Player can open a building menu (can be a stub list for now; full UI is 0012), pick a building, see a valid/invalid placement preview, and confirm. (Stub: `B` toggles placing, `Tab` cycles the list, left-click confirms, `Esc`/right-click cancels.)
- [x] Confirming deducts the correct resource cost and fails gracefully (no deduction, no placement) if the stockpile can't afford it.
- [x] A construction site appears immediately, and becomes the finished building after its construction condition is met.
- [x] Invalid placements (occupied tile, non-buildable terrain, out of bounds) are rejected with visible feedback. (Red ghost plus a reason line in the UI label.)

## Decisions
- `BuildingDef` resource (`scripts/buildings/building_def.gd`): `id`, `display_name`, `footprint` (tiles), `cost` (`ResourceStockpile.Type` to int), `build_time` (seconds). Instance: `resources/buildings/storage_barn.tres`, a 2x2 stub with cost 10 wood and 5 s build time. It is a placeholder for the MVP buildings in 0009.
- Footprint is anchored at its top-left cell, which is the cell under the cursor.
- Validation order: outside map, then occupied, then terrain not buildable, then not enough resources. The first failure is the reason shown.
- Construction sites and finished buildings are impassable and unbuildable. Occupancy lives in `WorldGrid` (`set_occupied`), and walkability and buildability now include it.
- Construction is time-based (automatic completion). Settler labor is wired in with 0008.
- On completion, the `ConstructionSite` node is replaced by a `Building` node on the same cells. The occupancy does not change, so pathfinding sees no difference.
- Multiple sites may be queued. No priority.

## Open questions
- Whether construction should require a settler on site (0008) once that exists.
