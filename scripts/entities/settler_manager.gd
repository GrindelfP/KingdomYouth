class_name SettlerManager
extends Node2D

signal population_changed(count: int)
signal settler_born(settler: Settler)
signal settler_died(settler: Settler)

const STARTING_SETTLER_COUNT := 5
const STARTING_BUILDERS := 2
const POPULATION_TICK := 1.0
const BIRTH_COOLDOWN := 45.0
const BIRTH_MIN_FOOD := 10
const MIN_PARENTS := 2
const HEAT_DURATION := 20.0
const FUEL_PER_HEATING := 1

var _world: WorldGrid
var _pathfinder: GridPathfinder
var _buildings: BuildController
var _tick_accumulator := 0.0
var _next_display_id := 1


func _ready() -> void:
	_world = get_parent()
	_pathfinder = get_parent().get_node("Pathfinder")
	_buildings = get_parent().get_node("Buildings")
	_world.map_generated.connect(_spawn_starting_settlers)


func _process(delta: float) -> void:
	_tick_accumulator += delta
	while _tick_accumulator >= POPULATION_TICK:
		_tick_accumulator -= POPULATION_TICK
		_population_tick(POPULATION_TICK)


func population() -> int:
	return living_settlers().size()


func employed_count() -> int:
	var count := 0
	for settler in living_settlers():
		if settler.worker.building != null:
			count += 1
	return count


func _spawn_starting_settlers() -> void:
	var bounds := _world.get_map_bounds()
	var center := bounds.get_center()
	var cells: Array[Vector2i] = []
	for x in range(bounds.position.x, bounds.end.x):
		for y in range(bounds.position.y, bounds.end.y):
			var grid_pos := Vector2i(x, y)
			if _world.is_walkable(grid_pos):
				cells.append(grid_pos)
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.distance_squared_to(center) < b.distance_squared_to(center))
	for i in mini(STARTING_SETTLER_COUNT, cells.size()):
		var settler := _spawn_settler(cells[i])
		if i < STARTING_BUILDERS:
			settler.profession = Professions.BUILDER


func clear_settlers() -> void:
	for child in get_children():
		remove_child(child)
		child.free()
	_next_display_id = 1


func to_save_data() -> Array:
	var entries := []
	for settler in living_settlers():
		entries.append({
			"display_id": settler.display_id,
			"cell": WorldGrid.cell_to_json(settler.get_grid_pos()),
			"hunger": settler.needs.hunger,
			"rest": settler.needs.rest,
			"warmth": settler.needs.warmth,
			"health": settler.needs.health,
			"carried_id": String(settler.carried_id),
			"carried_amount": settler.carried_amount,
			"profession": String(settler.profession),
			"has_tool": settler.has_tool,
			"tool_wear": settler.tool_wear,
			"home": WorldGrid.cell_to_json(settler.home.origin) if settler.home else null,
			"job": WorldGrid.cell_to_json(settler.worker.building.origin) if settler.worker.building else null,
		})
	return entries


func from_save_data(entries: Array, buildings: BuildController) -> void:
	clear_settlers()
	for entry in entries:
		var settler := _spawn_settler(WorldGrid.cell_from_json(entry["cell"]))
		settler.display_id = int(entry["display_id"])
		_next_display_id = maxi(_next_display_id, settler.display_id + 1)
		settler.needs.hunger = float(entry["hunger"])
		settler.needs.rest = float(entry["rest"])
		settler.needs.warmth = float(entry["warmth"])
		settler.needs.health = float(entry["health"])
		if int(entry["carried_amount"]) > 0 and ResourceCatalog.has(StringName(entry["carried_id"])):
			settler.set_carried(StringName(entry["carried_id"]), int(entry["carried_amount"]))
		settler.has_tool = bool(entry["has_tool"])
		settler.tool_wear = float(entry["tool_wear"])
		var profession := StringName(entry["profession"])
		settler.profession = profession if profession == Professions.BUILDER else Professions.LABORER
		if entry["home"] != null:
			var house := buildings.find_building(WorldGrid.cell_from_json(entry["home"]))
			if house:
				settler.assign_home(house)
		if entry["job"] != null:
			var job_building := buildings.find_building(WorldGrid.cell_from_json(entry["job"]))
			if job_building:
				settler.worker.assign(job_building)


func _spawn_settler(grid_pos: Vector2i) -> Settler:
	var settler := Settler.new()
	settler.display_id = _next_display_id
	_next_display_id += 1
	add_child(settler)
	settler.setup(_world, _pathfinder, _buildings, grid_pos)
	settler.needs.died.connect(_on_settler_died.bind(settler))
	population_changed.emit(population())
	return settler


func _population_tick(dt: float) -> void:
	_assign_homeless()
	_update_heating(dt)
	_update_births(dt)


func _update_heating(dt: float) -> void:
	for house in _houses():
		if not TimeManager.is_cold():
			house.heat_left = 0.0
			continue
		house.heat_left = maxf(house.heat_left - dt, 0.0)
		if not house.is_heated() and house.residents.size() > 0:
			if house.household.take(Building.FUEL_ID, FUEL_PER_HEATING) > 0:
				house.heat_left = HEAT_DURATION


func _assign_homeless() -> void:
	for settler in living_settlers():
		if settler.home == null:
			var house := _house_with_room()
			if house:
				settler.assign_home(house)


func _house_with_room() -> Building:
	var best: Building = null
	for house in _houses():
		if not house.has_free_housing():
			continue
		if best == null or house.residents.size() < best.residents.size():
			best = house
	return best


func _update_births(dt: float) -> void:
	for house in _houses():
		house.birth_cooldown = maxf(house.birth_cooldown - dt, 0.0)
		if house.birth_cooldown > 0.0 or not house.has_free_housing():
			continue
		if house.residents.size() < MIN_PARENTS or house.food_stock() < BIRTH_MIN_FOOD:
			continue
		var cells := house.get_access_cells()
		if cells.is_empty():
			continue
		house.birth_cooldown = BIRTH_COOLDOWN
		var newborn := _spawn_settler(cells[0])
		newborn.assign_home(house)
		settler_born.emit(newborn)


func _on_settler_died(settler: Settler) -> void:
	settler.worker.unassign()
	settler.unassign_home()
	settler.queue_free()
	settler_died.emit(settler)
	population_changed.emit(population())


func living_settlers() -> Array[Settler]:
	var settlers: Array[Settler] = []
	for child in get_children():
		if child is Settler and not child.is_queued_for_deletion():
			settlers.append(child as Settler)
	return settlers


func _houses() -> Array[Building]:
	var houses: Array[Building] = []
	for child in _buildings.get_children():
		if child is Building and child.def.housing_capacity > 0:
			houses.append(child as Building)
	return houses
