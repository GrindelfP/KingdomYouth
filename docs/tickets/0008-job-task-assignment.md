# 0008 — Job & task assignment system

- **Status:** done
- **Milestone:** M2 — Core Simulation Loop
- **Depends on:** 0006, 0007

## Goal
The player can assign settlers to jobs (e.g. "woodcutter"), and settlers with a job autonomously perform that job's work loop (go to workplace/resource, do work, deliver output) when not interrupted by urgent needs.

## Context
This is the other core interaction loop alongside building placement (0005). The player's main lever over the simulation, beyond placing buildings, is assigning settlers to the jobs those buildings create.

## Scope
- A `Job` concept tied to a work building (e.g. a finished Woodcutter's Lodge from 0009 "provides" a woodcutter job slot).
- A simple assignment UI/interaction: player clicks a settler (or a building's job slot) and assigns/unassigns a settler to a job. (Minimal UI is fine here — full polish is 0012's job.)
- A generic per-job work loop the settler executes: walk to work location/resource node → perform work action (timed) → produce output → deposit into stockpile (0004) → repeat. The specifics of "what resource, what output, what location" come from the job/building definition, not hardcoded per job.
- Idle behavior: an unemployed settler (no job assigned) does nothing active (or wanders near housing) — define this minimally, it's not a priority.
- Interruption: a settler mid-job whose hunger (0007) crosses the critical threshold should break off and address the need, then resume.
- Only settlers without a current job can be freely assigned; reassigning a busy settler should cleanly cancel their current task.

## Out of scope
- Job priority/skill levels (e.g. settlers getting better at a job over time) — not in Banished's core model either, skip.
- Automatic job assignment (player always assigns manually for MVP).
- Multiple settlers per job slot beyond what a building defines (0009 defines slot counts).

## Acceptance criteria
- [x] Player can assign an idle settler to an available job slot on a finished building and unassign them. (Click a settler, then click a building; `U` unassigns.)
- [x] An assigned settler autonomously performs the full work loop (travel → work → deposit) on a repeating basis without further player input. (Headless: farm output rose by 15 food in 12 s.)
- [x] A settler interrupted by critical hunger breaks off, satisfies the need, and resumes their job afterward. (Headless: paused at critical hunger, resumed after food returned, still assigned.)
- [x] Reassigning or unassigning a working settler cancels their in-progress task cleanly (no orphaned state, no duplicate output). (Output is only added on completed work; unassign mid-work produced no extra food.)

## Decisions
- `JobDef` resource (`scripts/buildings/job_def.gd`) hangs off `BuildingDef.job`: `slots`, `work_time`, `output_type`, `output_amount`, `target_terrain`. An empty `target_terrain` means the settler works at the building itself, from one of its access cells. A non-empty value means the settler harvests the nearest reachable tile of that terrain.
- `Worker` (`scripts/entities/worker.gd`) is a child node of each settler. States: IDLE, TRAVEL, WORK. Work only produces output on completion, and only if the target is still the right terrain, so a depleted tile or a cancelled task yields nothing.
- Interrupts: `Settler` ticks with `Needs`. While `is_critical()`, the worker pauses, which cancels the travel or work in progress. It resumes when hunger drops below critical. Eating is instant, so this is a brief break.
- Target search: forest candidates are sorted by distance and checked with the pathfinder, up to 30 tries. Failures retry after 3 s.
- Assignment is manual. `JobController` (`scripts/world/job_controller.gd`) handles click-to-select and click-to-assign, and reassignment unassigns the previous job first. Idle settlers do nothing.
- Known quirk: `BuildController` used to hold a `preload` of the barn resource in a `const`. That gave a `Resource` without its script when a `BuildingDef` was created first, so the list now loads at runtime.

## Open questions
- Exact UI for assignment (click building → see slots → click settler, vs. click settler → see job list) — defer bikeshedding to 0012; this ticket just needs *a* functional interaction, even a debug one.
