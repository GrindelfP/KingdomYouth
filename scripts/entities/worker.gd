class_name Worker
extends Node

enum State { IDLE, TRAVEL, WORK, PICKUP, DELIVER, BUILD, RETURN }
enum Action { HARVEST, PLANT, CUT, PLOW, SOW, REAP }

const NO_TARGET := Vector2i(-1, -1)
const RETRY_DELAY := 3.0
const IDLE_RETRY := 1.0
const MAX_TARGET_CANDIDATES := 30
const HAUL_SIZE := Hauler.CARRY_SIZE
const LABORER_PICKUP_MIN := 5
const RALLY_RADIUS := 4

var building: Building
var _settler: Settler
var _hauler: Hauler
var _state := State.IDLE
var _target := NO_TARGET
var _action := Action.HARVEST
var _work_left := 0.0
var _retry_left := 0.0
var _paused := false
var _site: ConstructionSite
var _reserved_site: ConstructionSite
var _reserved_id := &""
var _reserved_amount := 0
var _claimed_building: Building
var _claimed_amount := 0
var _claimed_house: Building
var _claimed_field: Building
var _field_cell := NO_TARGET


func _ready() -> void:
	_settler = get_parent()
	_hauler = Hauler.new(_settler)
	_settler.arrived.connect(_on_arrived)
	_settler.path_failed.connect(_on_path_failed)


func assign(target_building: Building) -> bool:
	if not target_building.has_free_job_slot():
		return false
	unassign()
	building = target_building
	building.workers.append(_settler)
	_settler.profession = building.job_def().profession_id()
	return true


func unassign() -> void:
	cancel_task()
	if building:
		building.workers.erase(_settler)
		_settler.profession = Professions.LABORER
	building = null


func set_profession(profession: StringName) -> void:
	if profession == _settler.profession:
		return
	unassign()
	_settler.profession = profession


func is_paused() -> bool:
	return _paused


func is_working() -> bool:
	return _state == State.WORK or _state == State.BUILD


func get_state_name() -> String:
	return State.keys()[_state].capitalize()


func pause() -> void:
	_paused = true
	cancel_task()


func resume() -> void:
	_paused = false


func cancel_task() -> void:
	if _state != State.IDLE:
		_hauler.cancel()
		_settler.cancel_movement()
		_state = State.IDLE
		_target = NO_TARGET
		_work_left = 0.0
		_site = null
	_release_claims()
	_return_carried()


func _process(delta: float) -> void:
	if _paused:
		return
	match _state:
		State.IDLE:
			if _retry_left > 0.0:
				_retry_left -= delta
			else:
				_plan()
		State.WORK:
			_settler.wear_tool(delta)
			_work_left -= delta
			if _work_left <= 0.0:
				_finish_work()
		State.BUILD:
			if _site and _site.is_alive() and _site.is_ready():
				_settler.wear_tool(delta)
				_site.add_work(delta * _settler.work_speed())
			else:
				_site = null
				_state = State.IDLE


func _plan() -> void:
	if _settler.is_carrying():
		_state = State.DELIVER
		if not _hauler.deliver_to_storage(_on_trip_done):
			_state = State.IDLE
			_retry_left = RETRY_DELAY
		return
	if not _settler.is_working_age():
		_plan_child()
		return
	var started := _plan_survival() or _plan_tool()
	if started:
		return
	match _settler.profession:
		Professions.LABORER:
			started = _plan_hauling() or _plan_rally()
		Professions.BUILDER:
			started = _plan_construction() or _plan_hauling() or _plan_rally()
		_:
			started = _plan_job()
	if not started and _state == State.IDLE:
		_retry_left = IDLE_RETRY if building == null else RETRY_DELAY


func _plan_child() -> void:
	var needs := _settler.needs
	var home := _settler.home
	var started := false
	if needs.hunger >= Needs.EAT_HUNGER:
		if home == null:
			started = _plan_eat_at_storage()
		elif home.food_stock() > 0 and _settler.is_at_home():
			needs.try_eat()
	if not started and home != null and not _settler.is_at_home():
		started = _plan_go_home()
	if not started and _state == State.IDLE:
		_retry_left = IDLE_RETRY


func serve_hunger() -> void:
	if _state != State.TRAVEL and _state != State.WORK and _state != State.BUILD:
		return
	if _can_find_meal():
		cancel_task()


