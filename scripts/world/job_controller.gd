class_name JobController
extends Node

const PICK_RADIUS := 12.0

var _world: WorldGrid
var _buildings: BuildController
var _settlers: SettlerManager
var _selected: Settler
var _status: Label


func _ready() -> void:
	_world = get_parent()
	_buildings = get_parent().get_node("Buildings")
	_settlers = get_parent().get_node("Settlers")
	_status = get_node("../UI/Status")


func _process(_delta: float) -> void:
	if not is_instance_valid(_selected):
		_selected = null
	_status.text = _describe_selection()


func _unhandled_input(event: InputEvent) -> void:
	if _buildings.is_placing():
		return
	if event.is_action_pressed("select_or_assign"):
		_click(_world.get_global_mouse_position())
	elif event.is_action_pressed("unassign_settler") and _selected:
		_selected.worker.unassign()
	elif event.is_action_pressed("cancel_build"):
		_selected = null


func _click(world_pos: Vector2) -> void:
	var settler := _settler_at(world_pos)
	if settler:
		_selected = settler
		return
	if _selected == null:
		return
	var building := _building_at(_world.world_to_grid(world_pos))
	if building:
		_selected.worker.assign(building)


func _settler_at(world_pos: Vector2) -> Settler:
	for settler in _settlers.get_children():
		if settler.global_position.distance_to(world_pos) <= PICK_RADIUS:
			return settler
	return null


func _building_at(grid_pos: Vector2i) -> Building:
	for child in _buildings.get_children():
		if child is Building and child.occupies(grid_pos):
			return child
	return null


func _describe_selection() -> String:
	if _selected == null:
		return "Click a settler to select; then click a building with a job slot to assign. U unassigns."
	var job := "none"
	if _selected.worker.building:
		job = _selected.worker.building.def.display_name
	return "Settler: hunger %d  rest %d  health %d  job: %s" % [
		_selected.needs.hunger, _selected.needs.rest, _selected.needs.health, job,
	]
