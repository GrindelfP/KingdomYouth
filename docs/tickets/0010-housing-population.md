# 0010 — Housing & population growth/death

- **Status:** done
- **Milestone:** M3 — Population & Time
- **Depends on:** 0005, 0007, 0009

## Goal
Houses matter (settlers need one to live in/rest in), and the population changes over time: new settlers are born when conditions allow, and settlers die when needs go critically unmet.

## Context
This is what turns the game from "manage a fixed cast" into "manage a growing/shrinking settlement," the core long-term tension of a Banished-like.

## Scope
- **House** building (via 0005's `BuildingDef` pattern): has a settler capacity. Settlers are assigned a home (manually by the player, or automatically on birth/arrival — decide and document).
- Wire 0007's stubbed "rest" need to actual houses: a settler without an assigned house, or unable to reach one, should suffer a defined consequence (can mirror hunger's consequence model).
- **Population growth**: define a birth condition (e.g. a couple/household with a house and sufficient food surplus, after a cooldown) that spawns a new settler. Keep this simple for MVP — it does not need to model families/relationships in depth.
- **Death**: wire up the consequence paths from 0007 (starvation) and this ticket's rest/shelter shortfall into an actual settler removal, with a minimal, non-disruptive cleanup (unassign job, remove from scene, update population count).
- A visible population counter concept (data only here; display is 0012).

## Out of scope
- Family/relationship modeling, named households, genealogy.
- Aging/elderly death from old age (nice Banished touch, but not MVP-critical — add later if time allows).
- Immigration (new settlers arriving from outside) — births are the only growth mechanism for MVP.

## Acceptance criteria
- [x] Houses can be built and have a defined capacity; settlers can be assigned to them. (`resources/buildings/house.tres`, capacity 4.)
- [x] A settler without adequate shelter suffers a defined, observable consequence over time. (Homeless: health drops 0.2/s. Shelter stops that and regenerates health.)
- [x] Under good conditions (enough food, housing with capacity), new settlers are born at a sensible pace. (Headless: population rose 5 → 7 in the first seconds, one birth per house per 45 s, needs 2 residents, room, and 10+ food.)
- [x] Under bad conditions (starvation, no shelter), settlers die and are cleanly removed from all systems (jobs, houses, needs tracking). (Headless: death at health 0 → population 7 → 6, freed, job and house cleared.)
- [x] A running population count is accurate after any birth/death event. (`SettlerManager.population()` and `population_changed(count)`.)

## Decisions
- House: `resources/buildings/house.tres`, 2x2, 15 wood, 6 s build, capacity 4. Shown in the build list after the barn.
- Home assignment is automatic. `SettlerManager` gives each homeless settler the house with the fewest residents that still has room. Spreading out this way keeps houses eligible for births.
- Rest: a settler whose rest drops to 25 calls home and rests until 95. At home rest recovers 4/s. Job work pauses while resting. Rest drains 0.25/s otherwise.
- Shelter: `Needs.sheltered` is true with a home. Homeless exposure drains health at 0.2/s.
- Births: each house with 2 or more residents, room, and no cooldown spawns one settler every 45 s if the stockpile holds at least 10 food.
- Death: `Needs.died` (health 0, from starvation or exposure) unassigns the job and the home and frees the settler. `population_changed` fires after any birth or death.
- Population count is data only. The display belongs to 0012.
- Starting population is 5 homeless settlers. Houses fill from there.

## Open questions
- Automatic vs. manual house assignment on birth — decided: automatic, fewest-residents-first (see decisions).
- Exact birth conditions/cooldown and death thresholds — placeholder values, tune after the loop is playable.
