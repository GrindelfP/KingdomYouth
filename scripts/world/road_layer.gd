class_name RoadLayer
extends Node2D

const DIRT_COLOR := Color(0.55, 0.42, 0.25)
const STONE_COLOR := Color(0.72, 0.72, 0.68)

var _world: WorldGrid


func setup(world: WorldGrid) -> void:
	_world = world
	world.roads_changed.connect(_on_roads_changed)


func _draw() -> void:
	if _world == null:
		return
	for grid_pos in _world.get_road_cells():
		var rect := _world.get_cell_rect(grid_pos)
		var color := STONE_COLOR if _world.get_road(grid_pos) == WorldGrid.Road.STONE else DIRT_COLOR
		draw_rect(Rect2(to_local(rect.position), rect.size), color)


func _on_roads_changed(_grid_pos: Vector2i) -> void:
	queue_redraw()
