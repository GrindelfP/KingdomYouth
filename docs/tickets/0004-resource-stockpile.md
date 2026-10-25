# 0004 — Global resource stockpile system

- **Status:** done
- **Milestone:** M2 — Core Simulation Loop
- **Depends on:** 0001

## Goal
A single source of truth for how much of each resource (wood, food, stone, tools, etc.) the settlement has, with an API every other system (construction, needs, jobs) can read from and write to.

## Context
Banished-style games track a shared settlement stockpile rather than per-building inventories for the MVP (per-building storage capacity/logistics is a later refinement, not needed for the first loop). Keep the model simple: one global counter per resource type for now.

## Scope
- Define the initial resource type list for MVP: `wood`, `food` (single generic food pool to start — see open questions), `stone`.
- An autoload/singleton (`ResourceStockpile` or similar) holding current amounts per type, with:
  - `add(type, amount)`, `remove(type, amount)` (with insufficient-funds handling — fail or clamp, decide and document), `get_amount(type)`.
  - A signal emitted on change (`resource_changed(type, new_amount)`) so UI (0012) can react without polling.
- A `Resource` enum or string-key convention decided once and used consistently everywhere else in the codebase.
- Starting resource amounts configurable (e.g. a small starting stock of wood for the first house/stockpile).

## Out of scope
- Per-building storage capacity/limits (later refinement).
- Resource decay/spoilage.
- Multiple food types with different nutrition (defer to post-MVP; see open questions).
- Tools/equipment resource (only add if a later ticket's buildings need it).

## Acceptance criteria
- [x] Autoload exposes add/remove/get for each defined resource type. (`ResourceStockpile` autoload, `scripts/autoload/resource_stockpile.gd`.)
- [x] `resource_changed` signal fires correctly on every mutation. (Checked headless: fires on each successful add/remove/spend, not on failed ones.)
- [x] Removing more than available is handled predictably (documented behavior, not a crash).
- [x] Starting amounts are configurable in one place, not magic numbers scattered in code. (`STARTING_AMOUNTS` in the autoload.)

## Decisions
- Enum `ResourceStockpile.Type { WOOD, FOOD, STONE }` is the single resource key convention. Costs and amounts are `Dictionary` keyed by that enum.
- Amounts are integers.
- Insufficient funds: `remove` returns `false` and changes nothing, and emits no signal. `spend(cost)` checks the whole cost first and only deducts when all of it is affordable, so it never leaves a partial deduction.
- `add` asserts a non-negative amount.

## Open questions
- Single generic `food` pool vs. distinct food types (grain, meat, berries) with later-game variety — recommend starting with a single `food` pool for MVP simplicity, splitting it out once farms/hunting/fishing are actually differentiated (post-MVP).
- Should resource amounts be floats or integers? Recommend integers (simpler UI, no fractional-wood weirdness).
