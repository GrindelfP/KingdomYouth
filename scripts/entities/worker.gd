class_name Worker
extends Node

enum State { IDLE, TRAVEL, WORK, PICKUP, DELIVER }

const NO_TARGET := Vector2i(-1, -1)
const RETRY_DELAY := 3.0
const MAX_TARGET_CANDIDATES := 30
const HAUL_SIZE := 10

var building: Building
var _settler: Settler
var _state := State.IDLE
var _target := NO_TARGET
var _work_left := 0.0
var _retry_left := 0.0
var _paused := false
var _storage: Building


func _ready() -> void:
	_settler = get_parent()
	_settler.arrived.connect(_on_arrived)
	_settler.path_failed.connect(_on_path_failed)


func assign(target_building: Building) -> bool:
	if not target_building.has_free_job_slot():
		return false
	unassign()
	building = target_building
	building.workers.append(_settler)
	return true


func unassign() -> void:
	cancel_task()
	if building:
		building.workers.erase(_settler)
	building = null


func is_paused() -> bool:
	return _paused


func get_state_name() -> String:
	return State.keys()[_state].capitalize()


func pause() -> void:
	_paused = true
	cancel_task()


func resume() -> void:
	_paused = false


func cancel_task() -> void:
	if _state != State.IDLE:
		_settler.cancel_movement()
		_state = State.IDLE
		_target = NO_TARGET
		_work_left = 0.0
		_storage = null
	_return_carried()


func _process(delta: float) -> void:
	if _paused or (building == null and not _settler.is_carrying()):
		return
	match _state:
		State.IDLE:
			if _retry_left > 0.0:
				_retry_left -= delta
			else:
				_start_travel()
		State.WORK:
			_work_left -= delta
			if _work_left <= 0.0:
				_finish_work()


func _start_travel() -> void:
	if _settler.is_carrying():
		if not _begin_delivery():
			_retry_left = RETRY_DELAY
		return
	if building == null:
		return
	var job := building.job_def()
	var target := NO_TARGET
	var can_work := building.output.free_space() >= job.output_amount
	if job.seasonal and TimeManager.food_multiplier() <= 0.0:
		can_work = false
	if can_work:
		target = _find_target()
	var stored := building.output.total()
	if stored > 0 and (stored >= HAUL_SIZE or target == NO_TARGET):
		if _begin_pickup():
			return
	if target == NO_TARGET:
		_retry_left = RETRY_DELAY
		return
	_target = target
	_state = State.TRAVEL
	_settler.move_to(target)


func _find_target() -> Vector2i:
	var job := building.job_def()
	var from := _settler.get_grid_pos()
	if job.target_terrain.is_empty():
		for cell in building.get_access_cells():
			if _is_reachable(from, cell):
				return cell
		return NO_TARGET
	var candidates := _settler.world.get_terrain_cells(job.target_terrain, building.get_center_cell())
	for cell in candidates.slice(0, MAX_TARGET_CANDIDATES):
		if _is_reachable(from, cell):
			return cell
	return NO_TARGET


func _is_reachable(from: Vector2i, to: Vector2i) -> bool:
	return not _settler.pathfinder.find_path(from, to).is_empty()


func _begin_pickup() -> bool:
	var id := _richest_output()
	if id == &"" or ResourceStockpile.find_storages(id, building.get_center_cell()).is_empty():
		return false
	var cell := _reachable_access_cell(building)
	if cell == NO_TARGET:
		return false
	_target = cell
	_state = State.PICKUP
	_settler.move_to(cell)
	return true


func _begin_delivery() -> bool:
	var from := _settler.get_grid_pos()
	for storage in ResourceStockpile.find_storages(_settler.carried_id, from):
		var cell := _reachable_access_cell(storage)
		if cell == NO_TARGET:
			continue
		_storage = storage
		_target = cell
		_state = State.DELIVER
		_settler.move_to(cell)
		return true
	return false


func _reachable_access_cell(target_building: Building) -> Vector2i:
	var from := _settler.get_grid_pos()
	var cells := target_building.get_access_cells()
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.distance_squared_to(from) < b.distance_squared_to(from))
	for cell in cells:
		if _is_reachable(from, cell):
			return cell
	return NO_TARGET


func _richest_output() -> StringName:
	var best := &""
	for id in building.output.ids():
		if best == &"" or building.output.get_amount(id) > building.output.get_amount(best):
			best = id
	return best


func _return_carried() -> void:
	if not _settler.is_carrying():
		return
	var id := _settler.carried_id
	var left := _settler.carried_amount
	if building and building.output:
		left -= building.output.add(id, left)
	if left > 0:
		ResourceStockpile.add(id, left)
	_settler.set_carried(&"", 0)


func _on_arrived(grid_pos: Vector2i) -> void:
	if grid_pos != _target:
		return
	match _state:
		State.TRAVEL:
			_state = State.WORK
			_work_left = _work_duration()
		State.PICKUP:
			var id := _richest_output()
			_state = State.IDLE
			if id != &"":
				_settler.set_carried(id, building.output.take(id, HAUL_SIZE))
				_begin_delivery()
		State.DELIVER:
			_state = State.IDLE
			if is_instance_valid(_storage) and _storage.storage:
				var accepted := _storage.storage.add(_settler.carried_id, _settler.carried_amount)
				_settler.set_carried(_settler.carried_id, _settler.carried_amount - accepted)
			_storage = null
			if _settler.is_carrying():
				_begin_delivery()


func _on_path_failed(grid_pos: Vector2i) -> void:
	if _state == State.IDLE or grid_pos != _target:
		return
	_state = State.IDLE
	_target = NO_TARGET
	_retry_left = RETRY_DELAY


func _work_duration() -> float:
	var job := building.job_def()
	if not job.seasonal:
		return job.work_time
	return job.work_time / TimeManager.food_multiplier()


func _finish_work() -> void:
	var job := building.job_def()
	_state = State.IDLE
	if not job.target_terrain.is_empty():
		if _settler.world.get_terrain_name(_target) != job.target_terrain:
			return
		_settler.world.deplete_forest(_target)
	building.output.add(job.output_id, job.output_amount)
