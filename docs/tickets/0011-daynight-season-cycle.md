# 0011 — Day/night & season cycle

- **Status:** ready
- **Milestone:** M3 — Population & Time
- **Depends on:** 0007, 0009

## Goal
Time passes in a legible way (day count, season), and seasons meaningfully affect the simulation — primarily food production and warmth pressure — so the settlement faces the classic "survive the winter" tension.

## Context
Seasons are what make Banished's resource math actually matter (you must stockpile food/fuel before winter). For MVP, a single abstracted "year" with four seasons is enough; no need for a full calendar/weather system.

## Scope
- A `TimeManager` autoload tracking: current day, current season (spring/summer/autumn/winter), and elapsed in-game time, advancing on a configurable scale (e.g. N real seconds = 1 in-game day).
- Day/night as at minimum a visual cue (e.g. a day/night tint overlay) — deeper nighttime behavior (settlers sleeping on a schedule) is optional for MVP and can piggyback on the existing rest need (0007/0010) rather than requiring new mechanics.
- Season affects:
  - Farm production rate (0009) — e.g. reduced/zero in winter, boosted in summer.
  - Warmth need (stubbed in 0007) — becomes actually enforced here, with winter raising warmth drain, requiring a fuel source (reuse `wood` from 0004 as fuel, consumed passively by housed settlers in cold seasons, to avoid introducing a new resource type for MVP).
- Signals for season/day change so UI (0012) can display them.

## Out of scope
- Weather effects beyond season (rain, storms).
- Full day/night settler schedules (sleep at night, work by day) — nice-to-have, not required; settlers can work around the clock for MVP if simpler.
- Multi-year calendar quirks (leap years etc.) — irrelevant for a game.

## Acceptance criteria
- [ ] In-game day and season advance automatically and predictably.
- [ ] Farm output visibly changes across seasons per the defined multipliers.
- [ ] Warmth need (0007) is enforced using wood-as-fuel, with winter creating real pressure (settlers can die from cold if underprepared, per 0010's death wiring).
- [ ] Season/day changes emit signals consumable by the UI layer.

## Open questions
- Real-time-to-in-game-time ratio — pick a pace that makes a "year" long enough to matter but short enough to playtest quickly (e.g. a few real minutes per season); tune once playable.
- Whether night meaningfully changes settler behavior or is purely cosmetic for MVP — recommend cosmetic-only for now, revisit if the game needs more rhythm later.
