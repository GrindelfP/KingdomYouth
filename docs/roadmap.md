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

## v0.2 — "Banished loop" (planned 2026-10-26, complete)
Status: all milestones M6–M10 are done and playable end to end; see `docs/balance.md` for the final numbers.
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

## v3 — A Town Worth Keeping (planned; not implemented)

**Version intent:** this is the requested **v3** roadmap, not a rename to v0.3. The implemented baseline remains v0.2 (M0–M10); no intervening release or v3 feature is implied to exist. All M11–M20 below are proposed work, with no tickets allocated yet. Create and refine tickets before implementation; the scopes and completion gates here guide that breakdown, not replace it.

**Goal:** carry a vulnerable founding village into a durable, multigenerational town. Keep Banished's indirect control, scarce labor, physical goods, seasonal survival, and housing-led growth. Progress comes from surplus, trade, education, and better services, not research points, combat, or directly commanded settlers. Retain the 2D tile-grid presentation and seasons-only calendar.

**Starting point:** v0.2 already has physical hauling/storage, professions, households, tools, families, seasonal fields, renewable forests, roads, demolition, and save/load. Extend these rather than rebuilding them. Known pressure points include food totals that omit household reserves and a three-year balance check too short to exercise generational replacement. The world already uses seeded terrain generation; map variety below means exposing and validating more starts, not introducing generation from nothing.

**Delivery order:** M11 → M12 → M13 → M14 → M15 → M16 → M17 → M18 → M19 → M20. Dependencies below are the minimum functional prerequisites; this sequence is the preferred implementation order. Persistence, readable feedback, generated art consistent with `docs/art-style.md`, and focused regression checks belong to every milestone, not just release polish.

### M11 — Readable Economy & Long-Run Baseline
- **Depends on:** completed M10.
- **Scope:** show food and fuel separately in storage, households, and transit, plus town-wide totals without double counting. Add seasonal production/consumption history, shortage warnings, and clear reasons for idle work (no inputs, no workers, full storage, unreachable destination). Extend the existing soak scenarios to cover aging and family replacement before adding new pressures.
- **Complete when:** moving goods between inventories preserves totals; a player can explain a shortage from the UI; a repeatable 20-year planned-town run reports population age groups, births/deaths, food, fuel, and tools without script errors or permanently stuck settlers. Record baseline outcomes, including any survival failures, and resolve blockers before proceeding.

### M12 — Markets, Reserves & Production Limits
- **Depends on:** M11.
- **Scope:** add a market with assigned vendors who physically collect goods and supply nearby households. Keep direct household restocking as a fallback outside coverage or when a market is empty. Add per-good production limits and visible reserve targets so the player can balance winter stocks against labor without manually pausing every workshop. Targets guide work; they never conjure or teleport goods.
- **Complete when:** covered and uncovered homes both restock correctly; market radius and staffing affect delivery time; a full or disconnected market cannot deadlock hauling; production stops at its limit and resumes after consumption. Save/load preserves market contents, settings, and valid hauling commitments without duplication.

### M13 — Clothing & Food Diversity
- **Depends on:** M12.
- **Scope:** introduce leather as a hunting by-product, a tailor, wearable coats, and coat wear/replacement. Coats reduce exposure but do not replace heated homes. Group existing foods into understandable dietary categories and make a varied diet improve long-term health rather than instantly punish a single-food starter village. Show clothing and dietary status on settler and town panels.
- **Complete when:** leather is hauled and consumed into coats, settlers obtain and wear them out, and clothed/unclothed winter checks demonstrate a documented difference. Varied food has a measurable benefit, basic food still prevents starvation, and the original first-winter loop remains viable before a tailor is built.

### M14 — Schools & Community Life
- **Depends on:** M11 and M13.
- **Scope:** add schools and teachers, a student life stage, and an education benefit to adult production. Make time spent in school a real short-term workforce cost; children unable to attend must still have a viable uneducated path into work. Add cemeteries and a small happiness model tied to bereavement and access to community services, with visible, bounded effects rather than unexplained productivity collapse.
- **Complete when:** a child cohort enrolls, graduates, and joins the workforce across a long-run test; school closure or teacher loss has defined behavior and cannot strand students forever. Educated and uneducated work yields are documented, deaths can fill cemetery capacity, and household replacement remains possible over multiple generations.

### M15 — Trading Post & Merchant Visits
- **Depends on:** M12 and M13.
- **Scope:** add a shoreline trading post with assigned traders and a valid water approach, scheduled merchant visits, barter values, and explicit player-confirmed exchanges. Trade inventory must be physically stocked and unavailable for household use until released. Start with existing goods plus orchard seeds and livestock unlocks consumed by M16; show their future use clearly. Protect essential reserves from accidental export.
- **Complete when:** an accessible post receives merchants; an inaccessible shore placement is rejected with a reason. A complete export/import cycle conserves quantities, respects capacity and reserves, and survives saving during a visit. Merchant offers and arrivals resume consistently after loading, and a settlement can still survive without trading.

