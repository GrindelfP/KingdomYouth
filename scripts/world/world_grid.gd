class_name WorldGrid
extends Node2D

signal map_generated
signal walkability_changed(grid_pos: Vector2i)
signal trees_changed(grid_pos: Vector2i)
signal trees_reloaded

enum Terrain { GRASS, FOREST, WATER, ROCK }

const MAP_RECT := Rect2i(Vector2i.ZERO, Vector2i(64, 64))
const TERRAIN_SOURCE_ID := 0
const MAP_SEED := 1337
const TERRAIN_CODES := {"grass": "G", "forest": "F", "water": "W", "rock": "R"}
const TERRAIN_BY_CODE := {"G": Terrain.GRASS, "F": Terrain.FOREST, "W": Terrain.WATER, "R": Terrain.ROCK}
const ELEVATION_FREQUENCY := 0.05
const MOISTURE_FREQUENCY := 0.08
const WATER_LEVEL := -0.25
const ROCK_LEVEL := 0.4
const FOREST_LEVEL := 0.15
const STAGE_SAPLING := 0
const STAGE_YOUNG := 1
const STAGE_MATURE := 2
const MONTHS_PER_STAGE := 2
const NO_TREE := -1
const ANY_STAGE := -2

var _occupied: Dictionary = {}
var _trees: Dictionary = {}
var _tree_age: Dictionary = {}

var terrain: TileMapLayer:
	get:
		return $Terrain


func _ready() -> void:
	add_to_group("world")
	TimeManager.month_changed.connect(_on_month_changed)
	_generate_map()
	_reset_trees()
	map_generated.emit()


func _on_month_changed(_month: int) -> void:
	if TimeManager.is_cold():
		return
	for grid_pos in _tree_age.keys():
		_tree_age[grid_pos] += 1
		if _tree_age[grid_pos] >= MONTHS_PER_STAGE:
			_tree_age[grid_pos] = 0
			_trees[grid_pos] += 1
			if _trees[grid_pos] >= STAGE_MATURE:
				_tree_age.erase(grid_pos)
			trees_changed.emit(grid_pos)


func is_in_bounds(grid_pos: Vector2i) -> bool:
	return MAP_RECT.has_point(grid_pos)


func is_walkable(grid_pos: Vector2i) -> bool:
	return _get_flag(grid_pos, "walkable") and not is_occupied(grid_pos)


func is_buildable(grid_pos: Vector2i) -> bool:
	return _get_flag(grid_pos, "buildable") and not is_occupied(grid_pos)


func is_occupied(grid_pos: Vector2i) -> bool:
	return _occupied.has(grid_pos)


func clear_occupancy() -> void:
	var previous := _occupied.keys()
	_occupied.clear()
	for grid_pos in previous:
		walkability_changed.emit(grid_pos)


func set_occupied(grid_positions: Array[Vector2i], occupied: bool) -> void:
	for grid_pos in grid_positions:
		if occupied:
			_occupied[grid_pos] = true
		else:
			_occupied.erase(grid_pos)
		walkability_changed.emit(grid_pos)


static func cell_to_json(grid_pos: Vector2i) -> Array:
	return [grid_pos.x, grid_pos.y]


static func cell_from_json(data: Array) -> Vector2i:
	return Vector2i(int(data[0]), int(data[1]))


func to_save_data() -> Dictionary:
	var codes := PackedStringArray()
	var trees := []
	for x in range(MAP_RECT.position.x, MAP_RECT.end.x):
		for y in range(MAP_RECT.position.y, MAP_RECT.end.y):
			codes.append(TERRAIN_CODES[get_terrain_name(Vector2i(x, y))])
	for grid_pos in _tree_age:
		trees.append([grid_pos.x, grid_pos.y, _trees[grid_pos], _tree_age[grid_pos]])
	return {"terrain": "".join(codes), "trees": trees}


func from_save_data(data: Dictionary) -> void:
	var codes: String = data["terrain"]
	var index := 0
	for x in range(MAP_RECT.position.x, MAP_RECT.end.x):
		for y in range(MAP_RECT.position.y, MAP_RECT.end.y):
			var terrain_type: Terrain = TERRAIN_BY_CODE[codes[index]]
			terrain.set_cell(Vector2i(x, y), TERRAIN_SOURCE_ID, Vector2i(terrain_type, 0))
			index += 1
	_reset_trees()
	for entry in data["trees"]:
		var grid_pos := Vector2i(int(entry[0]), int(entry[1]))
		_trees[grid_pos] = int(entry[2])
		_tree_age[grid_pos] = int(entry[3])
	trees_reloaded.emit()


func get_terrain_name(grid_pos: Vector2i) -> String:
	var data := terrain.get_cell_tile_data(grid_pos)
	return data.get_custom_data("terrain") if data else ""


