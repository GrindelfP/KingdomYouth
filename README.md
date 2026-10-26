# KingdomYouth

A Banished-like settlement builder. You never control your settlers directly. You place buildings, set how many settlers work in each profession, and keep the stockpile healthy, while the settlers look after their own hunger, rest, and warmth.

Balance growth against food, warmth, and shelter as the seasons change.

> **Status:** all MVP roadmap milestones (M0–M5) are done. The balance is a first draft and will change.

## Features

- Top-down 2D tile-grid world with forests, lakes, and rock
- Settlers with needs (hunger, rest, warmth, health) who act on their own
- Buildings: house, forester's lodge, gatherer's hut, hunting cabin, fishing dock, quarry, mine, farm, woodcutter, blacksmith, stockpile, storage barn
- Physical storage: goods are hauled by settlers to storage with limited capacity
- Banished-style labor: laborers haul materials, builders construct, and you set profession counts
- Seasons, a month/year calendar, and winter heating from each house's own firewood
- Households: houses keep their own food and firewood, and settlers fetch and eat from them
- Crafting: woodcutter (logs to firewood) and blacksmith (iron and logs to tools); tools wear out and speed up work
- Births, deaths, and a population that depends on housing and food
- HUD with resource bar, build menu, info panel, and toasts
- Save and load to a JSON file

## Requirements

- [Godot 4.4.1](https://godotengine.org/download/archive/4.4.1-stable/)

## Running the game

Open the project in Godot 4.4.1 and press **Play**, or run it from the terminal:

```sh
godot --path .
```

## Controls

| Action | Control |
| --- | --- |
| Pan the camera | `W` `A` `S` `D` or arrow keys |
| Zoom | Mouse wheel |
| Select a settler, building, or construction site | Left-click |
| Cancel a construction site (refunds delivered materials) | Right-click it, or `Delete` with it selected |
| Professions panel | `P` or the **Professions** button |
| Place a building | `B`, pick it in the build menu, then left-click |
| Pause / resume | `Space` |
| Game speed | `1` (normal), `2` (fast), `3` (fastest), or the top bar buttons |
| Save / load | `F5` / `F9` |

The full guide to controls, buildings, and the first hour of play is in [docs/tutorial.md](docs/tutorial.md).

## Project layout

```
assets/      Art and audio
docs/        Roadmap, tickets, tutorial, and session log
resources/   Building, job, and tileset resources
scenes/      Godot scenes
scripts/     GDScript: autoloads, entities, world, buildings, UI
```

Planning lives in [docs/roadmap.md](docs/roadmap.md) and [docs/tickets/](docs/tickets/).

## License

KingdomYouth is source-available. You may use, study, modify, and share it free of charge for non-commercial purposes. Any distributed copy or fork must stay free, include its source, and use the same license. Commercial use requires the author's written permission.

See [LICENSE](LICENSE) for the full terms.
