# 0016 — Physical storage & hauling

- **Status:** ready
- **Milestone:** M7 — Banished Economy
- **Depends on:** 0015

## Goal
Goods exist physically: they live in storage buildings with limited capacity, and settlers carry them there. Town layout (distance to storage) starts to matter, as in Banished.

## Context
In Banished, production is wasted walking if storage is far away, and running out of storage space stalls production. This is the main reason players plan their towns; our current global counter skips it entirely.

## Scope
- `Inventory` class (`scripts/economy/inventory.gd`): `capacity`, `{id: amount}`, `add` (returns accepted amount), `take`, `free_space`, `total`, save/load helpers.
- Storage buildings (BuildingDef gets `storage_capacity` and optional `storage_categories` filter; empty = anything):
  - **Stockpile**: 4x4, free, capacity 400, accepts MATERIAL/FUEL/TOOL.
  - **Storage Barn**: 3x3 (replaces old 2x2 barn), logs 40 + stone 20, capacity 600, accepts FOOD/TOOL/FUEL.
- `ResourceStockpile` becomes the aggregate view over all storage inventories (same public API). `add` deposits into storage nearest to the town center (fallback path used only by bootstrap/debug); `remove` withdraws from storages. Signals still fire on any change. Add `get_capacity(category)` / `get_free_space(id)`.
- New game: a pre-built Stockpile and Storage Barn are placed near the map center at start, holding the starting stock from 0015.
- Workplaces get a small output `Inventory` (capacity 20). The worker puts each output there; when it holds ≥ 10 (carry size) or the worker's job stalls, the worker carries up to 10 units to the nearest storage that accepts them (pathing there and back), deposits, and returns to work. If no storage has room, the workplace fills and the worker idles (info panel shows "storage full").
- Settlers draw a small carried-goods marker (colored square from `ResourceDef.color`) while carrying.
- HUD: storage usage line (e.g. `Storage 320/1000`), toast when storage is nearly full.
- Info panel for storage buildings lists contents; for workplaces shows the output buffer.
- Save/load: storage contents, workplace buffers, carried goods.

## Out of scope
- Laborers hauling for other buildings and supplying construction (0017).
- Household stocking (0019).

## Acceptance criteria
- [ ] Global amounts equal the sum of storage inventories at all times.
- [ ] A woodcutter far from storage visibly walks logs back; production per minute drops with distance.
- [ ] Full storage stops production and the UI explains why.
- [ ] Building a second storage increases capacity.
- [ ] Save/load round-trips storage and buffers.
- [ ] Headless run is free of script errors.

## Open questions
- None.
