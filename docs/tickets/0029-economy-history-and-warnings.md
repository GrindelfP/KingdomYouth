# 0029 — Seasonal economy history & shortage feedback

- **Status:** ready
- **Milestone:** [M11 — Readable Economy & Long-Run Baseline](../roadmap.md#m11--readable-economy--long-run-baseline)
- **Depends on:** 0028

## Goal
Let players explain shortages and idle workplaces from the UI rather than logs.

## Context
Transfers are not production or consumption. Seasonal records must follow actual creation/use of goods, while idle reasons come from current simulation state.

## Scope
- Record per-good seasonal production, consumption, imports/exports hooks, and explicit loss; retain the latest 20 years with current-season progress.
- Add an economy detail panel showing history beside 0028 inventory breakdowns.
- Expose workplace reasons for no workers, no input, no reachable work/destination, full storage, and off-season work; distinguish intentional pauses and later production limits.
- Add deduplicated food/fuel shortage warnings with affected homes and useful navigation. Document configurable thresholds; shortages must not create goods.
- Persist history and warning state; loading and pausing must not repeat consumption or flood toasts.

## Out of scope
- Full town overview/event archive (0045).
- New survival pressures or automated player decisions.

## Acceptance criteria
- [ ] A controlled season's creation, use, and transfers produce correct separate history entries.
- [ ] Each listed idle condition can be reproduced and explained in its workplace panel.
- [ ] Empty household reserves trigger actionable warnings even when distant storage contains food/fuel.
- [ ] History survives a round-trip and warnings remain inspectable while paused.
- [ ] Headless checks are error-free; the panel and alerts are reviewed at 1280x720.

## Open questions
- None; tune and document warning thresholds during implementation.