func _can_find_meal() -> bool:
	var home := _settler.home
	if home != null:
		return home.food_stock() > 0 and not _settler.is_at_home()
	return _nearest_food_storage() != null


func _plan_survival() -> bool:
	var needs := _settler.needs
	var home := _settler.home
	if needs.hunger >= Needs.EAT_HUNGER:
		if home == null:
			return _plan_eat_at_storage()
		if home.food_stock() > 0:
			if _settler.is_at_home():
				needs.try_eat()
			else:
				return _plan_go_home()
	if home != null:
		return _plan_restock(home)
	return false


func _plan_go_home() -> bool:
	_state = State.RETURN
	if _hauler.walk_to_cell(_settler.get_home_cell(), _on_home_reached):
		return true
	_state = State.IDLE
	return false


func _plan_eat_at_storage() -> bool:
	var storage := _nearest_food_storage()
	if storage == null:
		return false
	_state = State.RETURN
	if _hauler.walk_to(storage, _on_storage_meal.bind(storage.get_instance_id())):
		return true
	_state = State.IDLE
	return false


func _nearest_food_storage() -> Building:
	var from := _settler.get_grid_pos()
	var best: Building
	for storage in ResourceStockpile.get_storages():
		if storage.storage.category_total(ResourceDef.Category.FOOD) <= 0:
			continue
		if best == null or _manhattan(storage.get_center_cell(), from) < _manhattan(best.get_center_cell(), from):
			best = storage
	return best


func _plan_restock(home: Building) -> bool:
	if home.restock_claimed:
		return false
	var from := _settler.get_grid_pos()
	var wanted: Array[StringName] = []
	if home.needs_food():
		wanted.append_array(_food_kinds_by_stock(home))
	if home.needs_firewood():
		wanted.append(Building.FUEL_ID)
	for id in wanted:
		var target := Building.FOOD_TARGET if id != Building.FUEL_ID else Building.FIREWOOD_TARGET
		var have := home.household.get_amount(id) if id == Building.FUEL_ID else home.food_stock()
		var amount := mini(mini(target - have, Building.RESTOCK_TRIP), home.household.free_space())
		if amount <= 0:
			continue
		for source in ResourceStockpile.find_sources(id, from):
			var trip := mini(amount, source.storage.get_amount(id))
			home.restock_claimed = true
			_claimed_house = home
			_state = State.PICKUP
			if _hauler.fetch(source, source.storage, id, trip, _on_restock_taken.bind(home.get_instance_id())):
				return true
			_release_claims()
			_state = State.IDLE
	return false


func _food_kinds_by_stock(home: Building) -> Array[StringName]:
	var kinds := ResourceCatalog.ids_in_category(ResourceDef.Category.FOOD)
	kinds.sort_custom(func(a: StringName, b: StringName) -> bool:
		return home.household.get_amount(a) < home.household.get_amount(b))
	return kinds


func _plan_tool() -> bool:
	if not _settler.needs_tool():
		return false
	var from := _settler.get_grid_pos()
	for source in ResourceStockpile.find_sources(Building.TOOL_ID, from):
		_state = State.PICKUP
		if _hauler.fetch(source, source.storage, Building.TOOL_ID, 1, _on_tool_taken):
			return true
		_state = State.IDLE
	return false


func _plan_job() -> bool:
	if building == null:
		return false
	var job := building.job_def()
	var target := NO_TARGET
	var output_ready := building.output.free_space() >= job.output_total() and building.work_efficiency() > 0.0
	if output_ready and job.has_inputs() and not building.has_batch():
		if _plan_input_trip():
			return true
		output_ready = false
	var can_work := output_ready
	if can_work:
		target = _find_target()
	var stored := building.output.total()
	if stored > 0 and (stored >= HAUL_SIZE or target == NO_TARGET):
		if _begin_pickup():
			_release_field_claim()
			return true
	if target == NO_TARGET:
		return false
	_target = target
	_state = State.TRAVEL
	_settler.move_to(target)
	return true


func _plan_input_trip() -> bool:
	var id := building.missing_input()
	if id == &"":
		return false
	var amount := building.input_trip_amount(id)
	if amount <= 0:
		return false
	for source in ResourceStockpile.find_sources(id, _settler.get_grid_pos()):
		_state = State.PICKUP
		if _hauler.fetch(source, source.storage, id, mini(amount, source.storage.get_amount(id)), _on_input_taken):
			return true
		_state = State.IDLE
	return false


