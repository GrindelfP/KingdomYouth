class_name RoadLayer
extends Node2D

const TEXTURE: Texture2D = preload("res://assets/art/terrain/roads.png")
const TILE := 32
const NEIGHBOR_BITS := {Vector2i(0, -1): 1, Vector2i(1, 0): 2, Vector2i(0, 1): 4, Vector2i(-1, 0): 8}

var season := 0:
	set(value):
		season = value
		queue_redraw()

var _world: WorldGrid


func setup(world: WorldGrid) -> void:
	_world = world
	world.roads_changed.connect(_on_roads_changed)


func _draw() -> void:
	if _world == null:
		return
	for grid_pos in _world.get_road_cells():
		var rect := _world.get_cell_rect(grid_pos)
		var row := season * 2 + (1 if _world.get_road(grid_pos) == WorldGrid.Road.STONE else 0)
		var source := Rect2(_neighbor_mask(grid_pos) * TILE, row * TILE, TILE, TILE)
		draw_texture_rect_region(TEXTURE, Rect2(to_local(rect.position), rect.size), source)


func _neighbor_mask(grid_pos: Vector2i) -> int:
	var mask := 0
	for offset in NEIGHBOR_BITS:
		if _world.get_road(grid_pos + offset) != WorldGrid.Road.NONE:
			mask |= NEIGHBOR_BITS[offset]
	return mask


func _on_roads_changed(_grid_pos: Vector2i) -> void:
	queue_redraw()
