class_name ConstructionSite
extends Node2D

signal completed(site: ConstructionSite)

const SITE_COLOR := Color(0.55, 0.5, 0.4, 0.8)
const PROGRESS_COLOR := Color.WHITE
const PROGRESS_HEIGHT := 4.0

var def: BuildingDef
var origin: Vector2i
var _progress := 0.0
var _size: Vector2


func setup(world: WorldGrid, building_def: BuildingDef, grid_origin: Vector2i) -> void:
	def = building_def
	origin = grid_origin
	global_position = world.get_cell_rect(origin).position
	_size = Vector2(def.footprint) * world.get_tile_size()


func _process(delta: float) -> void:
	_progress += delta
	queue_redraw()
	if _progress >= def.build_time:
		set_process(false)
		completed.emit(self)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, _size), SITE_COLOR)
	var ratio := clampf(_progress / def.build_time, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, Vector2(_size.x * ratio, PROGRESS_HEIGHT)), PROGRESS_COLOR)
