# 0006 — Settler entity: movement & pathfinding

- **Status:** done
- **Milestone:** M2 — Core Simulation Loop
- **Depends on:** 0002

## Goal
A settler entity exists that can be told "go to tile X" and walks there, respecting terrain walkability, without the player steering it directly.

## Context
Core premise of the game: settlers are not directly controlled. They need autonomous navigation so that later tickets (needs, jobs) can simply issue destinations and let this system handle the "how."

## Scope
- A `Settler` scene/script (`CharacterBody2D` or similar) with a visual placeholder (simple sprite/shape is fine — no final art yet).
- Pathfinding using Godot's grid-based navigation appropriate to the TileMap (`AStar2D` built from the walkability grid in 0002, or `NavigationServer2D`/`NavigationRegion2D` if that proves simpler — pick one and document the choice).
- A simple movement API: `move_to(grid_pos)`, with the settler walking tile-by-tile (or along the computed path) at a defined speed, and a signal/callback for "arrived" or "path blocked/unreachable."
- Handle the trivial failure case: destination unreachable (e.g. surrounded by water) — settler should stop and report failure, not get stuck forever.
- Spawn a small fixed number of starting settlers (per the game's premise — "a few uncontrollable settlers") at a defined start position when a new game begins.

## Out of scope
- Needs, jobs, work logic (0007/0008) — this ticket is purely "can move from A to B."
- Pathfinding around dynamic obstacles like other settlers (acceptable for them to overlap/pass through each other in MVP; crowd avoidance is a later polish item).
- Animation beyond the most basic (e.g. no walk-cycle sprite sheet required yet).

## Acceptance criteria
- [x] A settler instance can be commanded to move to an arbitrary walkable tile and arrives there, taking a sensible path around impassable terrain. (Headless: 53-tile route around water and rock arrived at the target.)
- [x] Movement respects 0002's walkability rules (never cuts through water/rock). (The path is only over walkable cells, checked in the test.)
- [x] An unreachable destination fails cleanly with a signal/callback, no infinite loop or crash. (Enclosed target: `path_failed` emitted once, settler stops.)
- [x] A fixed starting number of settlers spawn at game start at a defined location. (`STARTING_SETTLER_COUNT` in `scripts/entities/settler_manager.gd`, placed on the walkable tiles nearest the map center.)

## Decisions
- Pathfinding: `AStar2D` built from the walkability grid (`scripts/world/grid_pathfinder.gd`), one point per tile, 4-neighbour (orthogonal) connections only. Points are disabled and enabled through `WorldGrid.walkability_changed`, so buildings (0005), and later harvesting (0009), keep it in sync without a rebuild.
- Settler is a `Node2D` script (`scripts/entities/settler.gd`) with a circle placeholder drawn in `_draw`. No `CharacterBody2D`, since movement is grid-driven and needs no physics.
- Speed: 3 tiles per second.
- Signals: `arrived(grid_pos)`, `path_failed(grid_pos)`. An unreachable target fails synchronously from `move_to`, which returns `false`.
- Planning always starts from the last tile the settler reached. If the next tile becomes blocked mid-walk, the settler replans from there, which may mean stepping back to that tile first.
- A settler standing on a tile that gets built over is not stuck. The A* search still works from a disabled start tile (checked), and the settler walks off.
- Settlers do not block each other and do not block placement.

## Open questions
- Settler spawn uses the nearest walkable tiles to the map center. Revisit when spawn position becomes a setting.
- Crowd avoidance is out of scope (see above).
- Exact starting settler count — Banished starts with a handful (commonly a few families); pick a small number (e.g. 4–6) for MVP and make it easy to change later.
- `AStar2D` vs `NavigationRegion2D` — recommend `AStar2D` built directly from the TileMap's walkable cells, since it maps 1:1 onto the grid model from 0002 and is simpler to keep in sync when terrain changes (e.g. a forest tile being harvested in 0009).
