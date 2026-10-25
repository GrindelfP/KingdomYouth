# 0005 — Building placement & construction system

- **Status:** ready
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
- [ ] Player can open a building menu (can be a stub list for now; full UI is 0012), pick a building, see a valid/invalid placement preview, and confirm.
- [ ] Confirming deducts the correct resource cost and fails gracefully (no deduction, no placement) if the stockpile can't afford it.
- [ ] A construction site appears immediately, and becomes the finished building after its construction condition is met.
- [ ] Invalid placements (occupied tile, non-buildable terrain, out of bounds) are rejected with visible feedback.

## Open questions
- Does construction require a settler to physically walk there and work (ties into 0006/0008), or is it tick-based/automatic for MVP? Recommend: automatic time-based completion for this ticket, then wire it to actual settler labor once 0008 (job assignment) exists, to avoid a circular dependency between 0005 and 0008.
