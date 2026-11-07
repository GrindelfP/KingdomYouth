# 0032 — Production limits & reserve targets

- **Status:** ready
- **Milestone:** [M12 — Markets, Reserves & Production Limits](../roadmap.md#m12--markets-reserves--production-limits)
- **Depends on:** 0031

## Goal
Let players maintain seasonal stocks without manually switching workshops on and off.

## Context
Use 0028 accounting and existing job planning. Targets guide real work and must never create goods or turn committed household stock into exportable surplus.

## Scope
- Add town-wide per-good production ceilings and reserve targets with unlimited/default settings and validated non-negative integer input.
- Document counts used: production ceilings include all loose inventories/transit for that good; reserve protection uses reachable general-storage stock and excludes homes, market commitments, and trade stock.
- Stop starting new production batches at the ceiling; allow already-started batches to finish and document bounded overshoot. Resume below the limit, without blocking delivery or survival tasks.
- Show actual/target values and intentional limit-idle reasons; reserve targets warn and expose an export-budget API for 0037–0038, not unbounded forced production.
- Persist settings and test multiple producers, full storage, goods in transit, and output changes used by later chains.

## Out of scope
- Automatic trade, global priority scheduling, and stock teleportation.
- Forced immediate cancellation of in-progress work.

## Acceptance criteria
- [ ] Two producers stop and resume around a shared ceiling with only documented in-progress overshoot.
- [ ] Goods in transit or households do not disappear from ceiling accounting.
- [ ] Lowering a limit cannot strand carried goods or prevent eating/heating.
- [ ] Export-budget checks cannot count protected/committed goods as available surplus.
- [ ] UI settings and resulting work behavior survive loading; focused headless checks are error-free.

## Open questions
- None.
