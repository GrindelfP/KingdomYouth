# 0019 — Households, firewood & tools

- **Status:** done
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
- [x] Logs become firewood at a woodcutter; iron+logs become tools at a blacksmith.
- [x] Houses stock food and firewood; a house far from storage takes visibly longer to restock.
- [x] A town without firewood suffers in winter; with it, survives.
- [x] Workers without tools are measurably slower.
- [x] Save/load round-trips household inventories and tool wear.
- [x] Headless run is free of script errors.

## Open questions
- None.

## Implementation notes

**Crafting (data-driven):** `JobDef.inputs` (array of `{id, amount}` like `outputs`; helpers `has_inputs()`, `input_amount(id)`). Workplaces with inputs get `Building.input` (capacity 20). `Building.has_batch()`, `missing_input()` (an input below one batch), `input_trip_amount(id)` (fills up to `BATCHES_PER_TRIP` = 5 batches, max 10 per trip), `consume_batch()`. `Worker._plan_input_trip()` reuses `Hauler.fetch` then `Hauler.deliver` into `building.input`; work only starts with a full batch and the batch is consumed at the end of work (so a save mid-work loses nothing). Crafting progress saved = the `input` inventory (`input` key per building). New data: `woodcutter` (20 logs, 2x2, 1 worker, 6 s, 1 logs -> 3 firewood) and `blacksmith` (30 logs + 10 stone, 2x2, 1 worker, 12 s, 1 iron + 1 logs -> 1 tools), listed in `BuildController.building_defs`.

**Households:** `Building.household` (Inventory, capacity 50) on every house. Constants: `FOOD_TARGET` 30, `FIREWOOD_TARGET` 20, `RESTOCK_TRIP` 10. `needs_food()` / `needs_firewood()` are true below half the target. Helpers `food_stock()`, `firewood_stock()`, `diet_kinds()`. A new house starts empty and residents fill it. One restock trip carries a single kind (the carry model holds one good), choosing the food kind the house has least of, so variety builds up over several trips (deviation from "mixed kinds in one trip"). `Building.restock_claimed` stops several residents fetching for the same house. `Inventory` gained `category_total`, `kind_count`, `take_best(category, n)` (most plentiful first). `ResourceStockpile.remove_food` was removed; births now need `BIRTH_MIN_FOOD` (10) food in the house.

**Worker._plan priority:** carried goods are delivered first, then (for working-age settlers, gate `Settler.is_working_age()`, always true until 0021 makes children return false) `_plan_survival()`, then `_plan_tool()`, then the profession plan. Survival: hungry (>= 60) with a homed settler eats at home if there, goes home (`Hauler.walk_to_cell(home_cell)`) if the house has food, else restocks; homeless settlers walk to the nearest storage with food and eat from it; any homed settler restocks food/firewood when below half. `Worker.serve_hunger()` (called by `Settler` each second when hunger >= 85) interrupts work if a meal is reachable. The old behavior of pausing work at critical hunger was removed. Starvation now follows from an empty house (hunger reaching 100).

**Meals and heat:** `Needs.meal_provider` (Callable returning the house inventory when the settler stands on its home cell), `Needs.eat_from(inventory)`. Houses burn 1 firewood from `household` per 20 s in winter when residents exist (`SettlerManager._update_heating`). `needs.warm` is true only while standing at a heated home. `Settler` warms up like it rests: below `Needs.COLD_CALL` 40 in a heated winter home it pauses work and goes home until `Needs.WARM_FULL` 90. Diet: `Needs.diet_modifier` +0.2 health regen per second with >= 3 food kinds, -0.15 with exactly 1 kind.

**Tools:** `Settler.has_tool`, `tool_wear` (0..1), `TOOL_LIFETIME` 720 s of work (one game year at 60 s per month), `NO_TOOL_SPEED` 0.5. `wear_tool(seconds)` is called while working and building; at 1.0 the tool breaks. `needs_tool()` is true for builders and settlers with a job. `_plan_tool()` fetches one `tools` from the nearest storage. Work duration is divided by `work_speed()`, builder progress is multiplied by it. Settlers start without tools and pick up the starting 12. Info panel shows tool wear or "none (works at half speed)", a house's household stock and food kinds, and a crafter's input.

**Save:** `SAVE_VERSION` 7: settlers save `has_tool` and `tool_wear`; buildings save `input` and `household`. Old saves are rejected.

**Verified headless (throwaway scripts, time scale 10):** woodcutter and blacksmith run on fetched inputs (10 iron to 5 tools, firewood grows in storage), houses restock mixed food and firewood from storage, winter from month 9: with firewood average health stays 100 and warmth recovers at home, without firewood warmth hits 0 and average health falls to 74 within two winter months; a woodcutter without tools made 12 firewood against 21 with tools in the same time; save/load restored household, input and tool state.

**Not done / known limits:** tool breakage after 720 work-seconds was not run to completion; only wear accumulation was observed. Building info panel buttons not exercised interactively. Balance (firewood yield, house stock sizes) is first draft for 0027.
