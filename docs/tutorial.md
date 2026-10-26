# KingdomYouth — Quick Tutorial

KingdomYouth is a settlement builder. You never control your settlers directly. You place buildings, assign settlers to jobs, and keep the stockpile healthy. Settlers look after their own hunger, rest, and warmth.

Run the game from the editor (`open -a Godot`, then Play), or from the terminal with `/Applications/Godot.app/Contents/MacOS/Godot --path .`.

## Controls

| Action | Control |
| --- | --- |
| Pan the camera | `W` `A` `S` `D` or arrow keys |
| Pan by dragging | Hold the middle mouse button and drag |
| Zoom | Mouse wheel |
| Select a settler or building | Left-click it |
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

- 5 settlers, all homeless.
- 50 wood, 20 food, 0 stone. Stone is not used yet.
- A map with forests, lakes, and rock. Your settlers start near the middle.

## The buildings

| Building | Cost | Size | What it does |
| --- | --- | --- | --- |
| **House** | 15 wood | 2x2 | Holds 4 settlers. Settlers with a home rest there, stay warm in winter, and can have children. |
| **Woodcutter's Lodge** | 10 wood | 2x2 | Has 2 woodcutter slots. Woodcutters walk to the nearest forest tile and gather 2 wood each trip. The tile turns to grass and grows back after 2 minutes. |
| **Farm** | 15 wood | 3x3 | Has 3 farmer slots. Each harvest gives 3 food. Farms work faster in summer and stop in winter. |
| **Storage Barn** | 10 wood | 2x2 | Decorative only. The stockpile is shared by the whole settlement, so the barn adds nothing yet. |

Buildings go on grass only. You cannot build on forest, water, or rock, or on top of another building. Buildings also block walking, so settlers path around them. Settlers standing on a spot do not stop you building there; they just walk away.

## Your first hour in the game

### 1. Look around

Pan with `WASD` and zoom with the mouse wheel. Find the forest, which is dark green, and the open grass, which is light green.

### 2. Build a house

Click **House** in the build menu at the bottom left. The hint line at the top shows what you are placing and why a spot is not valid. Move the cursor over open grass. A green box means you can place it here. A red box means you cannot, with the reason shown. Left-click to place it.

The house takes about 6 seconds to finish. When it is done, a toast appears in the top right. Homeless settlers move in automatically, up to 4 per house.

### 3. Build a Woodcutter's Lodge near the forest

Click **Woodcutter's Lodge**, then place it on grass close to the forest. Woodcutters walk to the nearest reachable forest tile, so closer is better.

### 4. Assign woodcutters

1. Click one of your settlers (cream dots) to select it. The info panel appears on the right.
2. Click the lodge. The panel now lists its workers and the idle settlers.
3. Press **Assign** next to a settler. Do this for up to 2 settlers.

Assigned settlers walk to the forest, gather wood, and return to repeat the loop. Wood appears in the top bar.

To take a settler off the job, select the building and press **Remove**, or select the settler and press **Unassign job**.

### 5. Build a farm and assign farmers

Click **Farm** and place it on a 3x3 patch of grass. Then assign up to 3 settlers to it, the same way as in step 4. Food rises as farmers harvest.

Settlers eat from the shared food stock by themselves when they get hungry. If food runs out, they starve and their health falls.

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

To keep settlers warm in winter, each house with residents burns 1 wood every 20 seconds. Keep wood in the stockpile before winter arrives. The toast for "Winter" is a reminder.

The top bar shows the current month and year, for example "Mid Summer, Year 2".

### 8. Save and reload

Press `F5` or click **Save**. Press `F9` or click **Load** to go back to the saved state. Your settlers, buildings, construction progress, and time all come back. **New game** starts a fresh settlement and leaves your save file alone.

## Tips

- Build a house before your first birth is possible, since births need room.
- Place the farm and lodge close to houses to shorten settler trips.
- Watch the wood count. Houses use wood in winter, and buildings cost wood.
- Use the info panel to check why a settler is idle. The job line shows **paused** when the settler is eating or resting.
- A forest tile that a woodcutter used will come back after 2 minutes, so a forest can last a long time if you spread woodcutters around.

## Known limits (for now)

- The balance (costs, rates, timings) is a first draft and will change.
- There is no main menu or settings screen.
- Stone is not produced or used yet.
- Save files from older versions of the game may not load after changes.