func _plan_hauling() -> bool:
	return _plan_materials() or _plan_output_pickup()


func _plan_materials() -> bool:
	var from := _settler.get_grid_pos()
	for site in _sites_by_distance(from):
		for id in site.required:
			var missing := site.missing(id)
			if missing <= 0:
				continue
			for source in ResourceStockpile.find_sources(id, from):
				var amount := mini(mini(missing, HAUL_SIZE), source.storage.get_amount(id))
				_reserved_site = site
				_reserved_id = id
				_reserved_amount = amount
				site.reserve(id, amount)
				_state = State.PICKUP
				if _hauler.fetch(source, source.storage, id, amount, _on_materials_taken):
					return true
				_release_claims()
				_state = State.IDLE
	return false


func _plan_output_pickup() -> bool:
	var from := _settler.get_grid_pos()
	for workplace in _workplaces_by_distance(from):
		var available := workplace.output.total() - workplace.output_claimed
		if available < LABORER_PICKUP_MIN:
			continue
		var id := _richest_output(workplace)
		if id == &"" or ResourceStockpile.find_storages(id, workplace.get_center_cell()).is_empty():
			continue
		_claimed_building = workplace
		_claimed_amount = mini(available, HAUL_SIZE)
		workplace.output_claimed += _claimed_amount
		_state = State.PICKUP
		if _hauler.fetch(workplace, workplace.output, id, _claimed_amount, _on_output_taken):
			return true
		_release_claims()
		_state = State.IDLE
	return false


func _plan_construction() -> bool:
	var from := _settler.get_grid_pos()
	for site in _sites_by_distance(from):
		if not site.is_ready():
			continue
		_state = State.TRAVEL
		if _hauler.walk_to(site, _on_site_reached.bind(site.get_instance_id())):
			return true
		_state = State.IDLE
	return false


func _plan_rally() -> bool:
	var center := WorldGrid.MAP_RECT.get_center()
	var best: Building
	for storage in ResourceStockpile.get_storages():
		if best == null or _manhattan(storage.get_center_cell(), center) < _manhattan(best.get_center_cell(), center):
			best = storage
	if best == null or _manhattan(best.get_center_cell(), _settler.get_grid_pos()) <= RALLY_RADIUS + best.def.footprint.x:
		return false
	_state = State.RETURN
	if _hauler.walk_to(best, _on_trip_done):
		return true
	_state = State.IDLE
	return false


func _sites_by_distance(from: Vector2i) -> Array[ConstructionSite]:
	var sites := _settler.buildings.get_sites()
	sites.sort_custom(func(a: ConstructionSite, b: ConstructionSite) -> bool:
		return _manhattan(a.get_center_cell(), from) < _manhattan(b.get_center_cell(), from))
	return sites


func _workplaces_by_distance(from: Vector2i) -> Array[Building]:
	var workplaces: Array[Building] = []
	for candidate in _settler.buildings.get_buildings():
		if candidate.output != null and candidate.output.total() > 0:
			workplaces.append(candidate)
	workplaces.sort_custom(func(a: Building, b: Building) -> bool:
		return _manhattan(a.get_center_cell(), from) < _manhattan(b.get_center_cell(), from))
	return workplaces


func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


func _find_target() -> Vector2i:
	var job := building.job_def()
	match job.target_mode:
		JobDef.TargetMode.FOREST_CELL:
			_action = Action.HARVEST
			var forest: Array[Vector2i] = []
			for cell in _settler.world.get_cells_in_radius(building.get_work_center(), job.work_radius):
				if _settler.world.get_terrain_name(cell) == "forest":
					forest.append(cell)
			return _first_reachable(forest)
		JobDef.TargetMode.FORESTER:
			return _find_forester_target(job)
		JobDef.TargetMode.FIELD:
			return _find_field_target()
	_action = Action.HARVEST
	for cell in building.get_access_cells():
		if _hauler.is_reachable(cell):
			return cell
	return NO_TARGET


