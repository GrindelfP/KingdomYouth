# 0017 — Laborers, builders & profession management

- **Status:** ready
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
- [ ] Placing a building creates a site that is completed only after materials arrive and builders work on it.
- [ ] With 0 builders nothing gets built; with more builders sites finish faster.
- [ ] Laborers visibly carry materials to sites and empty workplace buffers.
- [ ] Profession panel changes counts and settlers switch jobs without manual clicks.
- [ ] Cancelling a site refunds delivered goods.
- [ ] Save/load round-trips all of the above.
- [ ] Headless run is free of script errors.

## Open questions
- None.
