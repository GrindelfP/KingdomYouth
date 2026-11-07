# 0039 — Orchards & imported seeds

- **Status:** ready
- **Milestone:** [M16 — Orchards & Pastures](../roadmap.md#m16--orchards--pastures)
- **Depends on:** 0034, 0038

## Goal
Add a long-term fruit investment that requires imported seeds, land, labor, and several growing seasons.

## Context
Reuse field placement/work targeting, seasonal time, physical output, and diet categories. Keep cultivated trees separate from renewable wild forest resources.

## Scope
- Add one fruit crop (apples), orchard footprint presets, orchard worker slots, and per-tree planting/age/maturity/harvest/replant state.
- The first purchased apple-seed entitlement unlocks cultivation permanently; it is consumed into that unlock, not repeatedly counted as food or a seed for every tree.
- Workers plant and harvest reachable tree cells. Trees yield only after a documented multiyear maturity period, then seasonally; aging/removal requires replanting with a renewed maturity delay.
- Route apples through real output/transit/storage into the fruit diet category; respect production ceilings without deleting ripe fruit silently.
- Show locked-build guidance, tree stages/harvest status, seasonal generated art, and persisted unlock/tree state.

## Out of scope
- More fruit varieties, disease, orchard fires, and autonomous expansion.

## Acceptance criteria
- [ ] An unpurchased orchard cannot be established; buying seeds unlocks exactly one persistent crop capability.
- [ ] Young trees produce no fruit; mature staffed orchards yield seasonal apples into real storage.
- [ ] Understaffing, winter harvest loss, aging/replanting, and demolition have documented behavior.
- [ ] Tree ages, pending harvests, unlocks, and goods round-trip without an extra harvest.
- [ ] Multi-year headless checks pass; each tree stage and seasonal UI/art is reviewed.

## Open questions
- None; document footprint costs, maturity/lifespan, harvest window, and yields before the multi-year check.
