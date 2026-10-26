# Balance (v0.2)

Numbers below are the final v0.2 values. Everything except the first table lives in `.tres` files or constants; the file in brackets is where to change it. A month is 60 seconds at normal speed, a year is 12 months.

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

## Soak results

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
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --fixed-fps 30 res://tools/soak/soak.tscn -- --mode=planned --years=3
```

Modes: `planned`, `nowood`, `neglect`. A run takes about 10 seconds. The script prints one row per season and a summary with the first death month, extinction month and any settler that stood still for three-quarters of a month while travelling.

Save round trip across two processes:

```sh
G=/Applications/Godot.app/Contents/MacOS/Godot
$G --headless --path . --fixed-fps 30 res://tools/soak/roundtrip.tscn -- --phase=save
$G --headless --path . res://tools/soak/roundtrip.tscn -- --phase=load
$G --headless --path . res://tools/soak/roundtrip.tscn -- --phase=old
```

The save phase builds a town for 14 months, lays roads, leaves a construction site, saves to `user://roundtrip_save.json` and writes a state digest; the load phase loads it in a fresh process and compares settlers, buildings, sites, stock, trees and roads. The `old` phase checks that a save from the previous version is rejected. Neither script touches the normal save file.
