class_name Building
extends Structure

signal crops_lost(count: int)

const BUILDING_COLOR := Color(0.45, 0.3, 0.15)
const OUTPUT_CAPACITY := 20
const FIELD_OUTPUT_CAPACITY := 40
const FIELD_UPDATE_INTERVAL := 0.25
const FIELD_FENCE_COLOR := Color(0.36, 0.24, 0.12)
const FIELD_COLORS := {
	CropField.CellState.EMPTY: Color(0.5, 0.42, 0.26),
	CropField.CellState.PLOWED: Color(0.33, 0.22, 0.12),
	CropField.CellState.PLANTED: Color(0.33, 0.22, 0.12),
	CropField.CellState.GROWING: Color(0.3, 0.21, 0.12),
	CropField.CellState.RIPE: Color(0.3, 0.21, 0.12),
	CropField.CellState.HARVESTED: Color(0.55, 0.47, 0.28),
}
const SPROUT_COLOR := Color(0.45, 0.75, 0.3)
const GROWING_COLOR := Color(0.25, 0.6, 0.2)
const RIPE_COLORS := {&"wheat": Color(0.92, 0.78, 0.25), &"cabbage": Color(0.62, 0.82, 0.4)}
const STUBBLE_COLOR := Color(0.72, 0.62, 0.35)
const INPUT_CAPACITY := 20
const BATCHES_PER_TRIP := 5
const HOUSEHOLD_CAPACITY := 50
const FOOD_TARGET := 30
const FIREWOOD_TARGET := 20
const RESTOCK_TRIP := Hauler.CARRY_SIZE
const FUEL_ID := &"firewood"
const TOOL_ID := &"tools"
const DIET_VARIETY_KINDS := 3

var workers: Array[Settler] = []
var residents: Array[Settler] = []
var birth_cooldown := 0.0
var heat_left := 0.0
var desired_workers := 0
var output_claimed := 0
var storage: Inventory
var output: Inventory
var input: Inventory
var household: Inventory
var restock_claimed := false
var field: CropField
var _field_timer := 0.0


func setup(world: WorldGrid, building_def: BuildingDef, grid_origin: Vector2i) -> void:
	bind_to_grid(world, building_def, grid_origin)
	if def.is_storage():
		storage = Inventory.new(def.storage_capacity)
		ResourceStockpile.register_storage(self)
	if def.job:
		output = Inventory.new(FIELD_OUTPUT_CAPACITY if def.is_field() else OUTPUT_CAPACITY)
		desired_workers = def.job.slots
		if def.job.has_inputs():
			input = Inventory.new(INPUT_CAPACITY)
	if def.housing_capacity > 0:
		household = Inventory.new(HOUSEHOLD_CAPACITY)
	if def.is_field():
		field = CropField.new(def.footprint.x)
		field.cell_changed.connect(_on_field_cell_changed)
		field.cells_reloaded.connect(queue_redraw)
		field.crop_changed.connect(queue_redraw)
		world.set_open(def.get_cells(origin), true)
		TimeManager.season_changed.connect(_on_season_changed)
		TimeManager.month_changed.connect(_on_month_changed)
	queue_redraw()


func _exit_tree() -> void:
	if storage:
		ResourceStockpile.unregister_storage(self)
	if field:
		TimeManager.season_changed.disconnect(_on_season_changed)
		TimeManager.month_changed.disconnect(_on_month_changed)


func _process(delta: float) -> void:
	if field == null:
		return
	_field_timer += delta
	if _field_timer >= FIELD_UPDATE_INTERVAL:
		_field_timer = 0.0
		field.update()


func get_output_id() -> StringName:
	return field.crop if field else def.job.primary_output()


func field_cell_to_grid(cell: Vector2i) -> Vector2i:
	return origin + cell


func grid_to_field_cell(grid_pos: Vector2i) -> Vector2i:
	return grid_pos - origin


func job_def() -> JobDef:
	return def.job


func is_storage() -> bool:
	return storage != null


func is_output_blocked() -> bool:
	if output == null:
		return false
	return output.free_space() < def.job.output_total() and ResourceStockpile.find_storages(get_output_id(), get_center_cell()).is_empty()


func forest_cell_count() -> int:
	return _world.count_terrain_in_radius("forest", get_work_center(), def.job.work_radius)


func work_efficiency() -> float:
	var job := def.job
	var efficiency := 1.0
	if job.density_cells > 0:
		efficiency = minf(float(forest_cell_count()) / job.density_cells, 1.0)
	if TimeManager.is_cold():
		efficiency *= job.winter_factor
	return efficiency


