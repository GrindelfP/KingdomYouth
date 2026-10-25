class_name Building
extends Node2D

const BUILDING_COLOR := Color(0.45, 0.3, 0.15)

var def: BuildingDef
var origin: Vector2i
var _size: Vector2


func setup(world: WorldGrid, building_def: BuildingDef, grid_origin: Vector2i) -> void:
	def = building_def
	origin = grid_origin
	global_position = world.get_cell_rect(origin).position
	_size = Vector2(def.footprint) * world.get_tile_size()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, _size), BUILDING_COLOR)
