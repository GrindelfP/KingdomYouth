# 0027 — Integration, balance pass & docs for v0.2

- **Status:** ready
- **Milestone:** M10 — v0.2 Release
- **Depends on:** 0014–0026

## Goal
Make v0.2 a coherent, playable whole: everything saves and loads, a reasonable player survives the first winters, and the docs describe the new game.

## Context
Tickets 0014–0026 each change core systems; this ticket checks they work together and tunes the numbers.

## Scope
- Save/load: one end-to-end round-trip covering storage, sites, professions, trees, roads, fields, households, families, tools, calendar. Saves from older versions are rejected with a toast.
- Automated soak run: a throwaway headless script that starts a new game, builds a sensible starter town programmatically (houses, gatherer, forester, woodcutter, fields, storage), runs at high time scale for 3 game years, and prints population, food, firewood per season. Fix crashes, stuck settlers, and leaks it reveals. Do not commit the script unless it is useful as a repeatable check (if kept, put it under `tools/`).
- Balance: tune costs, yields, consumption so that the starter town survives the first winter only with some planning, and unplanned play (no firewood, no food buildings) fails within ~2 years. Record final numbers in a table in `docs/balance.md`.
- Docs: update `docs/tutorial.md` (new loop, professions, storage, seasons, speed keys), `README.md` features/controls, and `docs/roadmap.md` status.

## Out of scope
- New features.

## Acceptance criteria
- [ ] Soak run completes 3 years with no script errors.
- [ ] Save/load round-trip verified across two processes.
- [ ] `docs/balance.md`, tutorial and README updated.

## Open questions
- None.
