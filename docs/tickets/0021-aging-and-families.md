# 0021 — Aging & families

- **Status:** done
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
- [x] Without free houses population stops growing; building houses triggers new families and births.
- [x] Children do not work; they become laborers when grown.
- [x] Elders eventually die of old age.
- [x] Save/load round-trips family structure.
- [x] Headless run is free of script errors.

## Open questions
- None.

## Implementation notes

**Settler API:** `given_name`, `sex` (`Settler.Sex.MALE/FEMALE`), `age` (years, float; use `set_age()` to redraw), `partner`, `parents: Array[Settler]`. `get_age_stage()` returns `Settler.AgeStage.CHILD/ADULT/ELDER` (thresholds `CHILD_AGE` 10, `ELDER_AGE` 60), `get_stage_name()`, `is_working_age()` (age >= 10, elders included), `lives_with_parent()`, `is_kin_of()`. `work_speed()` is multiplied by `ELDER_SPEED` 0.7 for elders. Drawing: children radius 4 instead of 6, females tinted pink, elders get a grey ring (placeholder for 0026).

**Children:** `Worker._plan` hands non-working-age settlers to `_plan_child()`: eat at home (or at a storage when homeless), otherwise go home and idle. They never haul, build, restock or take tools. `LaborManager.get_count` and `_nearest_laborer` skip children, so profession counts and the laborer pool cover working-age settlers only.

**Aging and death (`SettlerManager`):** on every `TimeManager.month_changed` age grows by 1/12. `settler_grew_up(settler)` fires when a child reaches 10. From 60 each month the death chance is `0.005 + 0.2 * t^2` with `t = (age-60)/20`, certain at 80 (`OLD_AGE_*`). `settler_died(settler, old_age: bool)`; `_remove_settler` clears partner/parent links. `count_by_stage()` returns `[children, adults, elders]`.

**Families and housing (checked every second, replaces `_assign_homeless`):** house capacity is 5. Order: pair unpartnered adults (age >= 16, opposite sex, not kin; into a lone single's house or an empty house), move homeless couples into empty houses, move single adults alone into remaining empty houses (homeless first, then grown children of the household), homeless children/partners follow parents/partner when there is room, orphans and elders without a partner fill any house with room. Without an empty house nobody new moves in.

**Births:** monthly per house, if it has free room, >= 10 food (`BIRTH_MIN_FOOD`), a female resident aged 16-49 whose partner lives there, 25% chance. Newborn age 0, parents linked. The house birth cooldown was removed.

**Start:** 3 couples (18-35), 3 children (2-8), 2 adults as builders. Starting stock unchanged; the first year with 9 mouths is survivable at time scale 20 with 5 houses (health stayed 100, population 9 to 15 in one year). Balance is left to 0027.

**UI:** HUD `Pop N (a adults, c children, e elders) | working W, builders B`; toasts use names ("X was born", "X came of age", "X died of old age"). Info panel shows name, stage, sex, age, partner, home; house panel lists residents.

**Save:** `SAVE_VERSION` 9: settlers save `name`, `sex`, `age`, `partner` (display_id or -1), `parents` (display_ids); family links are rebuilt in a second pass. The `birth_cooldown` building key is gone.

**Verified headless (throwaway scripts):** no house means no growth; one house takes one family; more houses lead to births; houses never exceed 5; children stay laborers with no job; they came of age, joined the laborer pool and paired up into empty houses; elders all died by 80; save/load round-tripped names, ages, partners, parents and homes.

**Not done:** marriage between elders or widows remarrying; no inheritance of professions; child/elder art is placeholder.
