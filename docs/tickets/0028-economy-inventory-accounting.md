# 0028 — Town-wide inventory accounting

- **Status:** ready
- **Milestone:** [M11 — Readable Economy & Long-Run Baseline](../roadmap.md#m11--readable-economy--long-run-baseline)
- **Depends on:** 0027

## Goal
Make food and fuel totals trustworthy without confusing available storage with goods already committed to homes or work.

## Context
The v0.2 HUD counts storage only; households, workplace buffers, construction deliveries, and carried goods are separate inventories. Extend the existing `Inventory` and `ResourceStockpile` model rather than replacing physical goods with counters.

## Scope
- Add a read-only accounting view with disjoint locations: general storage, households, workplace inputs/outputs, construction deliveries, and transit. Future markets and trade stores must be separately registered locations.
- Show food and firewood breakdowns and town-wide totals in the HUD/detail panel; distinguish available stock from committed goods.
- Count carried goods once, not again through a source reservation or destination claim. Equipment already worn and consumed construction materials are not inventory stock.
- Keep existing storage withdrawal APIs storage-only; town totals must not make remote or household goods spendable.
- Add repeatable transfer checks for pickup, delivery, partial acceptance, cancellation, demolition, and save/load. Explain intentional consumption and existing overflow loss separately from transfers.

## Out of scope
- Production/consumption history and warnings (0029).
- Markets and production targets (0031–0032).

## Acceptance criteria
- [ ] An independently summed fixture matches every location subtotal and town total for food and fuel.
- [ ] Moving goods between storage, home, workplace, and settler preserves totals until actual consumption or documented loss.
- [ ] Failed/partial deliveries, cancellation, and load do not double count goods or reservations.
- [ ] HUD labels distinguish stored, household, transit, and total amounts without enabling global withdrawal.
- [ ] Headless checks run without script errors; UI layout is reviewed in a windowed run.

## Open questions
- None.