func has_batch() -> bool:
	if input == null:
		return true
	for entry in def.job.inputs:
		if input.get_amount(StringName(entry["id"])) < int(entry["amount"]):
			return false
	return true


func missing_input() -> StringName:
	if input == null:
		return &""
	var worst := &""
	var worst_ratio := INF
	for entry in def.job.inputs:
		var id := StringName(entry["id"])
		var ratio := float(input.get_amount(id)) / int(entry["amount"])
		if ratio < 1.0 and ratio < worst_ratio:
			worst = id
			worst_ratio = ratio
	return worst


func input_trip_amount(id: StringName) -> int:
	var wanted := def.job.input_amount(id) * BATCHES_PER_TRIP - input.get_amount(id)
	return clampi(mini(wanted, input.free_space()), 0, Hauler.CARRY_SIZE)


func consume_batch() -> bool:
	if not has_batch():
		return false
	for entry in def.job.inputs:
		input.take(StringName(entry["id"]), int(entry["amount"]))
	return true


func food_stock() -> int:
	return household.category_total(ResourceDef.Category.FOOD) if household else 0


func firewood_stock() -> int:
	return household.get_amount(FUEL_ID) if household else 0


func needs_food() -> bool:
	return household != null and food_stock() * 2 < FOOD_TARGET


func needs_firewood() -> bool:
	return household != null and firewood_stock() * 2 < FIREWOOD_TARGET


func diet_kinds() -> int:
	return household.kind_count(ResourceDef.Category.FOOD) if household else 0


func is_heated() -> bool:
	return heat_left > 0.0


func has_free_housing() -> bool:
	return def.housing_capacity > 0 and residents.size() < def.housing_capacity


func has_free_job_slot() -> bool:
	return def.job != null and workers.size() < def.job.slots


func _on_field_cell_changed(_cell: Vector2i) -> void:
	queue_redraw()


func _on_month_changed(_month: int) -> void:
	field.update()
	queue_redraw()


func _on_season_changed(season: int) -> void:
	if season == TimeManager.Season.SPRING:
		field.begin_season()
	elif season == TimeManager.Season.WINTER:
		var lost := field.frost()
		if lost > 0:
			crops_lost.emit(lost)


func _draw() -> void:
	if field:
		_draw_field()
		return
	draw_rect(Rect2(Vector2.ZERO, _size), BUILDING_COLOR)


func _draw_field() -> void:
	var tile := _world.get_tile_size()
	for y in field.size:
		for x in field.size:
			var cell := Vector2i(x, y)
			var top_left := Vector2(cell) * tile
			var state := field.get_state(cell)
			draw_rect(Rect2(top_left, tile), FIELD_COLORS[state])
			match state:
				CropField.CellState.PLOWED, CropField.CellState.PLANTED, CropField.CellState.GROWING, CropField.CellState.RIPE:
					for row in 3:
						var line_y := top_left.y + tile.y * (row + 0.5) / 3.0
						draw_line(Vector2(top_left.x + 1.0, line_y), Vector2(top_left.x + tile.x - 1.0, line_y), Color(0.2, 0.13, 0.07), 1.0)
			_draw_crop(top_left + tile * 0.5, tile, state, field.get_growth(cell))
	draw_rect(Rect2(Vector2.ZERO, _size), FIELD_FENCE_COLOR, false, 2.0)


func _draw_crop(center: Vector2, tile: Vector2, state: int, growth: float) -> void:
	match state:
		CropField.CellState.PLANTED:
			draw_circle(center, tile.x * 0.1, SPROUT_COLOR)
		CropField.CellState.GROWING:
			draw_circle(center, tile.x * lerpf(0.15, 0.35, growth), GROWING_COLOR)
		CropField.CellState.RIPE:
			var color: Color = RIPE_COLORS[field.crop]
			if field.crop == &"cabbage":
				draw_circle(center, tile.x * 0.38, color)
			else:
				draw_rect(Rect2(center - tile * 0.38, tile * 0.76), color)
		CropField.CellState.HARVESTED:
			draw_line(center - tile * 0.25, center + tile * 0.25, STUBBLE_COLOR, 1.5)
			draw_line(center + Vector2(-0.25, 0.25) * tile, center + Vector2(0.25, -0.25) * tile, STUBBLE_COLOR, 1.5)

