# 0037 — Shoreline trading post & reserved inventory

- **Status:** ready
- **Milestone:** [M15 — Trading Post & Merchant Visits](../roadmap.md#m15--trading-post--merchant-visits)
- **Depends on:** 0032, 0034

## Goal
Build and physically stock a trading post without exposing household reserves to accidental export.

## Context
Trading needs a shoreline with a connected water approach, not just any isolated water tile. Reuse real construction, professions, `Inventory`, and reserve-budget rules.

## Scope
- Define a merchant approach as a connected water path from a map-edge water cell to the post frontage; preview valid shore orientation, land access, and reasons for rejection.
- Add trading post construction, trader profession, finite trade inventory, and per-good requested stock controls.
- Traders physically move eligible surplus from general storage into reserved trade stock, respecting 0032 reserves and in-flight commitments across multiple posts.
- Provide explicit release-to-storage controls; household use and ordinary producers cannot withdraw reserved trade goods.
- Integrate accounting/history locations, claim cleanup, idle reasons, generated seasonal art, and persistence. Expose post access/inventory APIs for merchant visits.

## Out of scope
- Merchant arrivals and exchange UI (0038).
- Free goods, currency, boats controlled by the player, and bridge construction (0043).

## Acceptance criteria
- [ ] Connected shore placement succeeds; inland, isolated-water, and blocked-access placements explain rejection.
- [ ] Two posts cannot collectively withdraw below a protected reserve through overlapping claims.
- [ ] Stocking/releasing is physical, capacity-limited, and conserves goods through full storage or path failure.
- [ ] Demolition and mid-trip load release/revalidate claims without making trade stock available twice.
- [ ] Art/UI is reviewed and focused headless placement/logistics checks pass.

## Open questions
- None; validate the default seed's approach and document the frontage rule before finalizing placement costs.
