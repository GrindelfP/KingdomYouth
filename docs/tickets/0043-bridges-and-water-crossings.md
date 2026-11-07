# 0043 — Constructed bridges & water crossings

- **Status:** ready
- **Milestone:** [M17 — Replayable Starts & Expansion](../roadmap.md#m17--replayable-starts--expansion)
- **Depends on:** 0042

## Goal
Allow expansion across water through costed construction and valid settler paths.

## Context
Water is normally unwalkable; roads do not cross it. A bridge must integrate construction delivery, occupancy, path invalidation, and merchant water approaches rather than simply marking all water walkable.

## Scope
- Add straight bridge placement between valid banks with preview, span limits, per-tile material/work costs, and rejection reasons.
- Deliver materials/work from a reachable bank; incomplete spans are not passable. Completed spans connect land paths and use distinct generated seasonal art.
- Preserve navigable water beneath bridges for merchant approach connectivity; occupied bridge deck tiles cannot also hold buildings or ordinary roads.
- Define safe removal: block demolition while any settler occupies or is committed to crossing the span; otherwise cancel/replan future routes and warn if removal disconnects a district.
- Persist bridge/site state, register path changes, and test interrupted construction and access loss without free completion.

## Out of scope
- Tunnels, curved/multilevel bridges, boat simulation, and instant/free crossings.

## Acceptance criteria
- [ ] Valid spans require delivered materials and builder work; invalid/unfinished spans cannot be walked across.
- [ ] Completed bridges enable paths across water while preserving merchant approach validity.
- [ ] Removal guard prevents occupied crossings from leaving settlers on unwalkable water; queued routes replan safely.
- [ ] Mid-construction and completed-span round-trips restore costs, occupancy, and paths consistently.
- [ ] Art/preview is reviewed; repeated construct/remove/path checks run without errors or stuck travellers.

## Open questions
- None; document span limits, costs, and removal guard feedback.
