# 0022 — Roads & demolition

- **Status:** ready
- **Milestone:** M8 — Population
- **Depends on:** 0017

## Goal
Let the player shape the town: lay roads that speed up walking, and demolish buildings they no longer want.

## Context
Banished roads make settlers walk faster and are the main layout tool; demolition recovers part of the materials. Both are standard city-builder controls.

## Scope
- **Roads**: dirt road (free, quick) and stone road (1 stone per tile). Drag-to-place in a straight line or L-shape from mouse-down to mouse-up. Roads are walkable tiles that buildings cannot overlap; they are built instantly for dirt and by builders for stone (or instantly with stone deducted — implementer's choice, document it).
  - Movement speed multiplier on road tiles: dirt 1.5x, stone 2x. Pathfinding prefers roads (AStar2D point weights or custom cost) so settlers route along them.
  - Roads are drawn as a separate layer above terrain (simple colors until 0024 art).
- **Demolish tool** (button + `X` key): click a building, site or road tile to remove it. Buildings refund 50% of their cost into storage (if room); workers/residents are released. Demolishing a site refunds delivered materials fully.
- Build menu groups: Roads, Storage, Housing, Food, Resources, Industry.
- Save/load roads.

## Out of scope
- Bridges, tunnels.

## Acceptance criteria
- [ ] Settlers walk measurably faster on roads and prefer them.
- [ ] Demolition removes buildings and refunds materials as described.
- [ ] Build menu is grouped.
- [ ] Save/load round-trips roads.
- [ ] Headless run is free of script errors.

## Open questions
- None.
