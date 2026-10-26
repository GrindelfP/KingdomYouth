class_name LaborManager
extends Node

signal professions_changed

const RECONCILE_INTERVAL := 0.5

var _settlers: SettlerManager
var _buildings: BuildController
var _accumulator := 0.0


func _ready() -> void:
	_settlers = get_parent().get_node("Settlers")
	_buildings = get_parent().get_node("Buildings")


func _process(delta: float) -> void:
	_accumulator += delta
	if _accumulator >= RECONCILE_INTERVAL:
		_accumulator = 0.0
		reconcile()


func profession_ids() -> Array[StringName]:
	var ids: Array[StringName] = [Professions.LABORER, Professions.BUILDER]
	for def in _buildings.building_defs:
		if def.job and not ids.has(def.job.profession_id()):
			ids.append(def.job.profession_id())
	return ids


func get_count(profession: StringName) -> int:
	var count := 0
	for settler in _settlers.living_settlers():
		if settler.profession == profession:
			count += 1
	return count


func get_max(profession: StringName) -> int:
	if profession == Professions.LABORER or profession == Professions.BUILDER:
		return -1
	var total := 0
	for workplace in _workplaces(profession):
		total += workplace.def.job.slots
	return total


func can_increase(profession: StringName) -> bool:
	if get_count(Professions.LABORER) == 0:
		return false
	if profession == Professions.BUILDER:
		return true
	if profession == Professions.LABORER:
		return false
	for workplace in _workplaces(profession):
		if workplace.desired_workers < workplace.def.job.slots:
			return true
	return false


func can_decrease(profession: StringName) -> bool:
	if profession == Professions.LABORER:
		return false
	return get_count(profession) > 0


func increase(profession: StringName) -> bool:
	if not can_increase(profession):
		return false
	if profession == Professions.BUILDER:
		var laborer := _nearest_laborer(_reference_cell())
		laborer.worker.set_profession(Professions.BUILDER)
	else:
		for workplace in _workplaces(profession):
			if workplace.desired_workers < workplace.def.job.slots:
				workplace.desired_workers += 1
				break
	reconcile()
	professions_changed.emit()
	return true


func decrease(profession: StringName) -> bool:
	if not can_decrease(profession):
		return false
	if profession == Professions.BUILDER:
		_farthest_of(profession, _reference_cell()).worker.set_profession(Professions.LABORER)
	else:
		var workplace := _workplace_to_shrink(profession)
		if workplace == null:
			return false
		workplace.desired_workers = maxi(workplace.desired_workers - 1, 0)
	reconcile()
	professions_changed.emit()
	return true


func set_desired_workers(workplace: Building, desired: int) -> void:
	workplace.desired_workers = clampi(desired, 0, workplace.def.job.slots)
	reconcile()
	professions_changed.emit()


func reconcile() -> void:
	var changed := false
	for workplace in _buildings.get_buildings():
		if workplace.def.job == null:
			continue
		while workplace.workers.size() > workplace.desired_workers:
			_farthest_worker(workplace).worker.unassign()
			changed = true
		while workplace.workers.size() < workplace.desired_workers:
			var laborer := _nearest_laborer(workplace.get_center_cell())
			if laborer == null or not laborer.worker.assign(workplace):
				break
			changed = true
	if changed:
		professions_changed.emit()


func _workplaces(profession: StringName) -> Array[Building]:
	var result: Array[Building] = []
	for building in _buildings.get_buildings():
		if building.def.job and building.def.job.profession_id() == profession:
			result.append(building)
	return result


func _workplace_to_shrink(profession: StringName) -> Building:
	var workplaces := _workplaces(profession)
	for workplace in workplaces:
		if workplace.desired_workers > workplace.workers.size():
			return workplace
	var best: Building
	var best_distance := -1
	var reference := _reference_cell()
	for workplace in workplaces:
		if workplace.workers.is_empty():
			continue
		var distance := _distance(workplace.get_center_cell(), reference)
		if distance > best_distance:
			best = workplace
			best_distance = distance
	return best


func _reference_cell() -> Vector2i:
	var sites := _buildings.get_sites()
	if not sites.is_empty():
		return sites[0].get_center_cell()
	return WorldGrid.MAP_RECT.get_center()


func _nearest_laborer(cell: Vector2i) -> Settler:
	var best: Settler
	for settler in _settlers.living_settlers():
		if settler.profession != Professions.LABORER:
			continue
		if best == null or _distance(settler.get_grid_pos(), cell) < _distance(best.get_grid_pos(), cell):
			best = settler
	return best


func _farthest_of(profession: StringName, cell: Vector2i) -> Settler:
	var best: Settler
	for settler in _settlers.living_settlers():
		if settler.profession != profession:
			continue
		if best == null or _distance(settler.get_grid_pos(), cell) > _distance(best.get_grid_pos(), cell):
			best = settler
	return best


func _farthest_worker(workplace: Building) -> Settler:
	var best: Settler
	var center := workplace.get_center_cell()
	for settler in workplace.workers:
		if best == null or _distance(settler.get_grid_pos(), center) > _distance(best.get_grid_pos(), center):
			best = settler
	return best


func _distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)
