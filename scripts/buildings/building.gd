class_name Building
extends Structure

const BUILDING_COLOR := Color(0.45, 0.3, 0.15)
const OUTPUT_CAPACITY := 20
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


func setup(world: WorldGrid, building_def: BuildingDef, grid_origin: Vector2i) -> void:
	bind_to_grid(world, building_def, grid_origin)
	if def.is_storage():
		storage = Inventory.new(def.storage_capacity)
		ResourceStockpile.register_storage(self)
	if def.job:
		output = Inventory.new(OUTPUT_CAPACITY)
		desired_workers = def.job.slots
		if def.job.has_inputs():
			input = Inventory.new(INPUT_CAPACITY)
	if def.housing_capacity > 0:
		household = Inventory.new(HOUSEHOLD_CAPACITY)
	queue_redraw()


func _exit_tree() -> void:
	if storage:
		ResourceStockpile.unregister_storage(self)


func job_def() -> JobDef:
	return def.job


func is_storage() -> bool:
	return storage != null


func is_output_blocked() -> bool:
	if output == null:
		return false
	return output.free_space() < def.job.output_total() and ResourceStockpile.find_storages(def.job.primary_output(), get_center_cell()).is_empty()


func forest_cell_count() -> int:
	return _world.count_terrain_in_radius("forest", get_work_center(), def.job.work_radius)


func work_efficiency() -> float:
	var job := def.job
	var efficiency := 1.0
	if job.density_cells > 0:
		efficiency = minf(float(forest_cell_count()) / job.density_cells, 1.0)
	if TimeManager.is_cold():
		efficiency *= job.winter_factor
	if job.seasonal:
		efficiency *= TimeManager.food_multiplier()
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


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, _size), BUILDING_COLOR)
