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
| Lay a road | Pick a road in the build menu, then drag with the left mouse button and release |
| Stop placing | `Esc` or right-click |
| Demolish a building, site, or road | `X` or the **Demolish** button, then left-click it |
| Stop demolishing | `X` again, `Esc`, or right-click |
| Pause / resume | `Space` or the `||` button |
| Game speed | `1`, `2`, `3`, or the `>`, `>>`, `>>>` buttons |
| Save the game | `F5` or the **Save** button |
| Load the saved game | `F9` or the **Load** button |
| Start over | **New game** button |

## What you start with

- 9 settlers, all homeless: 3 couples (2 of the adults start as builders) and 3 children. Each settler has a name, age and sex.
- 80 logs, 30 stone, 10 iron, 40 firewood, 12 tools, 60 wheat, and 40 berries. The top bar shows logs, stone, iron, firewood, tools, and total food. Hover over Food to see each kind.
- A free Stockpile (400 capacity) and a Storage Barn (600 capacity) near the middle of the map, holding the starting goods. The top bar shows the total used and available storage.
- A map with forests, lakes, and rock. Your settlers start near the middle.

## The buildings

| Building | Cost | Size | What it does |
| --- | --- | --- | --- |
| **House** | 15 logs | 2x2 | Holds one family of up to 5. Settlers with a home rest there, eat there, stay warm in winter, and a couple living there can have children. Each house keeps its own food and firewood. |
| **Forester's Lodge** | 20 logs | 2x2 | 2 foresters. Work radius 8 tiles. Cuts mature trees (3 logs each) and plants saplings on free grass so the forest stays at about 60% density. |
| **Gatherer's Hut** | 15 logs | 2x2 | 2 gatherers. Radius 8. Collects berries and some mushrooms in forest tiles; faster the more forest is in range (full speed at 40 forest tiles). Stops in winter. |
| **Hunting Cabin** | 25 logs | 2x2 | 2 hunters. Radius 10. Venison from forest tiles in range (full speed at 60 forest tiles); half speed in winter. |
| **Fishing Dock** | 30 logs | 2x2 | 2 fishers. Must touch water. Fish; half speed in winter. |
| **Quarry** | 30 logs | 3x3 | 3 quarrymen. Needs at least 4 rock tiles within 3 tiles. Produces stone. |
| **Mine** | 40 logs, 20 stone | 3x3 | 3 miners. Needs at least 4 rock tiles within 3 tiles. Produces iron. |
| **Crop Field** | 15 / 30 / 50 logs | 4x4 / 6x6 / 8x8 | Up to 4 farmers. Grows wheat or cabbage cell by cell over the year (see below). Each harvested cell gives 2 of the crop. Press `R` while placing to change the size. |
| **Woodcutter** | 20 logs | 2x2 | 1 woodcutter. Turns 1 log into 3 firewood. Fetches logs from storage in batches. |
| **Blacksmith** | 30 logs, 10 stone | 2x2 | 1 blacksmith. Turns 1 iron and 1 log into 1 tool. |
| **Stockpile** | free | 4x4 | Stores 400 units of materials, fuel, and tools. |
| **Storage Barn** | 40 logs, 20 stone | 3x3 | Stores 600 units of food, tools, and fuel. |
| **Dirt Road** | free | 1 tile | Settlers walk 1.5x faster on it. |
| **Stone Road** | 1 stone per tile | 1 tile | Settlers walk 2x faster on it. |


Buildings go on grass only. You cannot build on forest, water, or rock, or on top of another building or road. Buildings also block walking, so settlers path around them. Settlers standing on a spot do not stop you building there; they just walk away.

The build menu is grouped into Roads, Storage, Housing, Food, Resources and Industry.

Roads go on open grass only: not on forest (trees), water, rock, buildings, or construction sites. Drag from the first tile to the last; the road runs straight, then turns once in an L-shape. Tiles you cannot place are skipped. Stone roads need 1 stone per tile placed, and if you run short only the affordable tiles are built.

Demolishing (`X`, then left-click) removes a construction site, a building, or a road tile. A site returns all its delivered materials. A finished building returns half its cost to storage, and anything stored inside it (goods in its storage, output, input or household) is moved to other storage. Residents become homeless and are rehoused in an empty house if one exists. Workers become laborers. Roads return nothing.

## Your first hour in the game

### 1. Look around

Pan with `WASD` and zoom with the mouse wheel. Find the forest, which is dark green, and the open grass, which is light green.

### 2. Build a house

Click **House** in the build menu at the bottom left. The hint line at the top shows what you are placing and why a spot is not valid. Move the cursor over open grass. A green box means you can place it here. A red box means you cannot, with the reason shown. Left-click to place it.

Placing a building costs nothing right away. It becomes a construction site that needs materials first: laborers carry the cost from storage to the site (the site shows an orange materials bar), and once everything has arrived the builders start work (the white progress bar). A house takes 20 builder-seconds, so two builders finish it in about 10 seconds plus walking time. More builders build faster; with 0 builders nothing is built. You can place a building even when you lack the logs; the site just waits for materials.

To cancel a site, right-click it or select it and press **Cancel construction** or `Delete`. Materials already delivered go back to storage.

When it is done, a toast appears in the top right. A homeless family moves in automatically: one couple (and their children) per empty house, or two single adults who pair up. Houses are the brake on growth: with no free house, nobody new moves in.

### 3. Build a Forester's Lodge near the forest

Click **Forester's Lodge**, then place it on grass close to the forest. While placing, and when the building is selected, a translucent circle shows its work radius. Foresters only work inside that circle. Gatherers and hunters depend on how much forest is inside it, and the dock, quarry, and mine show a hint when their terrain rule is not met.

### 4. Staff the lodge

