# 0016 — Physical storage & hauling

- **Status:** done
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
- [x] Global amounts equal the sum of storage inventories at all times.
- [x] A woodcutter far from storage visibly walks logs back; production per minute drops with distance.
- [x] Full storage stops production and the UI explains why.
- [x] Building a second storage increases capacity.
- [x] Save/load round-trips storage and buffers.
- [x] Headless run is free of script errors.

## Open questions
- None.

## Implementation notes
- `Inventory` (`scripts/economy/inventory.gd`): `capacity`, `add(id, n) -> accepted`, `take(id, n) -> taken`, `get_amount`, `total`, `free_space`, `ids()`, `to_save_data`/`from_save_data`, signal `changed(id)`. Household inventories (0019) can use it directly.
- `BuildingDef`: `storage_capacity`, `storage_categories: Array[int]` (ResourceDef.Category values; empty = anything), `is_storage()`, `accepts(id)`. New `stockpile.tres`; barn is 3x3, 40 logs + 20 stone.
- `Building.storage` (storage buildings) and `Building.output` (workplaces, capacity `Building.OUTPUT_CAPACITY` 20); `is_output_blocked()` drives the "storage full" info line.
- `ResourceStockpile` is now an aggregate view over registered storage buildings: `register_storage`/`unregister_storage` (done by `Building`), `find_storages(id, from_cell)` (accepting storages with room, nearest first), `get_capacity(category = -1)`, `get_stored_total()`, `get_free_space(id)`, `get_storages()`, signal `storage_changed`. `add` returns the accepted amount and fills storages nearest the map center; `remove` withdraws nearest the center first. The stockpile has no `reset`-time stock: starting goods are deposited by `GameBootstrap` after `BuildController.place_starting_storage(avoid_cells)` places the free pre-built Stockpile and Barn.
- Hauling lives in `Worker` (states PICKUP, DELIVER): at >= `HAUL_SIZE` (10) in the buffer, or when the job stalls (no target, off season, buffer full), the worker walks to the workplace, takes up to 10 of the richest good, walks to the nearest reachable storage access cell and deposits; leftovers go to the next storage. The `Settler` carries goods via `carried_id`/`carried_amount`, `set_carried()`, `is_carrying()`, drawn as a colored square. A worker with a carried load and no building still delivers, so 0017 laborers can reuse `_begin_delivery`/`_reachable_access_cell` (candidate for extraction into a shared helper). Cancelling a task returns carried goods to the workplace buffer.
- Placement still spends cost immediately (0017 changes that). Save version 4: global stock is no longer saved; each building saves `storage` and `output`, settlers save carried goods. Older saves fail to load.
- HUD shows `Storage used/capacity` and toasts at 90 percent (re-armed below 80 percent).
- Verified headless with a throwaway scenario: starting stock sums to 272 in 2 storages (cap 1000), a lodge's logs reach storage via carrying, the aggregate equals the per-storage sum, save/load restores stored goods, buffers and carried goods, full storage flags the workplace as blocked, and a second barn raises capacity to 1600.
