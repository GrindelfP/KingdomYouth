class_name Building
extends Structure

const BUILDING_COLOR := Color(0.45, 0.3, 0.15)
const OUTPUT_CAPACITY := 20

var workers: Array[Settler] = []
var residents: Array[Settler] = []
var birth_cooldown := 0.0
var heat_left := 0.0
var desired_workers := 0
var output_claimed := 0
var storage: Inventory
var output: Inventory


func setup(world: WorldGrid, building_def: BuildingDef, grid_origin: Vector2i) -> void:
	bind_to_grid(world, building_def, grid_origin)
	if def.is_storage():
		storage = Inventory.new(def.storage_capacity)
		ResourceStockpile.register_storage(self)
	if def.job:
		output = Inventory.new(OUTPUT_CAPACITY)
		desired_workers = def.job.slots
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


func is_heated() -> bool:
	return heat_left > 0.0


func has_free_housing() -> bool:
	return def.housing_capacity > 0 and residents.size() < def.housing_capacity


func has_free_job_slot() -> bool:
	return def.job != null and workers.size() < def.job.slots


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, _size), BUILDING_COLOR)
