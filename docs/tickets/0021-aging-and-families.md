# 0021 — Aging & families

- **Status:** ready
- **Milestone:** M8 — Population
- **Depends on:** 0019

## Goal
Population works like Banished: settlers age, form families in houses, have children only when there is room, and eventually die of old age. Housing becomes the growth throttle.

## Context
Banished's population pressure comes from demographics: too few houses → no growth; a baby boom → many children who eat but do not work; an aging town → labor collapse. Today births are a flat timer per house.

## Scope
- Settler gets `age` (years, float), `sex`, `partner`, `name` (random first name from a small list in `resources/names.txt` or a constant array).
- Age advances with the calendar (1 year per game year, fractional per month). Stages: child (< 10), adult (10–59), elder (≥ 60).
  - Children do not work or haul; they follow their family. Drawn smaller.
  - Elders work at 70% speed.
  - Old-age death: each month after 60, a small rising chance; guaranteed before ~80.
- Families: a house holds one family (partner pair + children), capacity 5. When a settler becomes adult and an empty house exists, unpartnered adults of opposite sex pair up and move in together (Banished's "new family moves in when a house is free"). Single adults may also move in alone.
- Births: once per month per house, if it has a partnered pair, room, food in the house, and the mother is < 50, chance ~25% → newborn child (age 0).
- Profession assignment ignores children; a child turning adult becomes a laborer.
- Start of game: 3 couples (ages 18–35) and 3 children (ages 2–8).
- Info panel for settlers: name, age, stage, partner, home, profession, needs.
- HUD population: `Pop 14 (8 adults, 5 children, 1 elder)`; toasts for births/deaths/coming of age stay concise.
- Remove the old house birth cooldown.
- Save/load: age, sex, partner, name, family links.

## Out of scope
- Schools/education, trading for nomads, marriage across houses beyond the simple rule above.

## Acceptance criteria
- [ ] Without free houses population stops growing; building houses triggers new families and births.
- [ ] Children do not work; they become laborers when grown.
- [ ] Elders eventually die of old age.
- [ ] Save/load round-trips family structure.
- [ ] Headless run is free of script errors.

## Open questions
- None.
