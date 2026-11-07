# 0033 — Leather, tailor & wearable coats

- **Status:** ready
- **Milestone:** [M13 — Clothing & Food Diversity](../roadmap.md#m13--clothing--food-diversity)
- **Depends on:** 0032

## Goal
Add a physical clothing chain that improves winter exposure without replacing heated homes.

## Context
Hunters already produce meat, tools already wear during work, and warmth already drives winter survival. Extend these systems rather than adding a separate crisis mechanic.

## Scope
- Add leather as a hunting by-product and a clothing resource category accepted by appropriate storage/markets.
- Add a constructible tailor, profession, and leather-to-coat recipe with physically fetched inputs/output hauling and production-limit support.
- Settlers fetch one coat from reachable supply, equip it, wear it over time, and seek a replacement after it breaks; no duplication when fetching is interrupted.
- Apply a documented bounded reduction to outdoor winter warmth loss. Homes still need firewood, and v0.2 first-winter survival remains possible without a tailor.
- Show coat type/condition and town clothing coverage; include generated good/building art, icons, history, and saved equipment/wear.

## Out of scope
- Wool coats (0041), armor, infectious illness, and weather disasters.

## Acceptance criteria
- [ ] Hunting produces real leather that is hauled, consumed by a tailor, and turned into stored coats.
- [ ] Acquisition, full wear-out, replacement, interruption, and mid-trip loading conserve inventory/equipment.
- [ ] Paired winter tests demonstrate a measured coat benefit while unheated homes remain unsafe.
- [ ] A documented starter scenario survives its first winter without clothing production.
- [ ] Save/load and error-free headless checks cover wear; art/UI is reviewed.

## Open questions
- None; record costs, recipe yields, wear lifetime, and warmth modifiers in `docs/balance.md`.
