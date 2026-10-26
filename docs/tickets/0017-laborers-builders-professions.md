# 0017 — Laborers, builders & profession management

- **Status:** done
- **Milestone:** M7 — Banished Economy
- **Depends on:** 0016

## Goal
Adopt Banished's labor model: construction is done by builders with delivered materials, laborers haul goods, and the player allocates workers by profession count rather than by clicking individual settlers.

## Context
In Banished the player never moves a settler. They set how many builders, laborers and per-building workers they want, and the town reshuffles itself. Construction is the main sink for labor and materials and is a key pacing lever.

## Scope
- Professions: `Laborer` (default for unassigned adults), `Builder`, plus one per workplace job.
- **Construction**: placing a building no longer spends stock. A `ConstructionSite` has a `required` dict (the cost) and a `delivered` inventory. Laborers (and builders when idle) carry materials from storage to the site. Once all materials are delivered, builders work on it; build progress advances by builder work-seconds (`build_time` is total work for one builder; more builders = faster). Placement is allowed even without stock; the site shows "waiting for materials".
- Site drawing shows a progress bar and a materials bar. Cancelling a site (right-click on it or Delete in its info panel) returns delivered materials to storage.
- **Laborer task picking** (nearest-first, simple priority): 1) deliver materials to construction sites, 2) empty workplace output buffers into storage, 3) idle near the town center.
- **Profession panel** (button "Professions" in the top bar, key `P`): rows for Laborer, Builder and each job type showing `assigned / max` (max = total slots in built workplaces; builders have no max). `+` moves the nearest laborer into the profession; `-` returns the farthest worker of that profession to laborers.
- Workplace info panel: `+`/`-` to set its desired worker count (0..slots); the town fills it from laborers automatically.
- Remove the old click-to-assign flow in `JobController` (selection and info panel stay).
- New game defaults: 2 builders, rest laborers.
- Save/load: professions, site deliveries and builder progress, workplace desired counts.

## Out of scope
- Children/elderly restrictions (0021). Roads (0022).

## Acceptance criteria
- [x] Placing a building creates a site that is completed only after materials arrive and builders work on it.
- [x] With 0 builders nothing gets built; with more builders sites finish faster.
- [x] Laborers visibly carry materials to sites and empty workplace buffers.
- [x] Profession panel changes counts and settlers switch jobs without manual clicks.
- [x] Cancelling a site refunds delivered goods.
- [x] Save/load round-trips all of the above.
- [x] Headless run is free of script errors.

## Open questions
- None.

## Implementation notes
- `Structure` (`scripts/buildings/structure.gd`) is the shared base of `Building` and `ConstructionSite`: `def`, `origin`, `occupies`, `get_center_cell`, `get_access_cells`, `is_alive`. Anything a settler can walk to is a `Structure`.
- `Hauler` (`scripts/entities/hauler.gd`) is the reusable trip helper owned by each `Worker`: `walk_to(structure, cb)`, `fetch(source, inventory, id, amount, done(taken))`, `deliver(sink, inventory, done(accepted))`, `deliver_to_storage(done)`, `reachable_access_cell`, `CARRY_SIZE` 10. Callbacks bind instance ids, so a structure freed mid-trip (cancelled site) is handled. 0019 household trips should build on `fetch`/`deliver` with a house `Inventory`.
- `Worker._plan()` is the single place deciding the next action by `Settler.profession`: carrying goods always delivers to storage first; laborer = materials to sites, then empty workplace buffers (at least 5 unclaimed), then walk to the storage nearest the map center; builder = build a fully delivered site, else the laborer plan; any job profession = the old workplace loop (`_plan_job`). New job types in 0018/0019 extend `_plan_job`. Children (0021) should be given a profession that `_plan` ignores.
- Professions: `Professions.LABORER`, `Professions.BUILDER`; a job's profession is `JobDef.profession_id()` (lowercased `job_name`). `Worker.set_profession()` switches laborer/builder, `Worker.assign()/unassign()` switch job professions.
- `LaborManager` (node `Labor` in the world scene): `profession_ids()`, `get_count`, `get_max` (-1 = unlimited), `can_increase/can_decrease`, `increase/decrease`, `set_desired_workers(building, n)`, `reconcile()` (every 0.5 s: fills each workplace up to `Building.desired_workers` from the nearest laborers, removes the farthest workers above it). Job `+/-` changes `desired_workers`; a new workplace defaults to all slots.
- `ConstructionSite`: `required` (def cost), `delivered` Inventory, `missing(id)` (excludes in-flight `reserve`d amounts), `is_ready()`, `add_work(seconds)` (called by each builder per frame, so work scales with builder count), `refund()`, `status_text()`. `BuildController.cancel_site()`, `get_sites()`, `get_buildings()`, `find_site_at()`, signal `construction_cancelled`. Placement no longer spends stock and no longer fails for lack of resources.
- Build times raised because they are now builder-seconds: house 20, lodge 15, farm 24, stockpile 12, barn 30.
- `Building.output_claimed` stops several laborers from targeting the same buffer. `ResourceStockpile.find_sources(id, from)` lists storages holding a good, nearest first.
- Input: actions `professions_toggle` (P) and `delete_selected` (Delete). The info panel skips its periodic rebuild while the left mouse button is held so button clicks are not lost.
- Save version 5: settlers save `profession`, buildings save `desired_workers`, sites save `delivered` and `progress`. Goods in flight to a site are not reserved after a load; the carrying laborer returns them to storage.
- Verified headless with a throwaway scenario at high time scale: house and lodge sites receive materials by carrying laborers and are completed by builders, the lodge auto-fills with 2 woodcutters, profession counts and `+/-` change, 0 builders builds nothing, cancel refunds delivered goods with no script errors, and professions, desired workers and site deliveries survive save/load. Not exercised interactively: the profession panel buttons, right-click cancel and Delete key wiring.
- Known limit: if all storage is full, a cancel refund drops the overflow.
