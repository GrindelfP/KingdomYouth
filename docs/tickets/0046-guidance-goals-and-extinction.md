# 0046 — First-winter guidance, settlement goals & extinction

- **Status:** ready
- **Milestone:** [M18 — Settlement Identity, Guidance & Presentation](../roadmap.md#m18--settlement-identity-guidance--presentation)
- **Depends on:** 0045

## Goal
Help a new player survive and plan beyond the first winter without turning open-ended settlement into a forced victory sequence.

## Context
Objectives observe real simulation state; they do not reward free supplies or override indirect control. Ordinary shortages remain the survival challenge.

## Scope
- Add optional, dismissible first-winter guidance for completed housing, staffed food/fuel production, actual household reserves, and seasonal readiness; link steps to relevant UI.
- Add optional long-term goals for successor generations, education, surplus trade, and established orchard/flock chains, with documented measurable predicates.
- Evaluate progress from actual state, handling demolition, shortages, and save/load rather than trusting a build-button click. Historical achievements remain distinct from current readiness.
- Detect zero living settlers and present clear extinction feedback with load/restart choices; restarting asks before discarding the current world.
- Preserve open-ended play after goals; persist completion/dismissal and integrate event history.

## Out of scope
- Free rewards, combat, scripted disasters, mandatory victory endings, and automatic building placement.

## Acceptance criteria
- [ ] A new-player playtest follows guidance to diagnose and address first-winter needs without logs.
- [ ] Empty/unfinished buildings and goods only promised in transit cannot falsely satisfy stock/readiness steps.
- [ ] Long-term goals recognize real graduates, successor adults, trades, and established production chains.
- [ ] Extinction offers working load/restart controls; completed goals do not end the simulation.
- [ ] Progress survives loading without duplicate events; headless predicate checks and interactive flow pass.

## Open questions
- None; document exact goal thresholds with the shipped tutorial.
