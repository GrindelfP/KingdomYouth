# 0010 — Housing & population growth/death

- **Status:** ready
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
- [ ] Houses can be built and have a defined capacity; settlers can be assigned to them.
- [ ] A settler without adequate shelter suffers a defined, observable consequence over time.
- [ ] Under good conditions (enough food, housing with capacity), new settlers are born at a sensible pace.
- [ ] Under bad conditions (starvation, no shelter), settlers die and are cleanly removed from all systems (jobs, houses, needs tracking).
- [ ] A running population count is accurate after any birth/death event.

## Open questions
- Automatic vs. manual house assignment on birth — recommend automatic (assign to the house with spare capacity nearest to... anything reasonable) to avoid forcing player micromanagement for every newborn in the MVP.
- Exact birth conditions/cooldown and death thresholds — placeholder values, tune after the loop is playable.
