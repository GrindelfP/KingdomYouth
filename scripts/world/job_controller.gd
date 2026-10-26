class_name JobController
extends Node

signal selection_changed

const PICK_RADIUS := 12.0

var _world: WorldGrid
var _buildings: BuildController
var _settlers: SettlerManager
var _selected_settler: Settler
var _selected_building: Building
var _selected_site: ConstructionSite


func _ready() -> void:
	_world = get_parent()
	_buildings = get_parent().get_node("Buildings")
	_settlers = get_parent().get_node("Settlers")
	selection_changed.connect(_sync_highlight)


func get_selected_settler() -> Settler:
	return _selected_settler if is_instance_valid(_selected_settler) else null


func get_selected_building() -> Building:
	return _selected_building if is_instance_valid(_selected_building) else null


func get_selected_site() -> ConstructionSite:
	return _selected_site if is_instance_valid(_selected_site) and _selected_site.is_alive() else null


func cancel_selected_site() -> void:
	var site := get_selected_site()
	if site:
		_buildings.cancel_site(site)
	clear_selection()


func clear_selection() -> void:
	_selected_settler = null
	_selected_building = null
	_selected_site = null
	selection_changed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if _buildings.is_placing():
		return
	if event.is_action_pressed("select_or_assign"):
		_click(_world.get_global_mouse_position())
	elif event.is_action_pressed("delete_selected"):
		cancel_selected_site()
	elif event.is_action_pressed("cancel_build"):
		var site := _buildings.find_site_at(_world.world_to_grid(_world.get_global_mouse_position()))
		if event is InputEventMouseButton and site:
			_buildings.cancel_site(site)
		clear_selection()


func _click(world_pos: Vector2) -> void:
	var settler := _settler_at(world_pos)
	if settler:
		clear_selection()
		_selected_settler = settler
		selection_changed.emit()
		return
	var grid_pos := _world.world_to_grid(world_pos)
	var site := _buildings.find_site_at(grid_pos)
	if site:
		clear_selection()
		_selected_site = site
		selection_changed.emit()
		return
	var building := _building_at(grid_pos)
	if building:
		clear_selection()
		_selected_building = building
		selection_changed.emit()
		return
	clear_selection()


func _sync_highlight() -> void:
	var picked := get_selected_settler()
	for settler in _settlers.living_settlers():
		settler.set_selected(settler == picked)
	var structure: Structure = get_selected_building()
	if structure == null:
		structure = get_selected_site()
	_buildings.set_highlight(structure)


func _settler_at(world_pos: Vector2) -> Settler:
	for settler in _settlers.living_settlers():
		if settler.global_position.distance_to(world_pos) <= PICK_RADIUS:
			return settler
	return null


func _building_at(grid_pos: Vector2i) -> Building:
	for child in _buildings.get_children():
		if child is Building and child.occupies(grid_pos):
			return child
	return null
