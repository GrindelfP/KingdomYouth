# 0007 — Settler needs system (hunger, rest, warmth)

- **Status:** ready
- **Milestone:** M2 — Core Simulation Loop
- **Depends on:** 0006, 0004

## Goal
Each settler has needs that drain over time and must be satisfied by the settlement's resources/buildings, creating the central survival pressure of the game.

## Context
This is what makes the settlement a system to manage rather than a diorama. For MVP, keep the need set minimal and legible: hunger (needs food from the stockpile), rest (needs to be inside a house periodically), warmth (needs shelter/fuel, especially tied into the season cycle in 0011). Health and happiness (full Banished-style) are deferred.

## Scope
- A `Needs` component/script attached to each settler tracking at least: `hunger` (0–100, rises over time, settler eats from stockpile via 0004 to reduce it), `rest`/`energy` (drains over time awake, settler must return to an assigned house to recover — depends on 0010 for housing, so this ticket can stub "recovers when idle at home" with a placeholder home reference if 0010 isn't ready yet).
- Consequence of unmet needs: if `hunger` maxes out, define what happens (health damage over time, eventually death — death itself may be finalized in 0010, but this ticket should define the hunger-exceeded signal/state).
- Settlers autonomously seek to satisfy critical needs: when hunger crosses a threshold, the settler should interrupt current work and go eat (consume from stockpile directly, or walk to a food-related building — pick the simpler option for MVP: direct stockpile consumption without needing to walk anywhere, since food is abstracted as a global pool per 0004).
- Needs tick on a reasonable interval (not necessarily every frame) to keep this cheap at scale.

## Out of scope
- Happiness/morale system.
- Health/disease modeling beyond a simple consequence-of-starvation state.
- Per-settler food preferences.

## Acceptance criteria
- [ ] Each settler's hunger rises over time and decreases when they eat.
- [ ] Eating consumes from the global food stockpile (0004); if the stockpile is empty, the settler cannot reduce hunger and the game should make this visibly consequential (e.g. eventually triggers the starvation state).
- [ ] A defined, observable consequence exists for hunger reaching its maximum (at minimum: a signal other systems — including 0010's death logic — can listen to).
- [ ] Needs updates are batched/ticked, not naively running full logic every physics frame for every settler.

## Open questions
- Exact numeric rates (how fast hunger rises, how much one "eat" action restores) — pick placeholder values and tune by playtesting once the loop exists; not worth debating in the abstract.
- Whether rest/warmth are fully implemented here or stubbed until 0010/0011 land — recommend implementing hunger fully in this ticket, and stubbing rest/warmth as tracked-but-not-yet-enforced fields so 0010/0011 can wire in consequences without re-architecting the `Needs` component.
