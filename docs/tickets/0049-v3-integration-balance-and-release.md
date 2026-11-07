# 0049 — v3 integration, balance & release gate

- **Status:** ready
- **Milestone:** [M19 — v3 Integration & Release Gate](../roadmap.md#m19--v3-integration--release-gate)
- **Depends on:** 0028–0048

## Goal
Ship a coherent v3 whose multigenerational survival, shortages, persistence, and supported scale have repeatable evidence.

## Context
The baseline remains v0.2 until all v3 gates pass. Extend existing soak/round-trip tools and preserve physical goods, seasons-only survival, and open-ended play; fires, disease outbreaks, and disaster settings/scenarios are not part of this release.

## Scope
- Extend the planned-town scenario to 30 years with affordable construction/housing growth, staffing, and actual markets, education, barter, orchards, sheep/clothing, and community services.
- Report successive generations, births/deaths, food/fuel/tools/clothing, production/consumption, service capacity, and stuck-travel checks. Record deterministic seeds and bounded planner interventions.
- Add recoverable food/fuel shortage scenarios with actionable warnings and measured recovery after restoring real supply. Keep no-food/no-fuel controls that fail for understandable survival reasons.
- Run 0048 two-process persistence checks and 0044 standard/large performance fixtures against their fixed budgets; fix measured integration failures and rerun.
- Perform an interactive playtest of new-game settings, placements/bridges, market fallback, trade confirmation, warnings, pause/inspect, goals, extinction, and volume controls.
- Update `README.md`, `docs/tutorial.md`, `docs/balance.md`, roadmap/ticket status, and commands to describe only the shipped behavior. Mark v3 implemented only after every associated ticket is done.

## Out of scope
- New chains, additional crops/animals, disasters, engine changes, and declaring success from manual confidence alone.

## Acceptance criteria
- [ ] The documented 30-year planned town sustains successive adult generations and exercises all listed chains without script errors, duplicated inventory, or permanent pathing stalls.
- [ ] Shortage/recovery and no-food/no-fuel outcomes match documented causes; no scenario grants emergency free goods.
- [ ] Full two-process round-trips and invalid-save checks pass with the finalized compatibility policy.
- [ ] Default/large results meet the numeric targets fixed in 0044 on documented hardware.
- [ ] Interactive checks are recorded with remaining limitations; docs and completed ticket statuses accurately describe v3 before its roadmap status changes.

## Open questions
- None; balance changes must be measured against the 0030 baseline and recorded with rerun results.