You never assign settlers one by one. A finished workplace asks for its full number of workers and the town fills it from the laborers automatically. Select the building to change its **Desired workers** with `-` and `+` in the info panel.

You can also open the **Professions** panel (`P`). Each row shows `assigned / max` for a profession, where max is the total slots in your built workplaces. `+` turns the nearest laborer into that profession, and `-` sends the farthest one back to being a laborer. Builders have no maximum; raise them to build faster.

Foresters cut mature trees and plant saplings, then goods go to the output buffer and back to storage. Logs appear in the top bar. Laborers who have nothing to deliver also empty full workplace buffers into storage and wait near the storage buildings.

### 5. Build a crop field and staff it

Click a **Crop Field** size in the build menu (or press `R` while placing to cycle 4x4, 6x6 and 8x8) and place it on open grass. Up to 4 laborers become farmers once it is built, as in step 4. Settlers can walk across fields.

A field follows the year. In spring farmers plow and plant empty cells one by one. Crops grow through summer (cabbage ripens in late summer, wheat in early autumn). In autumn farmers harvest ripe cells, each giving 2 of the crop, which laborers and farmers carry to storage. At the start of winter every cell still in the ground is lost to frost, with a toast. Fields hold more cells than a few farmers can work, so match the size to your farmers.

Select a field to see its crop and planted, ripe and harvested counts, and to pick Wheat or Cabbage. A change applies next spring, except while nothing is planted yet. A field built after spring waits for the next spring.

Settlers eat from their house when they are hungry (60 or more), taking the most plentiful kind first. A hungry settler who is away walks home to eat. Homeless settlers eat directly at a storage building. If their house has no food, they starve and their health falls.

Each house holds up to 30 food and 20 firewood. When food or firewood falls below half, a resident fetches up to 10 from the nearest storage between tasks, one kind per trip. A house far from storage takes longer to restock, so keep houses and storage close. A house that holds 3 or more kinds of food gives its residents a small health bonus; a house with only 1 kind gives a small penalty.

### 6. Keep an eye on your settlers

Select a settler to see its needs:

- **Hunger** rises over time. Settlers eat from their house when it passes 60 and they are home. At 85 they drop their work and go eat.
- **Rest** drains while they are awake. At 25 they walk home to rest until they reach 95. A settler without a home cannot recover rest.
- **Warmth** only matters in winter (see below).
- **Health** falls when settlers starve, get cold, or have no home. It recovers when they are fed and housed. At 0 a settler dies.

Settlers age one year per game year. Children (under 10) do not work, haul or build; they stay at home and eat from the household, so a baby boom costs food before it adds labor. At 10 they become laborers. From 60 they are elders: they work at 70% speed and have a rising chance each month to die of old age, certain by 80. Each month a couple with room in their house, at least 10 food there and a mother under 50 has a 25% chance of a child. Grown children pair up with unrelated singles and move into an empty house, or stay with their parents until one is free. The top bar shows `Pop N (adults, children, elders)`; select a settler to see name, age, stage and partner, and a house to see who lives there.

### 7. Prepare for winter

The year has 12 months grouped into four seasons: spring, summer, autumn, and winter. Each month lasts 60 seconds at normal speed, so one season is roughly 3 minutes.

- **Summer:** crops grow. Stock up on goods you can gather.
- **Winter:** fields lie empty, and anything unharvested is lost. Unheated settlers lose warmth, and then health.

To keep settlers warm in winter, each house with residents burns 1 firewood every 20 seconds from its own stock. Settlers outside lose warmth; below 40 they go home to warm up (interrupting work) until it is back above 90, as long as the house is heated. Without firewood, warmth drops to 0 and health falls. Build a **Woodcutter** before winter: it turns logs into firewood, which laborers carry to storage and residents carry home. The toast for "Winter" is a reminder.

### 8. Equip your workers

Every settler with a job (and every builder) needs a tool. A tool wears out after about one year of continuous work. Without one, work takes twice as long. A settler without a tool fetches one from storage between tasks. A **Blacksmith** makes tools from iron and logs, so mine some iron. The info panel shows the settler's tool state, and a house's panel shows its food, firewood, and food kinds.

The top bar shows the current month and year, for example "Mid Summer, Year 2".

### 9. Save and reload

Press `F5` or click **Save**. Press `F9` or click **Load** to go back to the saved state. Your settlers (with ages, families and homes), their tools, professions, buildings, household stocks, construction deliveries and progress, and time all come back. **New game** starts a fresh settlement and leaves your save file alone.

## Tips

- Keep enough laborers: they carry all construction materials and also haul workplace output. Too many jobs leaves nobody to deliver.
- Build houses early: a couple can only have children in a house, and each new family needs an empty one.
- Place fields and workplaces close to houses to shorten settler trips.
- Lay roads between houses, storage and workplaces. Dirt roads cost nothing, stone roads cost one stone per tile, and settlers walk faster and prefer them. Demolish a building you no longer need with `X` to recover half its cost.
- If all storage is full, workplaces fill up and stop working. Build another stockpile or barn.
- Keep a woodcutter running and a blacksmith supplied with iron before the first winter.
- Watch the firewood count in winter, and the log count when you build.
- Use the info panel to check why a settler is idle. The task line shows **paused** when the settler is resting or warming up at home.
- Trees grow one stage (sapling, young, mature) every 2 months, except in winter. Only mature trees can be cut. A cut tile becomes grass, and foresters replant it, so keep a lodge staffed to keep logs coming.

## Known limits (for now)

- The balance (costs, rates, timings) is a first draft and will change.
- There is no main menu or settings screen.
- Cabbage and wheat processing are not produced yet. Stone is used only for the barn, mine, and blacksmith.
- Save files from older versions of the game may not load after changes.
