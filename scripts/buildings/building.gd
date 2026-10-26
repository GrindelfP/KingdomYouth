class_name Building
extends Node2D

const BUILDING_COLOR := Color(0.45, 0.3, 0.15)
const OUTPUT_CAPACITY := 20
const ACCESS_OFFSETS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

var def: BuildingDef
var origin: Vector2i
var workers: Array[Settler] = []
var residents: Array[Settler] = []
var birth_cooldown := 0.0
var heat_left := 0.0
var storage: Inventory
var output: Inventory
var _world: WorldGrid
var _size: Vector2


func setup(world: WorldGrid, building_def: BuildingDef, grid_origin: Vector2i) -> void:
	_world = world
	def = building_def
	origin = grid_origin
	global_position = world.get_cell_rect(origin).position
	_size = Vector2(def.footprint) * world.get_tile_size()
	if def.is_storage():
		storage = Inventory.new(def.storage_capacity)
		ResourceStockpile.register_storage(self)
	if def.job:
		output = Inventory.new(OUTPUT_CAPACITY)
	queue_redraw()


func _exit_tree() -> void:
	if storage:
		ResourceStockpile.unregister_storage(self)


func occupies(grid_pos: Vector2i) -> bool:
	return def.get_cells(origin).has(grid_pos)


func get_center_cell() -> Vector2i:
	return origin + (def.footprint - Vector2i.ONE) / 2


func get_access_cells() -> Array[Vector2i]:
	var footprint_cells := def.get_cells(origin)
	var cells: Array[Vector2i] = []
	for cell in footprint_cells:
		for offset in ACCESS_OFFSETS:
			var neighbour: Vector2i = cell + offset
			if not footprint_cells.has(neighbour) and not cells.has(neighbour) and _world.is_walkable(neighbour):
				cells.append(neighbour)
	return cells


func job_def() -> JobDef:
	return def.job


func is_storage() -> bool:
	return storage != null


func is_output_blocked() -> bool:
	if output == null:
		return false
	return output.free_space() < def.job.output_amount and ResourceStockpile.find_storages(def.job.output_id, get_center_cell()).is_empty()


func is_heated() -> bool:
	return heat_left > 0.0


func has_free_housing() -> bool:
	return def.housing_capacity > 0 and residents.size() < def.housing_capacity


func has_free_job_slot() -> bool:
	return def.job != null and workers.size() < def.job.slots


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, _size), BUILDING_COLOR)
