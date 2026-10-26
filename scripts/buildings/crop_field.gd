class_name CropField
extends RefCounted

signal cell_changed(cell: Vector2i)
signal cells_reloaded
signal crop_changed

enum CellState { EMPTY, PLOWED, PLANTED, GROWING, RIPE, HARVESTED }
enum Task { NONE, PLOW, SOW, REAP }

const CROP_IDS: Array[StringName] = [&"wheat", &"cabbage"]
const GROW_MONTHS: Dictionary = {&"wheat": 5.5, &"cabbage": 4.5}
const SPROUT_GROWTH := 0.2
const DEFAULT_CROP := &"wheat"

var size := 0
var crop: StringName = DEFAULT_CROP
var pending_crop: StringName = DEFAULT_CROP
var _states := PackedInt32Array()
var _planted_at := PackedFloat64Array()
var _claimed: Dictionary = {}


func _init(field_size: int) -> void:
	size = field_size
	_states.resize(size * size)
	_planted_at.resize(size * size)


func is_in_field(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size and cell.y < size


func get_state(cell: Vector2i) -> int:
	return _states[_index(cell)]


func get_growth(cell: Vector2i) -> float:
	match get_state(cell):
		CellState.PLANTED, CellState.GROWING:
			return clampf((TimeManager.get_time_months() - _planted_at[_index(cell)]) / float(GROW_MONTHS[crop]), 0.0, 1.0)
		CellState.RIPE:
			return 1.0
	return 0.0


func count(state: int) -> int:
	var total := 0
	for value in _states:
		if value == state:
			total += 1
	return total


func planted_count() -> int:
	return count(CellState.PLANTED) + count(CellState.GROWING)


func has_crops() -> bool:
	for value in _states:
		if value >= CellState.PLANTED:
			return true
	return false


func set_pending_crop(crop_id: StringName) -> void:
	if not CROP_IDS.has(crop_id) or crop_id == pending_crop:
		return
	pending_crop = crop_id
	if not has_crops():
		crop = crop_id
	crop_changed.emit()


func begin_season() -> void:
	if crop != pending_crop:
		crop = pending_crop
		crop_changed.emit()


func plow(cell: Vector2i) -> bool:
	if get_state(cell) != CellState.EMPTY:
		return false
	_set_state(cell, CellState.PLOWED)
	return true


func sow(cell: Vector2i) -> bool:
	if get_state(cell) != CellState.PLOWED:
		return false
	_planted_at[_index(cell)] = TimeManager.get_time_months()
	_set_state(cell, CellState.PLANTED)
	return true


func reap(cell: Vector2i) -> bool:
	if get_state(cell) != CellState.RIPE:
		return false
	_set_state(cell, CellState.HARVESTED)
	return true


func update() -> void:
	var now := TimeManager.get_time_months()
	for y in size:
		for x in size:
			var cell := Vector2i(x, y)
			var state := _states[_index(cell)]
			if state != CellState.PLANTED and state != CellState.GROWING:
				continue
			var growth: float = (now - _planted_at[_index(cell)]) / float(GROW_MONTHS[crop])
			if growth >= 1.0:
				_set_state(cell, CellState.RIPE)
			elif growth >= SPROUT_GROWTH and state == CellState.PLANTED:
				_set_state(cell, CellState.GROWING)


func frost() -> int:
	var lost := 0
	for value in _states:
		if value == CellState.PLANTED or value == CellState.GROWING or value == CellState.RIPE:
			lost += 1
	_states.fill(CellState.EMPTY)
	_claimed.clear()
	cells_reloaded.emit()
	return lost


func claim(cell: Vector2i) -> void:
	_claimed[cell] = true


func release(cell: Vector2i) -> void:
	_claimed.erase(cell)


func is_claimed(cell: Vector2i) -> bool:
	return _claimed.has(cell)


func next_task(from: Vector2i, sowing_season: bool) -> Dictionary:
	var best := {"task": Task.NONE, "cell": Vector2i.ZERO}
	var best_rank := 99
	var best_distance := 1 << 30
	for y in size:
		for x in size:
			var cell := Vector2i(x, y)
			if _claimed.has(cell):
				continue
			var rank := _task_rank(_states[_index(cell)], sowing_season)
			if rank == 0:
				continue
			var distance := absi(cell.x - from.x) + absi(cell.y - from.y)
			if rank < best_rank or (rank == best_rank and distance < best_distance):
				best_rank = rank
				best_distance = distance
				best = {"task": _task_for_rank(rank), "cell": cell}
	return best


func to_save_data() -> Dictionary:
	return {
		"crop": String(crop),
		"pending": String(pending_crop),
		"states": Array(_states),
		"planted_at": Array(_planted_at),
	}


func from_save_data(data: Dictionary) -> void:
	crop = StringName(data["crop"])
	pending_crop = StringName(data["pending"])
	var states: Array = data["states"]
	var planted: Array = data["planted_at"]
	for index in mini(states.size(), _states.size()):
		_states[index] = int(states[index])
		_planted_at[index] = float(planted[index])
	_claimed.clear()
	cells_reloaded.emit()
	crop_changed.emit()


func _task_rank(state: int, sowing_season: bool) -> int:
	if state == CellState.RIPE:
		return 1
	if not sowing_season:
		return 0
	if state == CellState.PLOWED:
		return 2
	if state == CellState.EMPTY:
		return 3
	return 0


func _task_for_rank(rank: int) -> int:
	match rank:
		1:
			return Task.REAP
		2:
			return Task.SOW
	return Task.PLOW


func _set_state(cell: Vector2i, state: int) -> void:
	_states[_index(cell)] = state
	cell_changed.emit(cell)


func _index(cell: Vector2i) -> int:
	return cell.y * size + cell.x
