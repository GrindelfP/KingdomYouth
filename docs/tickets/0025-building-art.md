# 0025 — Distinct building art

- **Status:** done
- **Milestone:** M9 — Visual Overhaul
- **Depends on:** 0024, 0020, 0021

## Style
Follow `docs/art-style.md` and the pipeline notes in ticket 0023 (`tools/art/`).

## Goal
Every building is instantly recognizable: unique sprite, silhouette, roof color and prop, plus readable construction stages.

## Context
Owner feedback: "all structures look the same" (they are identical brown rectangles). This is the most visible complaint.

## Scope
- Generated sprites (0023 pipeline) for every BuildingDef: house, stockpile, storage barn, forester's lodge, gatherer's hut, hunting cabin, fishing dock, quarry, mine, woodcutter, blacksmith, crop field (field is drawn from cell states, with fence posts at the border). Guidance (follow `docs/art-style.md`):
  - House: timber walls, thatch roof, chimney (smoke particles when heated in winter).
  - Stockpile: fenced dirt yard; draw actual piles of contained goods (log stacks, stone blocks, firewood) scaled with contents.
  - Storage Barn: big red/brown barn roof, open doors, sacks.
  - Forester: dark green roof, sapling bed, axe stump.
  - Gatherer: small round thatch hut, baskets of berries.
  - Hunter: hide-covered roof, antlers, drying rack.
  - Fishing Dock: wooden pier over water edge, fish rack.
  - Quarry: stepped grey pit with stone blocks; Mine: dark entrance in rock with cart and rails.
  - Woodcutter: chopping block, firewood stacks; Blacksmith: slate roof, chimney with glow, anvil.
- Sprites may be taller than the footprint (roofs extend up); anchored at the footprint bottom; buildings, trees and settlers share one y-sorted layer so depth works.
- Crop field cells: plowed furrows, sprouts, growing green, ripe golden wheat / round cabbages, stubble; winter: snow over soil.
- Construction stages: site markers + foundation (0–33%), timber frame (33–66%), partial walls/roof (66–100%); undelivered materials shown as a faded ghost of the final sprite.
- Selection: outline highlight on hover and on the selected building; name tooltip on hover.
- Seasonal: snow on roofs in winter.
- Placement preview shows the actual sprite tinted green/red instead of a flat rectangle.

## Out of scope
- Animations beyond smoke/glow; building upgrades.

## Acceptance criteria
- [x] Each building type is distinguishable from every other in a screenshot at default zoom without UI.
- [x] Construction visibly progresses through stages.
- [x] Depth sorting with trees and settlers looks correct.
- [x] Implementer reviews screenshots (windowed run saving the viewport) of a town with every building type before marking done.
- [x] Headless run is free of script errors.

## Open questions
- None.

## Implementation notes
- Generators: `tools/art/gen_buildings.gd` (11 finished sprites, each with a `_winter` variant), `tools/art/gen_building_support.gd` (construction stages, field fences, field tiles, stockpile piles, smoke and glow textures), shared drawing helpers in `tools/art/building_parts.gd` (plank/log/stone walls, textured roofs, snow overlay, doors, windows, props). All registered in `generate_art.gd`; output in `assets/art/buildings/` is byte-identical between runs.
- Sprite layout: `<id>.png` and `<id>_winter.png`, canvas = `footprint*32 + 16` wide (8 px side pad) and `footprint*32 + extra + 6` tall (6 px bottom pad for the shadow); `SPECS` in `gen_buildings.gd` holds `[fw, fh, extra]`. The footprint bottom edge is at `height - 6`. Spring, summer and autumn share one sprite; winter adds roof snow and ground snow.
- Anchoring: `Structure` now sits at the bottom-centre of the footprint (`bind_to_grid`), so the shared y-sort works with trees and settlers. Everything keyed on cells (`occupies`, access cells, work centre, save/load, click picking) is grid-based and unchanged. `Structure.local_rect()` gives the footprint in local coordinates. Sprites use `BuildingArt.sprite_offset(texture)`.
- Adding a building sprite: add a `[fw, fh, extra]` entry to `SPECS`, write `_<id>(winter: bool)` in `gen_buildings.gd` and a case in `_make`, regenerate and `--import`. `BuildingArt.texture(def, winter)` finds it by `def.id`. Optional chimney smoke point / forge glow point go into `BuildingArt.SMOKE_POINTS` / `GLOW_POINTS` (sprite pixel coordinates).
- `BuildingArt` (`scripts/buildings/building_art.gd`) is the runtime lookup (textures, offsets, field tile columns, pile slots and thresholds). `Structure` handles season switching via `TerrainView.season_applied` and the outline (`set_outline(0 none, 1 hover, 2 selected)` using `assets/shaders/structure_outline.gdshader`). Fields are drawn in `Building._draw` from `field_tiles.png` (15 columns by state/crop/variant, row 1 snowy) plus a fence sprite, with `z_index = -5` so settlers always walk above them.
- Stockpile piles: `Building._refresh_piles` (polled every 0.3 s) places one pile sprite per good (logs, stone, firewood, iron, tools) at fixed slots; 4 stages at 1, 20, 60, 140 units; snow caps in winter. House smoke emits while `is_heated()`; the blacksmith emits smoke and shows a pulsing additive glow while it has workers.
- Construction: `ConstructionSite` shows `site_<n>.png` (n = 2, 3, 4 footprint; fields use `fence_<n>.png` stages 0-2 over bare soil) with the stage from `progress_ratio` (foundation, timber frame, walls and rafters) and a ghost of the finished sprite whose alpha falls with `material_ratio` (undelivered materials). Progress and material bars appear only when hovered or selected.
- Hover and selection: `BuildController` finds the structure under the mouse (grid occupancy, only when not over GUI), outlines it white (hover) or gold (selected, set via `set_highlight`) and shows a name tooltip on a `CanvasLayer`. The placement preview draws the real sprite tinted green or red over the flat footprint tint.
- Fix included: `BuildController.clear_buildings` freed every child, including the overlay (so the overlay died on load); it now frees only `Structure` nodes.
- Verification: headless logic scenario (place, deliver, build, click-select, save/load, demolish site and building) all passing; `--headless --quit-after 600` free of errors and warnings. Captured real frames (throwaway scene, not committed) with every building, sites at 0/20/50/80%, fields in several crop states, in summer and winter, at zoom 0.5, 1 and 2; iterated on art until each building read distinctly.
- Known limitations: fishing dock is orientation-agnostic (a deck with fish rack, not tied to the water side); construction frames are a generic wireframe per footprint; spring/summer/autumn buildings share a sprite.
