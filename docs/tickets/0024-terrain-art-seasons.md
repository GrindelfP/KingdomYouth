# 0024 — Terrain art & seasonal landscape

- **Status:** done
- **Milestone:** M9 — Visual Overhaul
- **Depends on:** 0023, 0018, 0022

## Style
Follow `docs/art-style.md` and the pipeline notes in ticket 0023 (`tools/art/`).

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
- [x] Ground has visible texture and variation; no two neighbouring grass tiles look like copies.
- [x] Each season is recognizable at a glance from a screenshot.
- [x] Trees show growth stages and seasonal foliage.
- [x] Shorelines and rocks read clearly.
- [x] Screenshots of all four seasons are reviewed by the implementer (rendered with a windowed run that saves the viewport) before marking done.
- [x] Headless run is free of script errors.

## Open questions
- None.

## Implementation notes
- Generators: `tools/art/gen_terrain.gd` (ground, shore, roads atlases), `tools/art/gen_nature.gd` (trees, rocks, particles), shared helpers in `tools/art/art_util.gd` (periodic noise so tiles tile seamlessly, Bayer index helper). Output in `assets/art/terrain/`; deterministic (md5 verified). Regenerate: generator, then `--import`.
- Atlas layout (all 32 px cells, season rows: 0 spring, 1 summer, 2 autumn, 3 winter):
  - `ground.png`: columns 0-5 grass variants (plain, plain, tufts, white/yellow flowers, pink flowers, mixed/pebbles; autumn: leaf litter; winter: twigs, footprints, stones), 6-7 forest floor, 8-9 rock gravel, 10-11 water (winter: ice). One row per season.
  - `shore.png`: columns are the dense indices of `ShoreMask.keys()` (47 keys: 4 side bits + corner bits that are not covered by a side). Row `season*2` is the sand bank drawn on land cells next to water, row `season*2+1` is foam/wet edge drawn on water cells next to land (winter: frozen shore, snow edge).
  - `roads.png`: 16 columns = 4-bit neighbour mask (N=1, E=2, S=4, W=8), row `season*2` dirt, `season*2+1` cobble.
  - `trees.png`: 32x48 cells, column = `variant*3 + stage` (variants: oak, birch, conifer; stages: sapling, young, mature), row = season. Trunk base is at (16, 44).
  - `rocks.png`: 32x32 cells, column = variant (3 boulder clusters), row = season. Base at (16, 27).
  - `leaf.png`, `snow.png`, `petal.png`: particle textures.
- Runtime (scripts/world):
  - `TerrainView` (node `TerrainView` in `world.tscn`): paints the ground, shore overlay and `RoadLayer` onto two stacks (two `TileMapLayer`s + a road layer each, z_index -10). The logic `Terrain` TileMapLayer (4 flat tiles, used by `WorldGrid` for terrain/walkable data) is now `visible = false` and untouched. Tile variant per cell is a hash of the cell (seeded with `MAP_SEED`), re-rolled if equal to the left or up neighbour; tile alternatives provide horizontal flips and a subtle light/dark tone patch from low-frequency noise (not in winter). Water cells swap between the two variants every 0.9 s for a shimmer (not in winter).
  - Seasonal switch API: `TerrainView.set_season(season: int, animate: bool)` and signal `season_applied(season, animate)`. It follows `TimeManager.season_changed` (animated) and is re-synced to `TimeManager.get_season()` without animation on `map_generated` and `trees_reloaded` (new game, load). The new season is painted on the hidden stack, which fades in over 3 s (`FADE_SECONDS`) on top of the old one; a constant per-season `CanvasModulate` grade tweens at the same time. `NatureLayer` and `AmbientLife` listen to `season_applied`. Painting plus the switch takes about 10 ms for a 64x64 map.
  - `NatureLayer` (node `Nature`): one `Sprite2D` per tree (about 830 on the default map) and per boulder (62% of rock cells), `centered = false`, `offset = -base`, positioned at the cell centre + (jitter, 15). Textures are shared `AtlasTexture`s. Reacts to `trees_changed` (growth, felling, planting) and `trees_reloaded`. Tree variant comes from low-frequency noise (conifer groves, birch groves, mixed oak). Season changes put a fading ghost sprite (old texture) on top of every sprite.
  - `RoadLayer.season` selects the atlas row; the 4-bit neighbour mask is computed from `WorldGrid.get_road`. `WorldGrid` no longer creates the road layer, `TerrainView` owns one per stack.
  - `AmbientLife` (node `Ambient`, z_index 30): three `CPUParticles2D` that follow the camera (autumn leaves, winter snow, spring petals).
- Objects layer and y-sort: the `World` root has `y_sort_enabled = true`, and `Nature`, `Buildings` and `Settlers` are y-sort enabled children, so everything they contain is depth sorted together by global y (the ground stacks have z_index -10 and are always below, particles z_index 30 above). Sprites sort by their node `position.y`, so the node origin must be the base of the object (bottom of the footprint). `BuildController` now draws its placement preview, work radius and road preview on a child `Node2D` with z_index 100 so they stay above sorted objects.
- How 0025 adds building sprites: add a `Sprite2D` (or an `AnimatedSprite2D`) as a child of the `Building` node, with `centered = false` and `offset` so the bottom edge of the sprite sits at the footprint bottom, and make the `Building` node origin the bottom-centre of its footprint (today it is the top-left corner, which sorts correctly only for non-overlapping neighbours). Nothing else is needed for sorting with trees and settlers; do not set z_index on buildings. Season-dependent sprites should connect to `TerrainView.season_applied` (find it with `world.get_node("TerrainView")`).
- Performance: ground is 2 stacks x (2 TileMapLayers) = about 16k tiles total, trees are about 1000 `Sprite2D`s with y-sort; a documented trade-off to keep per-tree growth/felling and depth sorting trivial. Zoomed in/out frames render without issues. Particle count is constant (260 snow, 90 leaves, 40 petals).
- Verification: captured real frames with a throwaway scene (not committed) using `--write-movie` for spring, summer, autumn and winter at zoom 1, zoom 0.5 and zoom 2-3, with roads, saplings/young trees, shoreline close-ups and a mid-fade frame; iterated on the art until the seasons were readable at a glance. `--headless --quit-after 600` is free of errors and warnings.
- Known limitations: forest floor and rock gravel are rectangular tiles without edge blending into grass; snow particles are faint over snow. Water has no depth shading.
