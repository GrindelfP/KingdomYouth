# 0012 — HUD & UI (resource bar, building menu, settler info panel)

- **Status:** done
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
- [x] Resource bar, time/season indicator, and population count are all visible and update live without manual refresh. (Resources via `resource_changed`; time and population refreshed each frame.)
- [x] Player can place any defined building through the building menu (no debug shortcuts needed). (Headless click-through test: menu → placement → built lodge.)
- [x] Player can assign/unassign settlers to jobs entirely through UI. (Building panel: Assign and Remove buttons.)
- [x] Clicking a settler shows an info panel with their current state. (Job, state, home, and need bars.)
- [x] Key events (birth, death, construction complete) produce visible in-game feedback. (Toasts for births, deaths, completed buildings, and season changes.)

## Decisions
- The HUD is one `CanvasLayer` (`scripts/ui/hud.gd`, the `UI` node). It builds its controls in code. Panels are `scripts/ui/building_menu.gd` and `scripts/ui/info_panel.gd`.
- Top bar: resources, population with working count, and day and season. A hint line sits under it and shows placement feedback.
- Build menu: one button per `building_defs` entry, showing cost. A click enters placement mode.
- Info panel: shows a building's workers, with Assign and Remove, or a settler's job, home, and needs, with Unassign. The panel rebuilds every 0.5 s and when the selection changes.
- Selection replaces the old debug interaction. Clicking a settler or a building selects it. Clicking empty ground or pressing Esc clears it. The `U` key shortcut is gone.
- Toasts show for 6 s, with at most 5 on screen.
- Controllers emit signals (`hint_changed`, `construction_completed`, `settler_born`, `settler_died`, `selection_changed`) so the HUD never writes to controller state.
- Settlers have stable numbers (`display_id`) shown in the UI.
- Visual check: the layout was captured with a windowed run. Theme is default.

## Open questions
- Exact visual layout/theme — low priority for MVP; function over form, revisit once the loop is validated.
