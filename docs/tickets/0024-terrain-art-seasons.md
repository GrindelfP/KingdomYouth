# 0024 — Terrain art & seasonal landscape

- **Status:** ready
- **Milestone:** M9 — Visual Overhaul
- **Depends on:** 0023, 0018, 0022

## Goal
A landscape that looks alive and changes with the seasons: textured ground with variation, individual trees, shorelines, rocks — green in spring, golden in autumn, white in winter.

## Context
Seasons are the only time cycle (owner decision), so they must be strongly visible. Today terrain is four flat colored squares.

## Scope
- Generated terrain atlas (via 0023 pipeline): for each season a row of tiles — grass (≥ 4 variants with tufts/flowers), dirt/stump ground, water (2 variants; frozen ice in winter), rock ground. Tile choice per cell is deterministic from a hash of the cell so the map does not flicker.
- Shorelines: water cells adjacent to land show sand/edge pixels (precomputed edge tiles for the 4 sides + corners, or an overlay pass — implementer's choice).
- **Trees as objects**: forest cells render tree sprites on a y-sorted layer (not ground tiles): ≥ 3 conifer/broadleaf variants, growth stages from 0018 (sapling, young, mature), seasonal palettes (spring light green, summer deep green, autumn orange/red/yellow for broadleaf, winter bare branches or snow-capped conifers). Trees overlap the tile above for depth.
- **Rocks**: rock cells show boulder clusters with highlights; snow caps in winter.
- Roads (0022) get textured dirt/cobble tiles that join neighbours (straight/corner/junction via a 4-bit neighbour mask).
- Seasonal transition: when the season changes, cross-fade over ~3 real seconds (e.g. two layers or a shader blend). A subtle, constant-per-season color grade is allowed; no time-of-day lighting.
- Gentle ambient life: occasional falling leaves in autumn and snow particles in winter (CPUParticles2D, cheap).
- Performance: 64x64 map must stay smooth; use TileMapLayer for ground and batched drawing (or MultiMesh) for trees if needed.

## Out of scope
- Building and settler art (0025, 0026).

## Acceptance criteria
- [ ] Ground has visible texture and variation; no two neighbouring grass tiles look like copies.
- [ ] Each season is recognizable at a glance from a screenshot.
- [ ] Trees show growth stages and seasonal foliage.
- [ ] Shorelines and rocks read clearly.
- [ ] Screenshots of all four seasons are reviewed by the implementer (rendered with a windowed run that saves the viewport) before marking done.
- [ ] Headless run is free of script errors.

## Open questions
- None.
