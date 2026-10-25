# 0007 — Settler needs system (hunger, rest, warmth)

- **Status:** done
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
- [x] Each settler's hunger rises over time and decreases when they eat. (+0.7/s; a meal at hunger 60+ restores 60.)
- [x] Eating consumes from the global food stockpile (0004); if the stockpile is empty, the settler cannot reduce hunger and the game should make this visibly consequential (e.g. eventually triggers the starvation state). (Empty stock: hunger caps at 100, `starving` fires, health drains at 1/s.)
- [x] A defined, observable consequence exists for hunger reaching its maximum (at minimum: a signal other systems — including 0010's death logic — can listen to). (`starving` once on reaching 100, then health drain; `died` when health reaches 0.)
- [x] Needs updates are batched/ticked, not naively running full logic every physics frame for every settler. (`TICK_INTERVAL` = 1 s; `ticked` signal fires per tick.)

## Decisions
- `Needs` is a child `Node` of each `Settler` (`scripts/entities/needs.gd`). It ticks once per second from `_process` accumulation.
- Fields: `hunger` 0 to 100 (rises), `rest` 0 to 100 (drains awake, recovers while `at_home`), `warmth` (tracked, not enforced until 0011), `health` 0 to 100.
- Eating is instant and autonomous when `hunger >= 60` and food is in stock. It costs one food and restores 60. No walking, per the ticket.
- Interruption signal: `hunger_critical` fires when hunger reaches 85 (0008 uses `is_critical()` to pause work).
- Starvation at hunger 100: `starving` fires once, health drains 1/s. Health regenerates 0.5/s when sheltered and not starving.
- Homelessness (`sheltered = false`) drains health at 0.2/s. Housing (0010) sets `sheltered` and `at_home`.
- `died` fires once when health reaches 0. 0010 removes the settler from the world.

## Open questions
- Exact numeric rates (how fast hunger rises, how much one "eat" action restores) — pick placeholder values and tune by playtesting once the loop exists; not worth debating in the abstract.
- Whether rest/warmth are fully implemented here or stubbed until 0010/0011 land — recommend implementing hunger fully in this ticket, and stubbing rest/warmth as tracked-but-not-yet-enforced fields so 0010/0011 can wire in consequences without re-architecting the `Needs` component.
