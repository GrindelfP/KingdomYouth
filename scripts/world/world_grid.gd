class_name WorldGrid
extends Node2D

enum Terrain { GRASS, FOREST, WATER, ROCK }

const MAP_RECT := Rect2i(Vector2i.ZERO, Vector2i(64, 64))
const TERRAIN_SOURCE_ID := 0
const MAP_SEED := 1337
const ELEVATION_FREQUENCY := 0.05
const MOISTURE_FREQUENCY := 0.08
const WATER_LEVEL := -0.25
const ROCK_LEVEL := 0.4
const FOREST_LEVEL := 0.15

@onready var terrain: TileMapLayer = $Terrain


func _ready() -> void:
	_generate_map()


func is_in_bounds(grid_pos: Vector2i) -> bool:
	return MAP_RECT.has_point(grid_pos)


func is_walkable(grid_pos: Vector2i) -> bool:
	return _get_flag(grid_pos, "walkable")


func is_buildable(grid_pos: Vector2i) -> bool:
	return _get_flag(grid_pos, "buildable")


func get_terrain_name(grid_pos: Vector2i) -> String:
	var data := terrain.get_cell_tile_data(grid_pos)
	return data.get_custom_data("terrain") if data else ""


func get_map_bounds() -> Rect2i:
	return MAP_RECT


func get_world_bounds() -> Rect2:
	var tile_size := Vector2(terrain.tile_set.tile_size)
	var top_left := terrain.to_global(Vector2(MAP_RECT.position) * tile_size)
	return Rect2(top_left, Vector2(MAP_RECT.size) * tile_size)


func world_to_grid(world_pos: Vector2) -> Vector2i:
	return terrain.local_to_map(terrain.to_local(world_pos))


func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return terrain.to_global(terrain.map_to_local(grid_pos))


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
