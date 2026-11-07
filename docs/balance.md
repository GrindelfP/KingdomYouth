# Balance and survival baselines

Base simulation numbers below are the final v0.2 values, unchanged by the M11 long-run baseline. Settings live in `.tres` files or constants; the file in brackets is where to change them. A month is 60 seconds at normal speed, a year is 12 months. Historical v0.2 results and the current twenty-year baseline are distinguished below.

## Time and survival constants

| Value | Setting | Where |
| --- | --- | --- |
| Month length | 60 s | `TimeManager.SECONDS_PER_MONTH` |
| Hunger gain | 1.0 per second (about 1 meal per settler per month) | `Needs.HUNGER_PER_SECOND` |
| Meal | restores 60 hunger, costs 1 food | `Needs.MEAL_RESTORE`, `FOOD_PER_MEAL` |
| Eat / drop work | hunger 60 / 85 | `Needs.EAT_HUNGER`, `CRITICAL_HUNGER` |
| Warmth loss outside a heated home (winter) | 1.5 per second | `Needs.WARMTH_DRAIN_PER_SECOND` |
| Health loss at 0 warmth | 1.5 per second (regeneration still gives back 0.5) | `Needs.COLD_DAMAGE_PER_SECOND` |
| Heating | each occupied house burns 1 firewood per 10 s in winter (about 18 per house per winter) | `SettlerManager.HEAT_DURATION` |
| Household targets | 30 food, 20 firewood, restock below half, 10 per trip | `Building.FOOD_TARGET`, `FIREWOOD_TARGET`, `RESTOCK_TRIP` |
| Tool life | 720 s of work (one year); no tool means half speed | `Settler.TOOL_LIFETIME`, `NO_TOOL_SPEED` |
| Growth | child at 10, elder at 60 (70% speed), certain death at 80; birth 25% per month per eligible couple with at least 10 food in the house | `Settler`, `SettlerManager` |

## Starting situation

9 settlers (3 couples aged 18-35, 3 children aged 2-8, 2 adults start as builders), a free Stockpile (400) and Storage Barn (600), and: 80 logs, 30 stone, 10 iron, 40 firewood, 12 tools, 60 wheat, 40 berries. Hunger starts at 50.

At 1 meal per settler per month the 100 starting food feeds 9 settlers for about 11 months, so food production must be running before the first winter. The 40 starting firewood covers 3 houses for about 2 winter months.

## Buildings

| Building | Cost | Build time (builder-s) | Workers | Work time | Yield |
| --- | --- | --- | --- | --- | --- |
| House | 15 logs | 20 | - | - | holds 5 |
| Forester's Lodge | 20 logs | 15 | 2 | 6 s cut, 3 s plant | 3 logs per mature tree; keeps forest near 60% |
| Gatherer's Hut | 15 logs | 12 | 2 | 5 s | 2 berries, 50% 1 mushroom; no winter work; full speed at 40 forest tiles in radius 8 |
| Hunting Cabin | 25 logs | 18 | 2 | 12 s | 4 venison; half speed in winter; full speed at 60 forest tiles in radius 10 |
| Fishing Dock | 30 logs | 20 | 2 | 8 s | 3 fish; half speed in winter; must touch water |
| Quarry | 30 logs | 25 | 3 | 10 s | 2 stone; needs 4 rock tiles within 3 |
| Mine | 40 logs, 20 stone | 30 | 3 | 14 s | 2 iron; needs 4 rock tiles within 3 |
| Crop Field 4x4 / 6x6 / 8x8 | 15 / 30 / 50 logs | 20 / 35 / 50 | 4 | plow 2.5 s, sow 2 s, reap 6 s | 2 wheat or cabbage per harvested cell; wheat ripens in 5.5 months, cabbage in 4.5 |
| Woodcutter | 20 logs | 15 | 1 | 6 s | 1 log into 3 firewood |
| Blacksmith | 30 logs, 10 stone | 20 | 1 | 12 s | 1 iron and 1 log into 1 tool |
| Stockpile | free (placed at start) | 12 | - | - | stores 400 (materials, fuel, tools) |
| Storage Barn | 40 logs, 20 stone | 30 | - | - | stores 600 (food, tools, fuel) |
| Dirt road | free | - | - | - | 1.5x walking speed |
| Stone road | 1 stone per tile | - | - | - | 2x walking speed |

