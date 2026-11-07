# 0042 — Map seeds, climates & validated starts

- **Status:** ready
- **Milestone:** [M17 — Replayable Starts & Expansion](../roadmap.md#m17--replayable-starts--expansion)
- **Depends on:** 0041

## Goal
Expose reproducible map choices and climate/supply difficulty without hiding production cheats.

## Context
Seeded terrain generation already exists. Preserve the current default start as a regression fixture and validate water access required by 0037.

## Scope
- Add new-game controls for seed, mild/harsh climate, and standard/large map sizes; show effective settings before confirming a restart.
- Keep the current standard size/default seed available. Document chosen large dimensions and climate-driven winter/starting-supply differences; keep production recipes/rates identical between presets.
- Validate spawn/buildable land, initial storage access, forest, rock, and shoreline connected to edge water. Deterministically retry/reject unusable seeds/settings with clear feedback, not a hung generator.
- Persist actual generated terrain, seed, dimensions, and settings; loading uses saved terrain, not regeneration from a newer algorithm.
- Add a documented fixed seed set per preset and reproducibility/start-access checks; adapt camera/world bounds and art to map size.

## Out of scope
- Disaster settings/scenarios, new biomes, hidden yield multipliers, and a terrain engine rewrite.
- Bridges and measured expansion performance (0043–0044).

## Acceptance criteria
- [ ] Identical seed/settings produce identical terrain and validated starting resources/access.
- [ ] Every documented seed/preset passes bounded generation and starting-access checks.
- [ ] Mild/harsh differences match documented climate/supply values without changing production yields.
- [ ] Default regression start remains selectable; large-world camera/placement bounds are correct.
- [ ] Save/load restores exact terrain/settings; new-game UI and headless checks pass.

## Open questions
- None; fix large dimensions and preset numbers during implementation, before 0044 performance measurement.
