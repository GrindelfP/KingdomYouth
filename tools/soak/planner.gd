extends RefCounted

const SEARCH_RADIUS := 32
const FOREST_SEEKERS := [&"foresters_lodge", &"gatherers_hut", &"hunting_cabin"]

var world: WorldGrid
var buildings: BuildController
var labor: LaborManager
var staffing: Dictionary = {}
var builders_target := -1
var builders_month := 6
var _configured: Dictionary = {}
var queue: Array[Dictionary] = []
var placed: Array[String] = []
var skipped: Array[String] = []
var long_run := false
var allow_fuel := true
var _next_management := 0.0


func _init(world_grid: WorldGrid, build: BuildController, labor_manager: LaborManager) -> void:
	world = world_grid
	buildings = build
	labor = labor_manager


func add(id: StringName, month := 0) -> void:
	queue.append({"id": id, "month": month})


func tick() -> void:
	if long_run:
		if TimeManager.get_time_months() >= _next_management:
			_next_management = TimeManager.get_time_months() + 1.0 / 60.0
			_manage_long_run()
		_place()
		return
	_manage()
	_place()


func _manage_long_run() -> void:
	var settlers := world.get_node("Settlers") as SettlerManager
	var workforce := 0
	var housing_needed := false
	for settler in settlers.living_settlers():
		if settler.is_working_age():
			workforce += 1
		if settler.age >= SettlerManager.MARRIAGE_AGE and (settler.home == null or settler.lives_with_parent()):
			housing_needed = true
	var budget := maxi(workforce - 2, 0)
	var desired := {}
	var priorities: Array[StringName] = [&"foresters_lodge", &"woodcutter", &"gatherers_hut", &"hunting_cabin", &"blacksmith", &"mine", &"quarry", &"crop_field_6", &"fishing_dock", &"crop_field_4"]
	for type in priorities:
		var target := int(staffing.get(type, 0))
		if type == &"foresters_lodge" and ResourceStockpile.get_amount(&"logs") > 120:
			target = 0
		if type == &"woodcutter" and (not allow_fuel or ResourceStockpile.get_amount(&"firewood") > 120):
			target = 0
		if type == &"blacksmith" and ResourceStockpile.get_amount(&"tools") >= 20:
			target = 0
		if type == &"mine" and ResourceStockpile.get_amount(&"iron") >= 20:
			target = 0
		if type == &"quarry" and ResourceStockpile.get_amount(&"stone") >= 40:
			target = 0
		if type in [&"crop_field_6", &"crop_field_4", &"gatherers_hut"] and TimeManager.is_cold():
			target = 0
		for building in buildings.get_buildings():
			if building.def.id != type:
				continue
			var count := mini(target, budget)
			desired[building] = count
			budget -= count
	for building in desired:
		building.desired_workers = desired[building]
	labor.reconcile()
	while labor.get_count(Professions.BUILDER) > 1:
		labor.decrease(Professions.BUILDER)
	if labor.get_count(Professions.BUILDER) == 0:
		labor.increase(Professions.BUILDER)
	if not queue.is_empty() or not buildings.get_sites().is_empty():
		return
	var empty_houses := 0
	var food_capacity := 0
	for building in buildings.get_buildings():
		if building.def.housing_capacity > 0 and building.residents.is_empty():
			empty_houses += 1
		if building.storage != null and building.def.accepts(&"wheat"):
			food_capacity += building.storage.capacity
	if housing_needed and empty_houses == 0:
		add(&"house")
	elif ResourceStockpile.get_food_total() > food_capacity * 0.75:
		add(&"storage_barn")


func _manage() -> void:
	for building in buildings.get_buildings():
		var id := building.get_instance_id()
		if _configured.has(id) or not staffing.has(building.def.id):
			continue
		_configured[id] = true
		labor.set_desired_workers(building, mini(staffing[building.def.id], building.def.job.slots))
	_throttle_woodcutter()
	if builders_target >= 0 and TimeManager.month >= builders_month:
		while labor.get_count(Professions.BUILDER) > builders_target and labor.decrease(Professions.BUILDER):
			pass


func _throttle_woodcutter() -> void:
	var firewood := ResourceStockpile.get_amount(&"firewood")
	for building in buildings.get_buildings():
		if building.def.id != &"woodcutter" or not _configured.has(building.get_instance_id()):
			continue
		if firewood > 120 and building.desired_workers > 0:
			labor.set_desired_workers(building, 0)
		elif firewood < 60 and building.desired_workers == 0:
			labor.set_desired_workers(building, 1)


func _place() -> void:
	while not queue.is_empty():
		var item: Dictionary = queue[0]
		if item["month"] > TimeManager.month:
			return
		var def := _def(item["id"])
		if not _affordable(def):
			return
		queue.pop_front()
		var origin := find_spot(def)
		if origin == Vector2i(-1, -1) or not buildings.try_place(def, origin):
			skipped.append("%s@%d" % [def.id, TimeManager.month])
			continue
		placed.append("%s@%d" % [def.id, TimeManager.month])


func find_spot(def: BuildingDef) -> Vector2i:
	var center := WorldGrid.MAP_RECT.get_center()
	var best := Vector2i(-1, -1)
	var best_score := -INF
	for x in range(center.x - SEARCH_RADIUS, center.x + SEARCH_RADIUS):
		for y in range(center.y - SEARCH_RADIUS, center.y + SEARCH_RADIUS):
			var origin := Vector2i(x, y)
			if buildings.get_placement_error(def, origin) != "" or not _has_margin(def, origin):
				continue
			var score := -float(origin.distance_to(center))
			if FOREST_SEEKERS.has(def.id):
				var mid := world.grid_to_world(origin) + Vector2(def.footprint) * 16.0
				score += world.count_terrain_in_radius("forest", mid, def.job.work_radius) * 0.5
			if score > best_score:
				best_score = score
				best = origin
	return best


func _has_margin(def: BuildingDef, origin: Vector2i) -> bool:
	var open_cells := 0
	for x in range(-1, def.footprint.x + 1):
		for y in range(-1, def.footprint.y + 1):
			var cell := origin + Vector2i(x, y)
			var inside := x >= 0 and y >= 0 and x < def.footprint.x and y < def.footprint.y
			if inside:
				continue
			if not world.is_in_bounds(cell) or world.is_occupied(cell):
				return false
			if world.is_walkable(cell):
				open_cells += 1
	return open_cells >= 4


func _affordable(def: BuildingDef) -> bool:
	var committed := {}
	for site in buildings.get_sites():
		for id: StringName in site.required:
			committed[id] = committed.get(id, 0) + site.missing(id)
	for id: StringName in def.cost:
		if ResourceStockpile.get_amount(id) - committed.get(id, 0) < def.cost[id]:
			return false
	return true


func _def(id: StringName) -> BuildingDef:
	return buildings.building_defs[buildings.find_def_index(id)]
