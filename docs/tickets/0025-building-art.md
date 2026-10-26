# 0025 — Distinct building art

- **Status:** ready
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
- [ ] Each building type is distinguishable from every other in a screenshot at default zoom without UI.
- [ ] Construction visibly progresses through stages.
- [ ] Depth sorting with trees and settlers looks correct.
- [ ] Implementer reviews screenshots (windowed run saving the viewport) of a town with every building type before marking done.
- [ ] Headless run is free of script errors.

## Open questions
- None.