Demolishing a building refunds half its cost.

## Historical v0.2 soak results

Scenario: `tools/soak/soak_test.gd` on the default map (seed 1337), time scale 10, 30 fixed frames per second, random seed 1. Columns are population (total, adults, children, elders), food (stock in storage), firewood (storage and houses), logs, tools, and mean health.

### Planned town

The script builds, in order and as soon as the logs are free: 3 houses, forester's lodge, gatherer's hut, 6x6 crop field, woodcutter, then a hunting cabin (month 8+), more houses, a 4x4 field, a fishing dock, quarry, mine, blacksmith, a second 6x6 field and a barn. It sets 1 forester, 1 gatherer, 2 farmers per field, 1 hunter and 1 woodcutter (paused above 120 firewood), and cuts builders from 2 to 1 at month 6, because only 6 adults can work.

| Time | Pop | Food in storage | Firewood | Logs | Tools | Health |
| --- | --- | --- | --- | --- | --- | --- |
| Y1 Spring | 9 | 100 | 40 | 80 | 12 | 100 |
| Y1 Summer | 13 | 36 | 40 | 0 | 8 | 100 |
| Y1 Autumn | 15 | 36 | 40 | 0 | 6 | 100 |
| Y1 Winter | 15 | 44 | 58 | 2 | 6 | 100 |
| Y2 Spring | 15 | 0 | 43 | 10 | 6 | 100 |
| Y2 Summer | 15 | 0 | 88 | 19 | 6 | 100 |
| Y2 Autumn | 15 | 0 | 127 | 0 | 6 | 100 |
| Y2 Winter | 15 | 32 | 164 | 14 | 6 | 100 |
| Y3 Spring | 15 | 12 | 100 | 17 | 6 | 100 |
| Y3 Summer | 15 | 42 | 110 | 2 | 5 | 100 |
| Y3 Autumn | 15 | 72 | 110 | 5 | 4 | 100 |
| Y3 Winter | 15 | 148 | 110 | 35 | 3 | 100 |

Nobody dies in three years. Pressure is real: logs hit 0 in the first summer (every log goes into houses and the first workplaces), and storage food falls to 0 in the second spring and summer while the houses still hold about 50 (the top bar counts storage only). Population stops at 15 because each couple's house is full (5) and the starting children only start families at 16.

### No firewood (food economy as above, no woodcutter)

First winter passes on the starting 40 firewood (pop 12). In the second winter the houses are empty, warmth drops, and every settler is dead by month 23 (end of Y2 Winter) with 150 food still in storage.

### Neglect (3 houses only, no food or fuel production)

Pop rises to 15 on the starting food, food runs out in autumn, the first death is in month 9 and the town is extinct in month 11, before the first winter ends (no building alone keeps a town alive).

## Tuning history

- Hunger was 0.7 per second: the starting food lasted 16 months and a gatherer produced twice what 15 settlers eat, so food never mattered. Now 1.0.
- Heating was 1 firewood per 20 s: the starting 40 firewood covered two full winters. Now 1 per 10 s.
- Cold did 0.5 damage per second against 0.5 regeneration, so no firewood meant no deaths. Warmth loss is now 1.5 and cold damage 1.5.

## Repeating the check

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --fixed-fps 30 res://tools/soak/soak.tscn -- --mode=planned --years=20 --seed=1
```

Modes: `planned`, `nowood`, `neglect`. The current planner and checks are described below; they supersede the historical three-year scenario above. Use `--mode=nowood --years=3 --seed=1` and `--mode=neglect --years=3 --seed=1` for the lethal controls. Every run prints the terrain and simulation seeds.

Save round trip across two processes:

```sh
G=/Applications/Godot.app/Contents/MacOS/Godot
$G --headless --path . --fixed-fps 30 res://tools/soak/roundtrip.tscn -- --phase=save
$G --headless --path . res://tools/soak/roundtrip.tscn -- --phase=load
$G --headless --path . res://tools/soak/roundtrip.tscn -- --phase=old
```

The save phase builds a town for 14 months, lays roads, leaves a construction site, saves to `user://roundtrip_save.json` and writes a state digest; the load phase loads it in a fresh process and compares settlers, buildings, sites, stock, trees and roads. The `old` phase checks that a save from the previous version is rejected. Neither script touches the normal save file.

