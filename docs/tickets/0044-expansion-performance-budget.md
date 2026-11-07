# 0044 — Expansion scale & measured performance budget

- **Status:** ready
- **Milestone:** [M17 — Replayable Starts & Expansion](../roadmap.md#m17--replayable-starts--expansion)
- **Depends on:** 0036, 0043

## Goal
Fix measurable default/large-town scale targets before final release integration.

## Context
The original world is 64x64. New services, pathfinding, markets, and individual livestock add work; headless simulation speed alone cannot establish rendered performance.

## Scope
- Build repeatable standard/large fixtures with multiple districts, bridges, markets, schools, trading, orchards, and pastures through valid construction/setup rules.
- Set and document supported population/map-size targets and numeric frame/simulation budgets on named hardware at normal and fastest game speeds.
- Measure rendered frame times, headless simulation costs, path requests, and growth in node/memory counts over a sustained run; record commands, fixtures, duration, and percentiles.
- Fix measured scaling bottlenecks without changing physical inventory or survival semantics; retain correctness checks for optimized paths.
- Add repeatable budget/regression reporting for 0049; distinguish test-fixture setup shortcuts from claimed survival evidence.

## Out of scope
- Engine migration, arbitrary unlimited populations, and unmeasured broad rewrites.

## Acceptance criteria
- [ ] Standard and large fixtures have explicit dimensions/populations and numeric supported performance targets.
- [ ] Reproducible windowed/headless measurements meet those targets on documented hardware.
- [ ] Sustained runs show no unbounded task/node growth, script errors, or permanently stuck settlers.
- [ ] Any optimization preserves accounting, bridge routing, and service behavior in focused regressions.
- [ ] Targets and commands are recorded for the v3 release gate, not postponed until it.

## Open questions
- None; select and record realistic numeric budgets before optimization, revisiting them only with explicit measured justification.