func get_map_bounds() -> Rect2i:
	return MAP_RECT


func get_tile_size() -> Vector2:
	return Vector2(terrain.tile_set.tile_size)


func get_world_bounds() -> Rect2:
	var top_left := terrain.to_global(Vector2(MAP_RECT.position) * get_tile_size())
	return Rect2(top_left, Vector2(MAP_RECT.size) * get_tile_size())


func get_tree_stage(grid_pos: Vector2i) -> int:
	return _trees.get(grid_pos, NO_TREE)


func has_mature_tree(grid_pos: Vector2i) -> bool:
	return get_tree_stage(grid_pos) == STAGE_MATURE


func get_tree_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	cells.assign(_trees.keys())
	return cells


func cut_tree(grid_pos: Vector2i) -> bool:
	if not has_mature_tree(grid_pos):
		return false
	_trees.erase(grid_pos)
	_tree_age.erase(grid_pos)
	terrain.set_cell(grid_pos, TERRAIN_SOURCE_ID, Vector2i(Terrain.GRASS, 0))
	trees_changed.emit(grid_pos)
	return true


func can_plant(grid_pos: Vector2i) -> bool:
	return is_in_bounds(grid_pos) and not is_occupied(grid_pos) and get_terrain_name(grid_pos) == "grass"


func plant_sapling(grid_pos: Vector2i) -> bool:
	if not can_plant(grid_pos):
		return false
	terrain.set_cell(grid_pos, TERRAIN_SOURCE_ID, Vector2i(Terrain.FOREST, 0))
	_trees[grid_pos] = STAGE_SAPLING
	_tree_age[grid_pos] = 0
	trees_changed.emit(grid_pos)
	return true


func get_cells_in_radius(center: Vector2, radius: float) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var reach := ceili(radius)
	var base := Vector2i(center.floor())
	for x in range(base.x - reach, base.x + reach + 1):
		for y in range(base.y - reach, base.y + reach + 1):
			var grid_pos := Vector2i(x, y)
			if is_in_bounds(grid_pos) and Vector2(grid_pos).distance_to(center) <= radius:
				cells.append(grid_pos)
	return cells


func count_terrain_in_radius(terrain_name: String, center: Vector2, radius: float) -> int:
	var count := 0
	for grid_pos in get_cells_in_radius(center, radius):
		if get_terrain_name(grid_pos) == terrain_name:
			count += 1
	return count


func count_trees_in_radius(center: Vector2, radius: float, stage := ANY_STAGE) -> int:
	var count := 0
	for grid_pos in get_cells_in_radius(center, radius):
		var tree_stage := get_tree_stage(grid_pos)
		if tree_stage != NO_TREE and (stage == ANY_STAGE or tree_stage == stage):
			count += 1
	return count


func get_cell_rect(grid_pos: Vector2i) -> Rect2:
	var tile_size := get_tile_size()
	return Rect2(grid_to_world(grid_pos) - tile_size / 2.0, tile_size)


func world_to_grid(world_pos: Vector2) -> Vector2i:
	return terrain.local_to_map(terrain.to_local(world_pos))


func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return terrain.to_global(terrain.map_to_local(grid_pos))


func _reset_trees() -> void:
	_trees.clear()
	_tree_age.clear()
	for x in range(MAP_RECT.position.x, MAP_RECT.end.x):
		for y in range(MAP_RECT.position.y, MAP_RECT.end.y):
			var grid_pos := Vector2i(x, y)
			if get_terrain_name(grid_pos) == "forest":
				_trees[grid_pos] = STAGE_MATURE


func _get_flag(grid_pos: Vector2i, layer_name: String) -> bool:
	var data := terrain.get_cell_tile_data(grid_pos)
	return data != null and data.get_custom_data(layer_name)


func _generate_map() -> void:
	var elevation := FastNoiseLite.new()
	elevation.seed = MAP_SEED
	elevation.frequency = ELEVATION_FREQUENCY

	var moisture := FastNoiseLite.new()
	moisture.seed = MAP_SEED + 1
	moisture.frequency = MOISTURE_FREQUENCY

	for x in range(MAP_RECT.position.x, MAP_RECT.end.x):
		for y in range(MAP_RECT.position.y, MAP_RECT.end.y):
			var terrain_type := _pick_terrain(
				elevation.get_noise_2d(x, y),
				moisture.get_noise_2d(x, y),
			)
			terrain.set_cell(Vector2i(x, y), TERRAIN_SOURCE_ID, Vector2i(terrain_type, 0))


func _pick_terrain(elevation: float, moisture: float) -> Terrain:
	if elevation < WATER_LEVEL:
		return Terrain.WATER
	if elevation > ROCK_LEVEL:
		return Terrain.ROCK
	if moisture > FOREST_LEVEL:
		return Terrain.FOREST
	return Terrain.GRASS