### M16 — Orchards & Pastures
- **Depends on:** M13 and M15.
- **Scope:** add orchards with imported seeds, multiyear tree maturity, seasonal harvest, and replanting; add fenced pastures with imported breeding stock, capacity, reproduction, and slaughter controls. Begin with one fruit crop and sheep producing wool/meat; extend the tailor to warm wool coats. Require workers, land, and transport, with livestock kept distinct from stored meat or wool.
- **Complete when:** purchased seeds establish an orchard that only yields after maturation; a breeding pair grows into a managed flock without exceeding capacity; slaughter does not silently destroy protected breeding stock. Fruit and animal products reach real storage, wool becomes clothing, and a round-trip preserves tree age, animals, and breeding progress.

### M17 — Health, Fire & Recoverable Crises
- **Depends on:** M12–M16.
- **Scope:** add herbalists/herbs for routine health, a staffed hospital for infectious illness, and wells with autonomous firefighting. Introduce bounded disease outbreaks and building fires with clear warnings, causes, and prevention. Famine remains the consequence of insufficient food, not an arbitrary event that deletes stocks. Offer disaster-off and normal settings; no tornadoes or additional disaster types in this milestone.
- **Complete when:** controlled scenarios show illness spreading and treatment reducing its harm; a contained fire consumes real response labor and water access, while an unattended fire can spread. Displaced households, lost inventories, demolition, and rebuilding remain consistent. Prepared towns demonstrably recover, warnings allow a response, and loading mid-crisis neither clears nor duplicates its effects.

### M18 — Replayable Starts & Expansion
- **Depends on:** M15–M17.
- **Scope:** expose the existing map seed and add validated mild/harsh climate presets and standard/large map sizes. Generate usable settlement land, forest, rock, and accessible trading water; add bridges for crossing water without bypassing construction costs or pathfinding. Difficulty changes starting supplies and climate pressure, not hidden production cheats. Keep the current default start available as a regression fixture.
- **Complete when:** a documented seed set for each preset passes starting-access and resource checks; the same seed/settings reproduce terrain. Bridge construction and removal update paths without trapping the simulation. Saved worlds restore their actual terrain/settings, and an expanded town runs at a documented population and map-size target with measured frame and simulation costs.

### M19 — Settlement Identity, Guidance & Presentation
- **Depends on:** M11–M18.
- **Scope:** add a town overview with population history, service coverage, household needs, and event history; guided first-winter objectives and optional long-term settlement goals. Add extinction feedback with restart/load choices while preserving open-ended play after goals are met. Give all new buildings distinct seasonal art, legible crisis indicators, and restrained ambient/production audio with volume controls. Support pause-and-inspect planning without losing alerts.
- **Complete when:** a new player can identify a shortage, find its cause, and take corrective action without logs; objectives recognize actual simulation state rather than reward free supplies. Every new building/service is identifiable at normal zoom, sound can be muted, and a playtest covers survival, recovery, optional goals, and extinction without forcing a victory ending.

### M20 — v3 Integration & Release Gate
- **Depends on:** M11–M19; all associated tickets completed.
- **Scope:** integrate balance, performance, documentation, and save compatibility. Decide and document whether to migrate v0.2 saves or reject them explicitly before finalizing the v3 save format; never silently reinterpret old data. Expand the existing soak and two-process round-trip tools rather than substituting manual confidence for repeatable checks.
- **Complete when:**
  - A documented 30-year planned-town scenario sustains successive adult generations and exercises markets, education, trade, orchards, livestock, and services without script errors, inventory duplication, or permanently stuck settlers.
  - Shortage, disaster-off, outbreak, and fire scenarios demonstrate both preventable failure and recovery; the no-food/no-fuel scenarios still fail for understandable survival reasons.
  - Two-process save/load checks cover all new persistent state, including merchant visits, unlocks, students, coats, animal populations, crises, map settings, and goods in transit; older/invalid saves are migrated or rejected as documented.
  - Default and large-map performance results meet targets fixed during M18, and an interactive playtest verifies build placement, trade confirmation, warnings, and recovery controls.
  - `README.md`, tutorial, balance tables, roadmap status, and ticket statuses describe the shipped game. Only then mark v3 implemented.

**v3 boundaries:** no combat, controllable units, research tree, currency economy, multiplayer, day/night cycle, or engine/presentation rewrite. Additional crops, animals, and disaster types wait until the first complete chains are balanced. Taverns, chapels, nomad immigration, mining depletion, and stone-house upgrades are candidates after this release, not implicit v3 commitments.

## Later / stretch — original backlog (preserved)
Originally deferred until M0–M5 formed a working loop. The list below is historical: professions, trade, disasters, map variety, sound, and optional goals now have planned v3 scope above; nothing in this list is newly implemented. Tech/research remains deferred and is not part of v3's Banished-style progression.
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
