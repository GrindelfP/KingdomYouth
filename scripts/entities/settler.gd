class_name Settler
extends Node2D

signal arrived(grid_pos: Vector2i)
signal path_failed(grid_pos: Vector2i)

const SPEED_TILES_PER_SECOND := 3.0
const RADIUS := 6.0
const COLOR := Color(0.95, 0.85, 0.6)
const REST_CALL := 25.0
const REST_FULL := 95.0
const CARRY_MARKER_SIZE := 6.0
const TOOL_LIFETIME := 720.0
const NO_TOOL_SPEED := 0.5

var world: WorldGrid
var pathfinder: GridPathfinder
var needs: Needs
var worker: Worker
var buildings: BuildController
var profession: StringName = Professions.LABORER
var home: Building
var display_id := 0
var carried_id: StringName
var carried_amount := 0
var has_tool := false
var tool_wear := 0.0
var _last_cell := Vector2i.ZERO
var _destination := Vector2i.ZERO
var _path: Array[Vector2i] = []
var _moving := false
var _home_cell := Vector2i.ZERO
var _resting := false
var _warming := false


func _ready() -> void:
	needs = Needs.new()
	add_child(needs)
	needs.ticked.connect(_on_needs_ticked)
	needs.meal_provider = _meal_source
	worker = Worker.new()
	add_child(worker)


func setup(world_grid: WorldGrid, grid_pathfinder: GridPathfinder, build_controller: BuildController, grid_pos: Vector2i) -> void:
	world = world_grid
	pathfinder = grid_pathfinder
	buildings = build_controller
	_last_cell = grid_pos
	global_position = world.grid_to_world(grid_pos)


func get_grid_pos() -> Vector2i:
	return _last_cell


func is_working_age() -> bool:
	return true


func needs_tool() -> bool:
	return not has_tool and (worker.building != null or profession == Professions.BUILDER)


func work_speed() -> float:
	return 1.0 if has_tool else NO_TOOL_SPEED


func wear_tool(seconds: float) -> void:
	if not has_tool:
		return
	tool_wear += seconds / TOOL_LIFETIME
	if tool_wear >= 1.0:
		has_tool = false
		tool_wear = 0.0


func equip_tool() -> void:
	has_tool = true
	tool_wear = 0.0


func get_home_cell() -> Vector2i:
	return _home_cell


func is_at_home() -> bool:
	return home != null and _last_cell == _home_cell and not _moving


func is_moving() -> bool:
	return _moving


func is_carrying() -> bool:
	return carried_amount > 0


func set_carried(id: StringName, amount: int) -> void:
	carried_id = id if amount > 0 else StringName()
	carried_amount = maxi(amount, 0)
	queue_redraw()


func move_to(grid_pos: Vector2i) -> bool:
	_destination = grid_pos
	_moving = true
	return _replan()


func cancel_movement() -> void:
	_moving = false
	_path.clear()


func _process(delta: float) -> void:
	if not _moving:
		return
	if not world.is_walkable(_path[0]):
		_replan()
		return
	var target := world.grid_to_world(_path[0])
	global_position = global_position.move_toward(target, SPEED_TILES_PER_SECOND * world.get_tile_size().x * delta)
	if global_position == target:
		_last_cell = _path.pop_front()
		if _path.is_empty():
			_arrive()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, COLOR)
	if carried_amount > 0:
		var color := ResourceCatalog.get_def(carried_id).color
		var marker := Vector2.ONE * CARRY_MARKER_SIZE
		draw_rect(Rect2(Vector2(-CARRY_MARKER_SIZE / 2.0, -RADIUS - CARRY_MARKER_SIZE - 1.0), marker), color)
		draw_rect(Rect2(Vector2(-CARRY_MARKER_SIZE / 2.0, -RADIUS - CARRY_MARKER_SIZE - 1.0), marker), Color.BLACK, false)


func assign_home(house: Building) -> bool:
	var cells := house.get_access_cells()
	if cells.is_empty():
		return false
	unassign_home()
	home = house
	_home_cell = cells[0]
	house.residents.append(self)
	needs.sheltered = true
	return true


func unassign_home() -> void:
	if home:
		home.residents.erase(self)
	home = null
	needs.sheltered = false
	_resting = false
	_warming = false
	needs.diet_modifier = 0.0


func _meal_source() -> Inventory:
	return home.household if is_at_home() else null


func _on_needs_ticked() -> void:
	needs.at_home = is_at_home()
	needs.warm = needs.at_home and home.is_heated()
	needs.diet_modifier = _diet_modifier()
	_update_resting()
	_update_warming()
	var recovering := _resting or _warming
	if recovering:
		worker.pause()
	else:
		worker.resume()
		if needs.is_critical():
			worker.serve_hunger()
	if recovering and not _moving and not is_at_home():
		move_to(_home_cell)


func _diet_modifier() -> float:
	if home == null:
		return 0.0
	var kinds := home.diet_kinds()
	if kinds >= Building.DIET_VARIETY_KINDS:
		return Needs.DIET_BONUS
	if kinds == 1:
		return -Needs.DIET_PENALTY
	return 0.0


func _update_warming() -> void:
	if home == null or not TimeManager.is_cold() or not home.is_heated():
		_warming = false
	elif needs.warmth < Needs.COLD_CALL:
		_warming = true
	elif needs.warmth >= Needs.WARM_FULL:
		_warming = false


func _update_resting() -> void:
	if home == null:
		_resting = false
	elif needs.rest <= REST_CALL:
		_resting = true
	elif needs.rest >= REST_FULL:
		_resting = false


func _replan() -> bool:
	var path := pathfinder.find_path(_last_cell, _destination)
	if path.is_empty():
		_moving = false
		_path.clear()
		path_failed.emit(_destination)
		return false
	path.pop_front()
	_path = path
	if _path.is_empty():
		_arrive()
	return true


func _arrive() -> void:
	_moving = false
	arrived.emit(_destination)
