# 0031 — Market & vendor logistics

- **Status:** ready
- **Milestone:** [M12 — Markets, Reserves & Production Limits](../roadmap.md#m12--markets-reserves--production-limits)
- **Depends on:** 0030

## Goal
Give nearby households a staffed local supply point while preserving physical hauling and direct-restocking fallback.

## Context
Reuse household inventories, `Hauler`, profession counts, construction, and storage filters. A market is not a second global stockpile or a teleporting service.

## Scope
- Add a constructible market, vendor profession, finite mixed-goods inventory, coverage overlay, and desired staffing controls.
- Vendors carry food/firewood from reachable general storage into the market; covered residents collect household goods there, falling back to reachable storage when goods are absent. Uncovered homes retain direct restocking.
- Use per-good stocking targets within capacity; avoid vendors repeatedly collecting from other markets or trade inventories.
- Release/revalidate claims on reassignment, demolition, path loss, death, and loading. Preserve carried goods through partial/failed delivery.
- Integrate location accounting/history, idle feedback, generated seasonal art, build menu, and save/load.

## Out of scope
- Town-wide production limits/reserve policy (0032).
- Automatic delivery straight into every house or new household needs.

## Acceptance criteria
- [ ] Staffed coverage measurably changes household travel compared with uncovered homes in a controlled layout.
- [ ] Empty, unstaffed, full, and disconnected markets do not deadlock vendors or prevent reachable fallback restocking.
- [ ] Transfers conserve goods; markets are not counted again as general storage.
- [ ] Demolition/reassignment and a mid-trip round-trip preserve goods and valid task state.
- [ ] New art/UI is reviewed; headless logistics checks are error-free.

## Open questions
- None; document initial footprint, costs, capacity, radius, and stocking targets in the balance tables.
