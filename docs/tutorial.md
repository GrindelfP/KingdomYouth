# KingdomYouth — Quick Tutorial

KingdomYouth is a settlement builder. You never control your settlers directly. You place buildings, set how many settlers work in each profession, and keep the stockpile healthy. Settlers look after their own hunger, rest, and warmth.

Run the game from the editor (`open -a Godot`, then Play), or from the terminal with `/Applications/Godot.app/Contents/MacOS/Godot --path .`.

## Controls

| Action | Control |
| --- | --- |
| Pan the camera | `W` `A` `S` `D` or arrow keys |
| Pan by dragging | Hold the middle mouse button and drag |
| Zoom | Mouse wheel |
| Select a settler, building, or construction site | Left-click it |
| Cancel a construction site | Right-click it, or `Delete` with it selected |
| Open the Professions panel | `P` or the **Professions** button |
| Clear the selection | Left-click empty ground, or `Esc` |
| Toggle placing mode | `B` (or click a button in the build menu) |
| Change the building you are placing | `Tab` |
| Place a building | Left-click while in placing mode |
| Stop placing | `Esc` or right-click |
| Pause / resume | `Space` or the `||` button |
| Game speed | `1`, `2`, `3`, or the `>`, `>>`, `>>>` buttons |
| Save the game | `F5` or the **Save** button |
| Load the saved game | `F9` or the **Load** button |
| Start over | **New game** button |

## What you start with

- 5 settlers, all homeless: 2 builders and 3 laborers.
- 80 logs, 30 stone, 10 iron, 40 firewood, 12 tools, 60 wheat, and 40 berries. The top bar shows logs, stone, iron, firewood, tools, and total food. Hover over Food to see each kind.
- A free Stockpile (400 capacity) and a Storage Barn (600 capacity) near the middle of the map, holding the starting goods. The top bar shows the total used and available storage.
- A map with forests, lakes, and rock. Your settlers start near the middle.

## The buildings

| Building | Cost | Size | What it does |
| --- | --- | --- | --- |
| **House** | 15 logs | 2x2 | Holds 4 settlers. Settlers with a home rest there, stay warm in winter, and can have children. |
| **Woodcutter's Lodge** | 10 logs | 2x2 | Has 2 woodcutter slots. Woodcutters walk to the nearest forest tile and gather 2 logs each trip. Goods collect in the building's output buffer (20 units); once it holds 10, a worker carries them to the nearest storage with room, so keep storage close. The tile turns to grass and grows back after 2 minutes. |
| **Farm** | 15 logs | 3x3 | Has 3 farmer slots. Each harvest gives 3 wheat. Farms work faster in summer and stop in winter. |
| **Stockpile** | free | 4x4 | Stores 400 units of materials, fuel, and tools. |
| **Storage Barn** | 40 logs, 20 stone | 3x3 | Stores 600 units of food, tools, and fuel. |

Buildings go on grass only. You cannot build on forest, water, or rock, or on top of another building. Buildings also block walking, so settlers path around them. Settlers standing on a spot do not stop you building there; they just walk away.

## Your first hour in the game

### 1. Look around

Pan with `WASD` and zoom with the mouse wheel. Find the forest, which is dark green, and the open grass, which is light green.

### 2. Build a house

Click **House** in the build menu at the bottom left. The hint line at the top shows what you are placing and why a spot is not valid. Move the cursor over open grass. A green box means you can place it here. A red box means you cannot, with the reason shown. Left-click to place it.

Placing a building costs nothing right away. It becomes a construction site that needs materials first: laborers carry the cost from storage to the site (the site shows an orange materials bar), and once everything has arrived the builders start work (the white progress bar). A house takes 20 builder-seconds, so two builders finish it in about 10 seconds plus walking time. More builders build faster; with 0 builders nothing is built. You can place a building even when you lack the logs; the site just waits for materials.

To cancel a site, right-click it or select it and press **Cancel construction** or `Delete`. Materials already delivered go back to storage.

When it is done, a toast appears in the top right. Homeless settlers move in automatically, up to 4 per house.

### 3. Build a Woodcutter's Lodge near the forest

Click **Woodcutter's Lodge**, then place it on grass close to the forest. Woodcutters walk to the nearest reachable forest tile, so closer is better.

### 4. Staff the lodge

You never assign settlers one by one. A finished workplace asks for its full number of workers and the town fills it from the laborers automatically. Select the lodge to change its **Desired workers** with `-` and `+` in the info panel.

You can also open the **Professions** panel (`P`). Each row shows `assigned / max` for a profession, where max is the total slots in your built workplaces. `+` turns the nearest laborer into that profession, and `-` sends the farthest one back to being a laborer. Builders have no maximum; raise them to build faster.

Woodcutters walk to the forest, gather logs, and return to repeat the loop. Logs appear in the top bar. Laborers who have nothing to deliver also empty full workplace buffers into storage and wait near the storage buildings.

### 5. Build a farm and staff it

Click **Farm** and place it on a 3x3 patch of grass. Up to 3 laborers become farmers once it is built, as in step 4. Food rises as farmers harvest and carry it to storage.

Settlers eat from the shared food stock by themselves when they get hungry, taking from the most plentiful kind first. If food runs out, they starve and their health falls.

### 6. Keep an eye on your settlers

Select a settler to see its needs:

- **Hunger** rises over time. Settlers eat when it passes 60. At 85 they stop working until they have eaten.
- **Rest** drains while they are awake. At 25 they walk home to rest until they reach 95. A settler without a home cannot recover rest.
- **Warmth** only matters in winter (see below).
- **Health** falls when settlers starve, get cold, or have no home. It recovers when they are fed and housed. At 0 a settler dies.

Births happen when a house has at least 2 settlers, room for another, and at least 10 food in the stockpile. A newborn appears about every 45 seconds per house.

### 7. Prepare for winter

The year has 12 months grouped into four seasons: spring, summer, autumn, and winter. Each month lasts 60 seconds at normal speed, so one season is roughly 3 minutes.

- **Summer:** farms run at 1.5 times their normal speed. Stock up.
- **Winter:** farms stop completely. Unheated settlers lose warmth, and then health.

To keep settlers warm in winter, each house with residents burns 1 firewood every 20 seconds. Nothing produces firewood yet, so the starting stock is all you have. The toast for "Winter" is a reminder.

The top bar shows the current month and year, for example "Mid Summer, Year 2".

### 8. Save and reload

Press `F5` or click **Save**. Press `F9` or click **Load** to go back to the saved state. Your settlers and their professions, buildings, construction deliveries and progress, and time all come back. **New game** starts a fresh settlement and leaves your save file alone.

## Tips

- Keep enough laborers: they carry all construction materials and also haul workplace output. Too many jobs leaves nobody to deliver.
- Build a house before your first birth is possible, since births need room.
- Place the farm and lodge close to houses to shorten settler trips.
- If all storage is full, workplaces fill up and stop working. Build another stockpile or barn.
- Watch the firewood count in winter, and the log count when you build.
- Use the info panel to check why a settler is idle. The task line shows **paused** when the settler is eating or resting.
- A forest tile that a woodcutter used will come back after 2 minutes, so a forest can last a long time if you spread woodcutters around.

## Known limits (for now)

- The balance (costs, rates, timings) is a first draft and will change.
- There is no main menu or settings screen.
- Stone, iron, tools, and most food kinds are not produced or used yet.
- Save files from older versions of the game may not load after changes.
