# 0019 — Households, firewood & tools

- **Status:** ready
- **Milestone:** M7 — Banished Economy
- **Depends on:** 0018

## Goal
Close Banished's survival loop: houses keep their own food and firewood, settlers must fetch them, winter needs firewood, and work needs tools that wear out.

## Context
In Banished, homes far from storage go hungry and cold; firewood must be processed from logs; tools from a blacksmith double productivity. These chains are what turn a village into an economy.

## Scope
- **Crafting job loop** (generic): a workplace with `inputs` fetches inputs from the nearest storage (worker walks there, carries up to the needed batch), works for `work_time`, puts outputs in its buffer (hauled per 0016/0017).
  - **Woodcutter** (2x2, 1 worker): 1 logs → 3 firewood.
  - **Blacksmith** (2x2, 1 worker): 1 iron + 1 logs → 1 tools.
- **Tools**: each working settler has `tool_wear` (0..1). Work consumes wear so one tool lasts about one year of continuous work. With no tool, work time is doubled. When the tool breaks or is missing, the worker fetches one from storage on its next trip. Info panel shows tool state.
- **Household inventory**: each house has an `Inventory` (food 30, firewood 20). When below half, a resident fetches from nearest storage (food: take mixed kinds, up to 10; firewood up to 10). Settlers eat from their house when at home; when hungry and away, they go home to eat; homeless settlers eat directly at a storage building.
- **Heating**: in winter a house with residents burns 1 firewood per ~20 s from its own inventory. Settlers outside in winter lose warmth and go home to warm up when warmth < 40 (interrupting work).
- **Diet variety**: a house whose stock contains ≥ 3 food kinds gives residents a small health regen bonus; 1 kind gives a small penalty. Info panel shows the house's food kinds.
- **Starvation** stays as in 0007, but now triggered by the house being empty, not the global pool.
- Remove the old global heating/eating shortcuts.
- Save/load: house inventories, tool wear, crafting progress.

## Out of scope
- Clothing/leather/tailor, health/herbalist, disease (later).

## Acceptance criteria
- [ ] Logs become firewood at a woodcutter; iron+logs become tools at a blacksmith.
- [ ] Houses stock food and firewood; a house far from storage takes visibly longer to restock.
- [ ] A town without firewood suffers in winter; with it, survives.
- [ ] Workers without tools are measurably slower.
- [ ] Save/load round-trips household inventories and tool wear.
- [ ] Headless run is free of script errors.

## Open questions
- None.
