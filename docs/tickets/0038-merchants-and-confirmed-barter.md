# 0038 — Merchant visits & confirmed barter

- **Status:** ready
- **Milestone:** [M15 — Trading Post & Merchant Visits](../roadmap.md#m15--trading-post--merchant-visits)
- **Depends on:** 0037

## Goal
Let players exchange real stocked goods during predictable merchant visits, without requiring trade for basic survival.

## Context
Use barter values, not currency. Orchard seeds and sheep are unlock purchases for 0039–0040; explain their future use rather than pretending those chains already exist.

## Scope
- Schedule seeded merchant arrivals/departures at accessible posts, with finite offers and visible visit timing; inaccessible posts defer visits rather than teleporting merchants.
- Add offer selection, quantity/value/capacity validation, and explicit confirmation. Revalidate at confirmation and apply all-or-nothing exchange to reserved trade stock.
- Offer existing goods plus one orchard seed entitlement and sheep breeding-stock purchases. Store pending unlocks/animals separately from ordinary edible goods until 0039–0040 can place them.
- Show reserve warnings when players alter export targets; never automatically barter or spend household/market stock.
- Persist merchant identity, offers, schedule/random state, pending purchases, and visit progress; record import/export history exactly once.

## Out of scope
- Currency, auto-trade, multiple fruit/sheep breeds, and compulsory imported food.
- Orchard and pasture simulation (0039–0040).

## Acceptance criteria
- [ ] A reachable post receives and loses a scheduled visitor; disconnected access has defined non-destructive behavior.
- [ ] Confirmed barter conserves quantities and respects values, capacity, reserves, and finite merchant stock.
- [ ] Rejected, cancelled, and repeated confirmation cannot partially apply or duplicate an exchange.
- [ ] Saving during a visit restores identical offers/timing/purchases and permits one valid exchange after loading.
- [ ] A no-trade starter scenario remains viable; interactive confirmation UI and headless checks are verified.

## Open questions
- None; document initial barter values, cadence, and visit duration in the balance tables.