func _find_field_target() -> Vector2i:
	var field := building.field
	var from := building.grid_to_field_cell(_settler.get_grid_pos())
	var pick := field.next_task(from, TimeManager.get_season() == TimeManager.Season.SPRING)
	if pick["task"] == CropField.Task.NONE:
		return NO_TARGET
	var cell: Vector2i = pick["cell"]
	var grid_cell := building.field_cell_to_grid(cell)
	if not _hauler.is_reachable(grid_cell):
		return NO_TARGET
	field.claim(cell)
	_claimed_field = building
	_field_cell = cell
	match pick["task"]:
		CropField.Task.REAP:
			_action = Action.REAP
		CropField.Task.SOW:
			_action = Action.SOW
		_:
			_action = Action.PLOW
	return grid_cell


func _find_forester_target(job: JobDef) -> Vector2i:
	var world := _settler.world
	var forest := 0
	var mature: Array[Vector2i] = []
	var plantable: Array[Vector2i] = []
	for cell in world.get_cells_in_radius(building.get_work_center(), job.work_radius):
		var stage := world.get_tree_stage(cell)
		if stage != WorldGrid.NO_TREE:
			forest += 1
			if stage == WorldGrid.STAGE_MATURE:
				mature.append(cell)
		elif world.can_plant(cell):
			plantable.append(cell)
	var density := float(forest) / maxf(forest + plantable.size(), 1.0)
	if density < job.forest_density and not plantable.is_empty():
		_action = Action.PLANT
		return _first_reachable(plantable)
	_action = Action.CUT
	return _first_reachable(mature)


func _first_reachable(cells: Array[Vector2i]) -> Vector2i:
	var from := _settler.get_grid_pos()
	cells.shuffle()
	for cell in cells.slice(0, MAX_TARGET_CANDIDATES):
		if not _settler.pathfinder.find_path(from, cell).is_empty():
			return cell
	return NO_TARGET


func _begin_pickup() -> bool:
	var id := _richest_output(building)
	if id == &"" or ResourceStockpile.find_storages(id, building.get_center_cell()).is_empty():
		return false
	_state = State.PICKUP
	if _hauler.fetch(building, building.output, id, HAUL_SIZE, _on_output_taken):
		return true
	_state = State.IDLE
	return false


func _richest_output(source: Building) -> StringName:
	var best := &""
	for id in source.output.ids():
		if best == &"" or source.output.get_amount(id) > source.output.get_amount(best):
			best = id
	return best


func _release_claims() -> void:
	if _reserved_site and is_instance_valid(_reserved_site):
		_reserved_site.release(_reserved_id, _reserved_amount)
	_reserved_site = null
	_reserved_amount = 0
	if _claimed_building and is_instance_valid(_claimed_building):
		_claimed_building.output_claimed = maxi(_claimed_building.output_claimed - _claimed_amount, 0)
	_claimed_building = null
	_claimed_amount = 0
	if _claimed_house and is_instance_valid(_claimed_house):
		_claimed_house.restock_claimed = false
	_claimed_house = null
	_release_field_claim()


func _release_field_claim() -> void:
	if _claimed_field and is_instance_valid(_claimed_field) and _claimed_field.field:
		_claimed_field.field.release(_field_cell)
	_claimed_field = null
	_field_cell = NO_TARGET


func _return_carried() -> void:
	if not _settler.is_carrying():
		return
	var id := _settler.carried_id
	var left := _settler.carried_amount
	if building and building.input and building.def.job.input_amount(id) > 0:
		left -= building.input.add(id, left)
	elif building and building.output:
		left -= building.output.add(id, left)
	if left > 0:
		ResourceStockpile.add(id, left)
	_settler.set_carried(&"", 0)


func _on_trip_done() -> void:
	_state = State.IDLE
	_retry_left = 0.0


func _on_home_reached() -> void:
	_settler.needs.try_eat()
	_on_trip_done()


func _on_storage_meal(storage_id: int) -> void:
	var storage := instance_from_id(storage_id) as Building
	if storage != null and storage.is_alive() and storage.storage != null:
		_settler.needs.eat_from(storage.storage)
	_on_trip_done()


func _on_restock_taken(taken: int, house_id: int) -> void:
	var house := instance_from_id(house_id) as Building
	if taken <= 0 or house == null or not house.is_alive():
		_release_claims()
		_state = State.IDLE
		return
	_state = State.DELIVER
	if not _hauler.deliver(house, house.household, _on_restock_delivered):
		_release_claims()
		_state = State.IDLE


