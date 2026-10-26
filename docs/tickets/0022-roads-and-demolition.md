# 0022 — Roads & demolition

- **Status:** done
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
- [x] Settlers walk measurably faster on roads and prefer them.
- [x] Demolition removes buildings and refunds materials as described.
- [x] Build menu is grouped.
- [x] Save/load round-trips roads.
- [x] Headless run is free of script errors.

## Open questions
- None.

## Implementation notes
- **Road state (`WorldGrid`)**: `enum Road { NONE, DIRT, STONE }`, `get_road(cell)`, `get_road_cells()`, `set_road(cell, type)`, `can_place_road(cell, type)` (in bounds, grass terrain, not occupied, no tree, and only upgrades: dirt to stone, never a downgrade), `get_speed_multiplier(cell)` (`ROAD_SPEED_MULTIPLIERS`: dirt 1.5, stone 2.0). Signal `roads_changed(grid_pos)`, emitted by `set_road` and by save load. Roads are saved in the terrain block as `roads: [[x, y, type]]`; `SAVE_VERSION` 10.
- **Decision: stone is charged instantly** (1 stone per tile, `ResourceStockpile.spend`). Tiles beyond the stone in stock are not built; the rest of the line is placed in order and a notice reports the shortfall.
- **Decision: roads on grass only.** Forest tiles always hold a tree and water/rock are excluded, so roads cannot cross them. Trees cannot be planted on a road (`can_plant` checks it), and buildings and fields cannot overlap one (`is_buildable` checks it).
- **Placement (`BuildController`)**: pick a road in the build menu (`select_road`), then drag with the left mouse button. `road_line_cells(from, to)` draws a straight line, or an L-shape that runs horizontally from the start and then vertically to the end. `place_road_line(from, to, type)` returns the number of tiles placed. Invalid tiles are skipped, so a line can have gaps where it crosses obstacles.
- **Movement**: `Settler` multiplies its speed by `get_speed_multiplier` of the cell it moves into. `GridPathfinder` sets each point's `weight_scale` to `1 / multiplier`, so AStar2D prefers roads.
- **Drawing**: `RoadLayer` (`scripts/world/road_layer.gd`), a Node2D that WorldGrid adds directly above the terrain layer. Brown for dirt, grey for stone; 0024 replaces the drawing.
- **Demolish** (`X` key, action `demolish_toggle`, or the **Demolish (X)** button; left-click, Esc or right-click leaves the mode). `demolish_at(cell)` tries a site (`cancel_site`, full refund of delivered goods), then a building (`demolish_building`), then a road (removed, no refund). `demolish_building`: unassigns each worker (`Worker.unassign`, which also returns carried goods to the workplace), releases each resident (`Settler.unassign_home`), removes the node from the child list (this unregisters storage at once, so `LaborManager.reconcile` and `SettlerManager` never see it), frees the cells, moves all inventory contents (storage, output, input, household) into other storage, refunds `cost / 2` per item through `ResourceStockpile.add` (overflow is lost, as before), then `queue_free`.
- **Dangling references**: the in-flight callbacks already check `is_alive` through instance ids (`Hauler._take`, `_put`, `_on_site_reached`, `_on_storage_meal`, `_on_restock_taken`). Claims (`output_claimed`, `restock_claimed`, `_reserved_site`) are released through `is_instance_valid` checks in `Worker._release_claims`. A worker's task is cancelled by `unassign`. Verified: a settler walking to a demolished house gets a refused delivery (0 accepted) and goes idle.
- **Build menu**: `BuildingMenu` lays out a 3-column grid of groups (Roads, Storage, Housing, Food, Resources, Industry). Group membership is a constant list of def ids in `building_menu.gd`; a new building must be added there or it will not appear.
- HUD: `BuildController.notice(text)` is connected to `add_toast` (one line in `hud.gd`) for demolition and partial stone placement.
- **Verified headless** (throwaway SceneTree script, normal speed): settler on a 12-tile dirt road takes 0.69x the off-road time (target 0.67), stone 0.52x (target 0.5); a path with a 3-row detour takes the road (12 of 13 tiles on road); stone line spends exactly the tiles it places and stops at zero stock; house demolish refunds 7 of 15 logs and releases two residents; a woodcutter's worker becomes a laborer; a demolished storage's wheat moves to another storage; road removal; save round trip of road count and types; after demolishing every house and workplace, 1500 frames run with no errors and population is unchanged.
- **Not exercised interactively**: the build menu grouping and the demolish button and `X` key wiring, the drag preview, and the visual road drawing.
- **Known limits**: roads refund nothing when demolished. Demolished storage contents that do not fit elsewhere are lost. A settler standing on a demolished road or field tile is not moved out, but the tile stays walkable. Roads cannot be placed on forest, so a road cannot cross a forest.