## M11 twenty-year baseline (ticket 0030)

Verified with Godot 4.4.1, fixed 30 FPS, time scale 10, terrain seed 1337. `--seed` selects the simulation RNG seed (initial ages, births, sex, and work randomness), not a different terrain. The default is `--years=20 --seed=1`. Month 0 is the start of Y1; month 240 is the Y21 spring boundary, after twenty complete years. Seasonal output includes children/adults/elders, workforce and profession counts, cumulative births and deaths by hunger/cold/exposure/old age, and physical food/firewood/tools in storage, households, workplaces, construction, transit, and town total.

### Affordable, real-labor planner

- Keep the normal starting settlers, inventories, stockpile, and barn. No instant completion, recurring supplies, direct movement, or extra settlers. All later buildings use `BuildController.try_place`, delivered materials, and actual builder work. Placement subtracts outstanding site commitments before testing affordability and keeps access margins around buildings.
- Queue three houses, forester, gatherer, 6x6 field, woodcutter; then quarry (month 8+), mine (10+), blacksmith (12+), hunter (14+). These are earliest dates, not promises: seed 1 actually places the woodcutter at month 9, quarry at 16, mine at 26, blacksmith at 30, and hunter at 39. Initial 80 logs only fund three houses, forester, and gatherer; later costs depend on real logging.
- Manage about once per simulated second. Reserve one builder and at least one laborer; never request more production workers than the remaining working-age population. Priority: forester, woodcutter, gatherer, hunter, blacksmith, mine, quarry, field. Request one worker per building except two farmers. Winter releases gatherers/farmers. Unused capacity remains laborers, which can haul and supply households; jobs are not assigned to children.
- Pause logging above 120 stored logs and fuel cutting above 120 stored firewood. Pause smithing at 20 stored tools, mining at 20 iron, quarrying at 40 stone. Resume below those cutoffs. Batch output and goods in transit can overshoot. These are test-planner staffing decisions, not a new production-limit game feature. They prevent logs from monopolizing storage and release scarce workers for food and replacement tools.
- Once the initial queue and active sites finish, add a house when a settler aged 16+ is homeless or still with parents, provided there is no empty house. Empty houses allow singles to leave parents and unrelated couples to form. Otherwise expand barns only above 75% of food-accepting storage capacity, not merely when food exceeds a fixed amount. Every expansion still waits for affordable logs/stone and construction labor.
- `nowood` uses the same rules but omits the woodcutter. `neglect` builds only three houses and leaves starting professions unchanged. Neither control deletes the initial supplies.

### Failures found and resolved

Extending the unchanged three-year planner to twenty years **failed**: first death at month 93, extinction at 107, six hunger and nine cold deaths, no successor households. Tools ran out in Y5, the fixed job requests consumed the workforce before later workshops could be staffed, and the barn at the head of the expansion queue could not obtain stone. By extinction, 600 stored food and logs clogging material storage did not constitute a functioning survival economy. There were no frozen-travel reports.

The first labor-budget revision passed seed 1, but seed 2 lost a whole five-person household to hunger at month 38 while industry outranked hunting. Moving hunting ahead of smithing/mining/quarrying removed those deaths on rerun. A provisional fixed-food expansion trigger also built excessive barns (14,800 total storage); the capacity-relative trigger reduced seed 1 to 2,800 total storage. **No game production, aging, fertility, hunger, heating, tool-wear, or movement constants changed.** The correction is feasible town planning and staffing, not hidden balance assistance.

### Measured final outcomes

All final runs returned `VERDICT: PASS`, with zero script errors, zero unexplained inventory differences, zero travel stalls, and no skipped placements. Initial population is nine in every run.