func _on_restock_delivered(_accepted: int) -> void:
	_release_claims()
	_state = State.IDLE


func _on_tool_taken(taken: int) -> void:
	if taken > 0:
		_settler.set_carried(&"", 0)
		_settler.equip_tool()
	_state = State.IDLE


func _on_input_taken(taken: int) -> void:
	if taken <= 0 or building == null:
		_state = State.IDLE
		return
	_state = State.DELIVER
	if not _hauler.deliver(building, building.input, _on_input_delivered):
		_state = State.IDLE


func _on_input_delivered(_accepted: int) -> void:
	_state = State.IDLE


func _on_materials_taken(taken: int) -> void:
	var site := _reserved_site
	if taken < _reserved_amount and site and is_instance_valid(site):
		site.release(_reserved_id, _reserved_amount - taken)
		_reserved_amount = taken
	if taken <= 0 or site == null or not is_instance_valid(site) or not site.is_alive():
		_release_claims()
		_state = State.IDLE
		return
	_state = State.DELIVER
	if not _hauler.deliver(site, site.delivered, _on_materials_delivered):
		_release_claims()
		_state = State.IDLE


func _on_materials_delivered(_accepted: int) -> void:
	_release_claims()
	_state = State.IDLE


func _on_output_taken(taken: int) -> void:
	_release_claims()
	if taken <= 0:
		_state = State.IDLE
		return
	_state = State.DELIVER
	if not _hauler.deliver_to_storage(_on_trip_done):
		_state = State.IDLE
		_retry_left = RETRY_DELAY


func _on_site_reached(site_id: int) -> void:
	var site := instance_from_id(site_id) as ConstructionSite
	if site != null and site.is_alive() and site.is_ready():
		_site = site
		_state = State.BUILD
	else:
		_state = State.IDLE


func _on_arrived(grid_pos: Vector2i) -> void:
	if _hauler.handle_arrived(grid_pos):
		return
	if _state == State.TRAVEL and grid_pos == _target:
		_state = State.WORK
		_work_left = _work_duration()


func _on_path_failed(grid_pos: Vector2i) -> void:
	if _hauler.handle_failed(grid_pos):
		_release_claims()
		_state = State.IDLE
		_retry_left = RETRY_DELAY
		return
	if _state == State.IDLE or grid_pos != _target:
		return
	_release_field_claim()
	_state = State.IDLE
	_target = NO_TARGET
	_retry_left = RETRY_DELAY


func _work_duration() -> float:
	var job := building.job_def()
	match _action:
		Action.PLANT:
			return job.plant_time
		Action.PLOW:
			return job.plow_time / _settler.work_speed()
		Action.SOW:
			return job.plant_time / _settler.work_speed()
		Action.REAP:
			return job.work_time / _settler.work_speed()
	return job.work_time / (maxf(building.work_efficiency(), 0.1) * _settler.work_speed())


func _finish_work() -> void:
	var job := building.job_def()
	var world := _settler.world
	if _action == Action.PLOW or _action == Action.SOW or _action == Action.REAP:
		_finish_field_work(job)
		return
	_state = State.IDLE
	match _action:
		Action.PLANT:
			world.plant_sapling(_target)
			return
		Action.CUT:
			if not world.cut_tree(_target):
				return
		Action.HARVEST:
			if job.target_mode == JobDef.TargetMode.FOREST_CELL and world.get_terrain_name(_target) != "forest":
				return
	if job.has_inputs() and not building.consume_batch():
		return
	for entry in job.outputs:
		if randf() <= float(entry["chance"]):
			building.output.add(StringName(entry["id"]), int(entry["amount"]))


func _finish_field_work(job: JobDef) -> void:
	var field := building.field
	_state = State.IDLE
	match _action:
		Action.PLOW:
			if field.plow(_field_cell) and TimeManager.get_season() == TimeManager.Season.SPRING:
				_action = Action.SOW
				_state = State.WORK
				_work_left = _work_duration()
				return
		Action.SOW:
			field.sow(_field_cell)
		Action.REAP:
			if field.reap(_field_cell):
				building.output.add(field.crop, int(job.outputs[0]["amount"]))
	_release_field_claim()
