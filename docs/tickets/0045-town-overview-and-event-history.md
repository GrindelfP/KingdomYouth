# 0045 — Town overview, service coverage & event history

- **Status:** ready
- **Milestone:** [M18 — Settlement Identity, Guidance & Presentation](../roadmap.md#m18--settlement-identity-guidance--presentation)
- **Depends on:** 0044

## Goal
Give players one inspectable explanation of population trends, unmet household needs, and service gaps.

## Context
Reuse 0029 economic history and existing service/settler state; the overview must not invent a parallel simulation or report merely nearby but inaccessible services as working.

## Scope
- Add a town overview showing population age/student history, births/deaths, clothing/diet/happiness, food/fuel trends, and households lacking needs.
- Show market/school/cemetery coverage with capacity/staff/access distinctions and navigation to affected homes/buildings.
- Keep a bounded 20-year event history for births/deaths, shortages/recovery, graduations, trade/unlocks, and objective hooks; coalesce repetitive events without losing important warnings.
- Make alerts/history/detail panels usable while paused, with retained actionable alerts after toasts fade.
- Audit every v3 building/good/animal and shortage/service indicator against `docs/art-style.md`; fill missing generated assets and review normal-zoom seasonal readability.
- Persist history, avoiding replayed events on load; document retention and sorting behavior.

## Out of scope
- Fire/disease indicators, new services, and direct settler commands.
- Objectives/extinction flow and audio (0046–0047).

## Acceptance criteria
- [ ] A deliberately starved/disconnected household is identifiable, explained, and reachable from the overview without logs.
- [ ] Demographic/service figures agree with simulation fixtures and history retention is bounded.
- [ ] Pause preserves selection/alerts, and loading neither drops retained history nor replays births/trades.
- [ ] Screenshots at normal zoom identify each new structure/service in summer and winter at 1280x720.
- [ ] Headless data checks and a windowed shortage investigation pass.

## Open questions
- None.