| Run | Final population (children/adults/elders) | Births | Grew up / observed working | Successor members / households | Hunger / cold deaths | Town food / fuel / tools |
| --- | --- | --- | --- | --- | --- | --- |
| 20 years, seed 1 | 28 (12/16/0) | 19 | 10 / 10 | 4 / 2 | 0 / 0 | 1447 / 106 / 21 |
| 20 years, seed 2 | 30 (15/15/0) | 21 | 9 / 9 | 4 / 2 | 0 / 0 | 1455 / 102 / 20 |
| 20 years, seed 3 | 36 (20/16/0) | 27 | 10 / 9 | 8 / 4 | 0 / 0 | 1498 / 128 / 23 |
| No fuel, seed 1 (month 36) | 0 | 6 | 0 / 0 | 0 / 0 | 0 / 15 | 45 / 0 / 16 |
| Neglect, seed 1 (month 11) | 0 | 6 | 0 / 0 | 0 / 0 | 15 / 0 | 0 / 12 / 10 |

No exposure or old-age deaths occurred. No-fuel deaths all occur in month 23, with food still physically present. Neglect first kills through hunger in month 9 and reaches extinction in month 11. Controls passing means their expected failure was observed, not that their towns survived.

Selected seasonal checkpoints for seed 1 (all resources are **town-wide**, unlike the historical table):

| Elapsed years | Population C/A/E | Births | Grew / worked | Successor households | Food | Firewood | Tools |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 0 | 3/6/0 | 0 | 0/0 | 0 | 100 | 40 | 12 |
| 1 | 9/6/0 | 6 | 0/0 | 0 | 74 | 16 | 7 |
| 3 | 8/7/0 | 6 | 1/0 | 0 | 32 | 145 | 11 |
| 5 | 6/9/0 | 6 | 3/1 | 0 | 221 | 145 | 20 |
| 10 | 7/9/0 | 7 | 3/3 | 0 | 949 | 145 | 23 |
| 15 | 6/15/0 | 12 | 9/8 | 1 | 1369 | 146 | 21 |
| 20 | 12/16/0 | 19 | 10/10 | 2 | 1447 | 106 | 21 |

At the final seed-1 checkpoint: food = 1248 stored + 194 household + 5 workplace; fuel = 100 household + 6 carried; tools = 21 stored. Storage alone reports zero fuel but the town is not out. The town has 23 completed buildings and no sites; ten houses include singles/parents as well as successor couples. Seed 1 was rerun with **byte-identical complete console output** (SHA-256 `08107bc603f4f4fdbbd36fb949e0b7f0126d5e5ec849ae243f499b3de906c5d7`). Existing focused tests report `INVENTORY OK`, `ECONOMY OK`; the two-process save test reports `ROUNDTRIP OK` (0/10 digest sections differ), and the older-save rejection check passes.

### What the gate checks, and its limits

- Each season reconciles every good against initial physical stock plus recorded production/imports minus consumption/exports/losses. Internal transfers must conserve town totals. Known discards are explicit `lost` flows, not unexplained disappearance. Initial accounting begins after the normal deferred bootstrap has supplied the starting inventories.
- Sample travel every 20 simulated seconds. A travel/pickup/delivery/return state, or actual movement, that remains in the same grid cell for more than 90 simulated seconds without a needs pause is a failed stall. Work/build and legitimate idle time are excluded. Long idle workplaces print their off-season/input/storage/access reason; the reserve labor pool is explicitly labeled. A season-boundary `Ready` message can precede the next normal worker retry and is not stalled travel.
- A 20-year planned run fails on extinction, any hunger/cold/exposure death, no observed child-cohort work, no successor household, an inventory discrepancy, or a travel stall. Shorter planned runs do not require successor evidence. Controls require extinction and at least one death from their expected cause, plus clean accounting/travel. Exit status is 0 for pass, 1 for a failed gate, 2 for invalid mode/year arguments.
- `grew` counts crossing working age (10); `worked` counts those settlers subsequently observed doing actual work/building. Successor members retain parent references, have a partner and home, and no longer live with parents; households count distinct home origins over the run. These are cumulative test observations, not new persistent gameplay statistics.
- This is a default-map, scripted-planning baseline, not proof that every player plan or seed survives. All three checked simulation seeds survive without deaths, but the first winter remains tight. No founding settler reaches elder age in twenty years (starts at 18–35, elder at 60); zero elders/old-age deaths are expected, **not** proof of elder replacement. This does not satisfy the 30-year release gate (0049), large-map performance, future services, or arbitrary map seeds. The existing save check still covers its original 14-month scenario, not a 20-year save/resume.
