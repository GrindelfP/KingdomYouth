class_name BuildController
extends Node2D

const VALID_COLOR := Color(0.3, 0.9, 0.3, 0.4)
const INVALID_COLOR := Color(0.9, 0.2, 0.2, 0.4)

var building_defs: Array[BuildingDef] = [load("res://resources/buildings/storage_barn.tres")]
var _world: WorldGrid
var _feedback: Label
var _placing := false
var _selected := 0
var _hover := Vector2i.ZERO


func _ready() -> void:
	_world = get_parent()
	_feedback = get_node("../UI/Feedback")


func _process(_delta: float) -> void:
	if _placing:
		_hover = _world.world_to_grid(get_global_mouse_position())
	queue_redraw()
	_update_feedback()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("build_toggle"):
		_placing = not _placing
	elif event.is_action_pressed("build_cycle"):
		_selected = (_selected + 1) % building_defs.size()
	elif event.is_action_pressed("cancel_build") and _placing:
		_placing = false
	elif event.is_action_pressed("place_building") and _placing:
		_hover = _world.world_to_grid(get_global_mouse_position())
		try_place(selected_def(), _hover)
		get_viewport().set_input_as_handled()


func is_placing() -> bool:
	return _placing


func selected_def() -> BuildingDef:
	return building_defs[_selected]


func get_placement_error(def: BuildingDef, origin: Vector2i) -> String:
	var cells := def.get_cells(origin)
	for cell in cells:
		if not _world.is_in_bounds(cell):
			return "outside the map"
	for cell in cells:
		if _world.is_occupied(cell):
			return "tile is occupied"
		if not _world.is_buildable(cell):
			return "terrain is not buildable"
	if not ResourceStockpile.can_afford(def.cost):
		return "not enough resources"
	return ""


func try_place(def: BuildingDef, origin: Vector2i) -> bool:
	if get_placement_error(def, origin) != "":
		return false
	ResourceStockpile.spend(def.cost)
	_world.set_occupied(def.get_cells(origin), true)
	var site := ConstructionSite.new()
	add_child(site)
	site.setup(_world, def, origin)
	site.completed.connect(_on_site_completed)
	return true


func _on_site_completed(site: ConstructionSite) -> void:
	var building := Building.new()
	add_child(building)
	building.setup(_world, site.def, site.origin)
	site.queue_free()


func _update_feedback() -> void:
	var def := selected_def()
	if not _placing:
		_feedback.text = "[B] Build: %s  [Tab] next building" % def.display_name
		return
	var reason := get_placement_error(def, _hover)
	_feedback.text = "Build %s: %s" % [def.display_name, reason if reason != "" else "click to place, Esc to cancel"]


func _draw() -> void:
	if not _placing:
		return
	var def := selected_def()
	var color := VALID_COLOR if get_placement_error(def, _hover) == "" else INVALID_COLOR
	var top_left := to_local(_world.get_cell_rect(_hover).position)
	draw_rect(Rect2(top_left, Vector2(def.footprint) * _world.get_tile_size()), color)
