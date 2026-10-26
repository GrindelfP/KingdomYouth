# 0015 — Resource catalog

- **Status:** done
- **Milestone:** M7 — Banished Economy
- **Depends on:** 0004, 0014

## Goal
Replace the hard-coded `WOOD/FOOD/STONE` enum with a data-driven resource catalog so the economy can grow to Banished's set of goods (logs, stone, iron, firewood, tools, several foods).

## Context
Banished's core tension comes from many interlocking goods: building materials, fuel, tools and a varied diet. Every later economy ticket (0016–0021) adds resources, so the catalog must make adding one a data-only change.

## Scope
- `ResourceDef` resource (`scripts/economy/resource_def.gd`): `id: StringName`, `display_name`, `category` (enum: MATERIAL, FUEL, TOOL, FOOD), `color: Color` (used for icons until art lands in 0023).
- `resources/goods/*.tres` for: `logs`, `stone`, `iron`, `firewood`, `tools`, `wheat`, `cabbage`, `berries`, `mushrooms`, `venison`, `fish`.
- `ResourceCatalog` (static helper or part of the autoload): lookup by id, list by category, all ids in a stable display order.
- `ResourceStockpile` keyed by `StringName` ids instead of the enum. Keep the public API shape (`get_amount`, `add`, `remove`, `can_afford`, `spend`, `resource_changed(id, amount)`), plus:
  - `get_food_total()` and `remove_food(amount)` (takes from the most plentiful food kind first, so diet varies naturally).
  - `get_category_total(category)`.
- Migrate all callers: building costs in `.tres` become `{&"logs": N, &"stone": N}`; job outputs use resource ids (`JobDef.output_type` → `output_id: StringName`); woodcutter currently outputs logs, farm outputs wheat; needs eat via `remove_food`; house heating burns `firewood` (falls back to nothing — no logs-as-fuel).
- Starting stock: logs 80, stone 30, iron 10, firewood 40, tools 12, wheat 60, berries 40.
- HUD resource bar: Logs, Stone, Iron, Firewood, Tools, Food (total). Hovering Food shows a tooltip with the per-kind breakdown. Each entry gets a small colored square icon from `ResourceDef.color` (replaced by real icons in 0023).
- Save/load stores stock as `{id: amount}`; bump `SAVE_VERSION`.

## Out of scope
- Physical storage and hauling (0016). Production of the new goods (0018–0020).
- Spoilage.

## Acceptance criteria
- [x] Adding a new good requires only a new `.tres` file (and registering it in the catalog list if the catalog uses an explicit list).
- [x] No references to `ResourceStockpile.Type` remain.
- [x] Settlers eat from any food kind; HUD food total matches the sum.
- [x] Building costs use logs/stone; heating uses firewood.
- [x] Save/load round-trips all goods.
- [x] Headless run is free of script errors.

## Open questions
- None.

## Implementation notes
- `ResourceDef` (`scripts/economy/resource_def.gd`) also has `sort_order` (display order) and `starting_amount`, so a new good is one `.tres` in `resources/goods/` with no code change. `ResourceCatalog` scans that directory lazily (handles `.remap` in exports).
- `ResourceCatalog` static API: `has(id)`, `get_def(id)`, `display_name(id)`, `all_ids()`, `ids_in_category(category)`.
- `ResourceStockpile` API: `get_amount`, `add`, `remove`, `can_afford`, `spend`, `get_category_total(category)`, `get_food_total()`, `remove_food(amount)` (atomic, most plentiful kind first), signal `resource_changed(id, amount)`. `reset()` and `from_save_data()` emit the signal for every good.
- `JobDef.output_id: StringName` replaces `output_type`. Building costs are `{&"logs": N}`; amounts unchanged from the old wood costs.
- Save version is 3; stock is saved as `{id: amount}`, unknown ids are ignored and missing ids load as 0.
- HUD shows Logs, Stone, Iron, Firewood, Tools and Food (total, with a per-kind tooltip) with colored square icons. Toast timers now ignore time scale.
- Nothing produces firewood yet (ticket 0019), so winter heating drains the starting 40.
