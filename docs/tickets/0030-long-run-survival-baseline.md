# 0030 — Twenty-year survival & demographic baseline

- **Status:** in-progress
- **Milestone:** [M11 — Readable Economy & Long-Run Baseline](../roadmap.md#m11--readable-economy--long-run-baseline)
- **Depends on:** 0028, 0029

## Goal
Establish a repeatable long-run baseline before adding v3 economic pressures.

## Context
The current three-year soak does not establish generational replacement. Extend `tools/soak/` and its planner; do not substitute instant buildings, free recurring goods, or an unrelated test harness for the real labor loop.

## Scope
- Extend the planned-town scenario to 20 years with recorded random seeds, affordable construction, staffing, and housing expansion rules.
- Report seasonal children/adults/elders, workforce, births/deaths by cause, food/fuel location totals, and tools.
- Detect permanently stalled travel separately from legitimate off-season/target-limited idle work.
- Retain no-food/no-fuel controls and document baseline outcomes, including survival failures, in `docs/balance.md`.
- Fix baseline crashes, accounting defects, pathing deadlocks, and demographic blockers revealed by the run before later milestones proceed. Keep balance changes explicit and measured.

## Out of scope
- New production chains and services.
- Claiming 20 years proves the final 30-year release gate (0049).

## Acceptance criteria
- [x] The documented command reproduces a 20-year run with seed and seasonal demographic/economy output.
- [x] The planned town demonstrates children entering work and forming successor households; any survival blockers are resolved and rerun.
- [x] No script errors, unexplained inventory changes, or permanently stuck settlers remain.
- [x] No-food/no-fuel controls still fail for observable hunger/cold reasons.
- [x] Baseline balance, planner rules, limitations, and results are recorded.

Implementation and headless verification are complete on the development branch; status remains `in-progress` until merged, per the ticket lifecycle. See [measured results, resolved failures, and limitations](../balance.md#m11-twenty-year-baseline-ticket-0030). Seeds 1/2/3 survive twenty years without deaths; the controls die of hunger/cold. No game balance constants changed. This is not the 30-year release gate.

## Open questions
- None; adjust affordable planner rules and measured balance rather than masking failures.
