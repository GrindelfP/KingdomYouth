# 0012 — HUD & UI (resource bar, building menu, settler info panel)

- **Status:** ready
- **Milestone:** M4 — UI/UX Layer
- **Depends on:** 0004, 0005, 0008, 0010, 0011

## Goal
Everything the simulation already does becomes visible and controllable through real UI, replacing the debug-level interactions assumed by earlier tickets.

## Context
Tickets 0004–0011 build the simulation with minimal/stub interaction points (e.g. "a debug way to assign jobs"). This ticket is where the player-facing experience is actually built, using Godot's `Control` node UI system.

## Scope
- **Resource bar**: always-visible display of current stockpile amounts (0004), updating live via the `resource_changed` signal.
- **Time/season indicator**: current day/season from 0011.
- **Population indicator**: current population count from 0010, ideally with an at-a-glance breakdown (e.g. employed/idle) if cheap to add.
- **Building menu**: replaces 0005's placeholder list — a proper panel/grid of buildable `BuildingDef`s showing cost, with click-to-enter-placement-mode.
- **Job assignment UI**: replaces 0008's debug interaction — clicking a building shows its job slots and lets the player assign/unassign settlers from a list of available ones.
- **Settler info panel**: clicking a settler shows their current job, needs (hunger/rest/warmth), and home assignment.
- Basic feedback/notifications for important events (e.g. "a settler has died," "a new settler was born," "construction complete") — a simple toast/log list is enough for MVP.

## Out of scope
- Settings/options menus, main menu, pause menu (not needed to validate the core loop — add once the loop is fun).
- Localization (project is English-only per `CLAUDE.md`).
- Visual polish/theming beyond "clear and usable."

## Acceptance criteria
- [ ] Resource bar, time/season indicator, and population count are all visible and update live without manual refresh.
- [ ] Player can place any defined building through the building menu (no debug shortcuts needed).
- [ ] Player can assign/unassign settlers to jobs entirely through UI.
- [ ] Clicking a settler shows an info panel with their current state.
- [ ] Key events (birth, death, construction complete) produce visible in-game feedback.

## Open questions
- Exact visual layout/theme — low priority for MVP; function over form, revisit once the loop is validated.
