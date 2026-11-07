# 0040 — Pastures & sheep husbandry

- **Status:** ready
- **Milestone:** [M16 — Orchards & Pastures](../roadmap.md#m16--orchards--pastures)
- **Depends on:** 0039

## Goal
Turn purchased sheep into a managed flock with real land, workforce, and breeding constraints.

## Context
Merchant purchases are pending breeding stock, not stored meat. Animals must have their own identity/state and cannot be counted as edible inventory or copied between pastures.

## Scope
- Add fenced pasture size presets, herder profession, capacity by area, and confirmed transfer of pending merchant sheep into completed reachable pasture space.
- Track animal identity, sex, age, breeding progress, and flock membership; require a mature breeding pair and free capacity for reproduction.
- Add target flock size and explicit slaughter controls, preserving a breeding pair by default. Overriding protection requires a visible confirmation.
- Workers shear mature sheep into wool and slaughter selected sheep into meat output; both require work and hauling, with finite output buffers and production limits.
- Show flock/capacity/breeding/protection state, generated sheep/fence/seasonal art, and deterministic save/load. Block demolition of occupied pastures until animals are transferred or explicitly slaughtered.

## Out of scope
- Animal disease, predators, escaping animals, cattle/chickens, and wool clothing recipes (0041).

## Acceptance criteria
- [ ] Purchased sheep move once into valid capacity; rejected placement keeps pending stock intact.
- [ ] A pair breeds over time without exceeding capacity, including through mid-breeding loading.
- [ ] Ordinary target management preserves breeding stock; explicit override cannot silently delete animals.
- [ ] Shearing/slaughter creates measurable wool/meat only through work and physical delivery.
- [ ] Animal transfer/removal and save/load conserve identities; art/UI and headless checks pass.

## Open questions
- None; document capacity, breeding/shearing intervals, maturity, and yields.
