class_name Worker
extends Node

enum State { IDLE, TRAVEL, WORK }

const NO_TARGET := Vector2i(-1, -1)
const RETRY_DELAY := 3.0
const MAX_TARGET_CANDIDATES := 30

var building: Building
var _settler: Settler
var _state := State.IDLE
var _target := NO_TARGET
var _work_left := 0.0
var _retry_left := 0.0
var _paused := false


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


func pause() -> void:
	_paused = true
	cancel_task()


func resume() -> void:
	_paused = false


func cancel_task() -> void:
	if _state == State.IDLE:
		return
	_settler.cancel_movement()
	_state = State.IDLE
	_target = NO_TARGET
	_work_left = 0.0


func _process(delta: float) -> void:
	if building == null or _paused:
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
	if building.job_def().seasonal and TimeManager.food_multiplier() <= 0.0:
		_retry_left = RETRY_DELAY
		return
	var target := _find_target()
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


func _on_arrived(grid_pos: Vector2i) -> void:
	if _state != State.TRAVEL or grid_pos != _target:
		return
	_state = State.WORK
	_work_left = _work_duration()


func _on_path_failed(grid_pos: Vector2i) -> void:
	if _state != State.TRAVEL or grid_pos != _target:
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
	ResourceStockpile.add(job.output_type, job.output_amount)
