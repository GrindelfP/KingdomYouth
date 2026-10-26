# KingdomYouth — Roadmap

Vision: a Banished-like settlement builder. The player never controls settlers directly — they place buildings, assign jobs, and manage a stockpile, and the settlers act on their own needs and assigned work. Core tension: balance population growth against food, warmth, and shelter through changing seasons.

**Art/technical direction (decided 2026-10-25):** 2D, top-down, tile-grid based. TileMap for terrain, AStar2D/TileMap-native pathfinding for settlers, orthogonal camera with pan/zoom. This is assumed throughout the tickets below.

This roadmap breaks the project into milestones. Milestones M0–M4 are the minimum playable loop (place a few buildings, keep settlers fed and housed, watch the population survive a year). Everything under "Later / stretch" is explicitly out of scope until the core loop works end to end.

## M0 — Project & Tooling Setup
Godot project exists, runs, and is under source control with a sane folder structure.
- 0001 — Project scaffolding & Godot project setup

## M1 — World Foundation
A renderable world the camera can look at and the player can navigate.
- 0002 — World grid & terrain rendering
- 0003 — Camera & input controls

## M2 — Core Simulation Loop
The heart of the game: resources, buildings, settlers, needs, jobs. This is the largest milestone.
- 0004 — Global resource stockpile system
- 0005 — Building placement & construction system
- 0006 — Settler entity: movement & pathfinding
- 0007 — Settler needs system (hunger, rest, warmth)
- 0008 — Job & task assignment system
- 0009 — Core production buildings (woodcutter's lodge, storage barn, farm)

## M3 — Population & Time
The world is alive over time, not a static sandbox.
- 0010 — Housing & population growth/death
- 0011 — Day/night & season cycle

## M4 — UI/UX Layer
The player can actually see and control the above without reading logs.
- 0012 — HUD & UI (resource bar, building menu, settler info panel)

## M5 — Persistence
- 0013 — Save/load system

## v0.2 — "Banished loop" (planned 2026-10-26)
Owner playtest feedback: keep going, but (A) no day/night cycle, only seasons; (B) structures must be distinguishable and textures more interesting; (C) overall graphics too simple. Everything else follows Banished's gameloop: physical goods, laborers/builders, profession counts, renewable resources, households, tools, families.

### M6 — Seasons & Time
- 0014 — Seasons-only calendar & game speed

### M7 — Banished Economy
- 0015 — Resource catalog
- 0016 — Physical storage & hauling
- 0017 — Laborers, builders & profession management
- 0018 — Raw production buildings & work areas
- 0019 — Households, firewood & tools
- 0020 — Crop fields with a seasonal lifecycle

### M8 — Population
- 0021 — Aging & families
- 0022 — Roads & demolition

### M9 — Visual Overhaul
- 0023 — Procedural art pipeline & style guide
- 0024 — Terrain art & seasonal landscape
- 0025 — Distinct building art
- 0026 — Settler art & UI skin

### M10 — v0.2 Release
- 0027 — Integration, balance pass & docs for v0.2

## Later / stretch (not ticketed yet)
Deliberately deferred until M0–M5 form a working loop:
- Additional professions & buildings (healer, school, tailor, tavern, orchards, livestock)
- Trading post / merchants
- Disasters: fire, disease, famine
- Tech/research progression
- Multiple map biomes, procedural terrain generation
- Sound design
- Win/lose conditions beyond "settlement survives"

## Working agreement
- Tickets live in `docs/tickets/`; this roadmap only tracks grouping and order, not detailed scope.
- A milestone is "done" when every ticket in it is `done` and the result is playable end to end, not just individually functional.
