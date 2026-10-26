# 0020 — Crop fields with a seasonal lifecycle

- **Status:** ready
- **Milestone:** M7 — Banished Economy
- **Depends on:** 0019

## Goal
Replace the abstract farm with Banished-style crop fields: planted in spring, grown through summer, harvested in autumn, lost to the first frost if left in the ground.

## Context
Farming is Banished's biggest food source and its most season-driven one. Over-sized fields with too few farmers lose crops to winter; this is a core management decision.

## Scope
- **Crop Field** building: footprint chosen by the player from presets 4x4, 6x6, 8x8 (cycle with `R` or buttons during placement; cost scales), up to 4 farmers.
- Crop choice per field (info panel buttons): Wheat or Cabbage. Changing crop takes effect next spring.
- Per-cell state: `empty → plowed → planted → growing (0..1) → ripe → harvested`.
  - Early Spring – Late Spring: farmers walk to cells and plow/plant them.
  - Growth advances automatically from planting through summer; Cabbage ripens earlier (Late Summer), Wheat later (Early Autumn).
  - Ripe cells are harvested one by one by farmers (each cell yields ~2 of the crop into the field's buffer, hauled to storage).
  - At the start of winter all unharvested cells are lost and reset to empty; toast "Frost destroyed crops at …".
- Field draws cell states clearly (plowed soil, sprout, growing, ripe) with simple shapes; final art comes in 0025.
- Info panel: crop, planted/ripe/harvested counts, workers.
- Retire the old Farm def; save/load per-cell states and crop choice.

## Out of scope
- Orchards, livestock, crop diseases.

## Acceptance criteria
- [ ] Over a year a staffed field goes through plant → grow → harvest, producing food into storage.
- [ ] An understaffed large field loses unharvested cells at winter.
- [ ] Crop type and field size are selectable.
- [ ] Save/load round-trips per-cell states.
- [ ] Headless run is free of script errors.

## Open questions
- None.
