class_name SettlerManager
extends Node2D

signal population_changed(count: int)
signal settler_born(settler: Settler)
signal settler_died(settler: Settler, old_age: bool)
signal settler_grew_up(settler: Settler)

const STARTING_COUPLES := 3
const STARTING_CHILDREN := 3
const STARTING_BUILDERS := 2
const START_ADULT_AGE := Vector2(18.0, 35.0)
const START_CHILD_AGE := Vector2(2.0, 8.0)
const POPULATION_TICK := 1.0
const MARRIAGE_AGE := 16.0
const MOTHER_MAX_AGE := 50.0
const BIRTH_CHANCE := 0.25
const BIRTH_MIN_FOOD := 10
const OLD_AGE_LIMIT := 80.0
const OLD_AGE_BASE_CHANCE := 0.005
const OLD_AGE_RISE := 0.2
const PICK_RADIUS := 12.0
const TIP_LAYER := 4
const TIP_OFFSET := Vector2(16.0, 18.0)
const HEAT_DURATION := 20.0
const FUEL_PER_HEATING := 1
const MALE_NAMES := ["Alder", "Bram", "Cedric", "Dunstan", "Edmund", "Finn", "Godric", "Hale", "Ivo", "Jory", "Kellan", "Leofric", "Merrick", "Osric", "Piers", "Rowan", "Tobin", "Wystan"]
const FEMALE_NAMES := ["Aelwen", "Brenna", "Cora", "Daisy", "Edda", "Freya", "Gwen", "Hild", "Isolde", "Joan", "Maud", "Nell", "Odette", "Petra", "Rosamund", "Sunniva", "Thea", "Wilma"]

var _world: WorldGrid
var _pathfinder: GridPathfinder
var _buildings: BuildController
var _tick_accumulator := 0.0
var _next_display_id := 1
var _hovered: Settler
var _tip_panel: PanelContainer
var _tip_label: Label


func _ready() -> void:
	_world = get_parent()
	_pathfinder = get_parent().get_node("Pathfinder")
	_buildings = get_parent().get_node("Buildings")
	_world.map_generated.connect(_spawn_starting_settlers)
	TimeManager.month_changed.connect(_on_month_changed)
	var layer := CanvasLayer.new()
	layer.layer = TIP_LAYER
	add_child(layer)
	_tip_panel = PanelContainer.new()
	_tip_panel.theme = UiTheme.load_theme()
	_tip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip_panel.visible = false
	_tip_label = Label.new()
	_tip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip_panel.add_child(_tip_label)
	layer.add_child(_tip_panel)


func hovered_settler() -> Settler:
	return _hovered if is_instance_valid(_hovered) else null


func _update_hover() -> void:
	var target: Settler = null
	var buildings := _world.get_node_or_null("Buildings") as BuildController
	var blocked := get_viewport().gui_get_hovered_control() != null or (buildings != null and buildings.is_placing())
	if not blocked:
		var mouse := get_global_mouse_position()
		var best := PICK_RADIUS
		for settler in living_settlers():
			var distance := settler.global_position.distance_to(mouse)
			if distance <= best:
				best = distance
				target = settler
	if target != _hovered:
		if is_instance_valid(_hovered):
			_hovered.set_hovered(false)
		_hovered = target
		if target != null:
			target.set_hovered(true)
	_tip_panel.visible = target != null
	if target != null:
		_tip_label.text = target.tooltip_text()
		_tip_panel.position = get_viewport().get_mouse_position() + TIP_OFFSET


func _process(delta: float) -> void:
	_update_hover()
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


func count_by_stage() -> Array[int]:
	var counts: Array[int] = [0, 0, 0]
	for settler in living_settlers():
		counts[settler.get_age_stage()] += 1
	return counts


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
	var total := STARTING_COUPLES * 2 + STARTING_CHILDREN
	if cells.size() < total:
		return
	var index := 0
	var fathers: Array[Settler] = []
	var mothers: Array[Settler] = []
	for i in STARTING_COUPLES:
		var father := _spawn_settler(cells[index], Settler.Sex.MALE, randf_range(START_ADULT_AGE.x, START_ADULT_AGE.y))
		var mother := _spawn_settler(cells[index + 1], Settler.Sex.FEMALE, randf_range(START_ADULT_AGE.x, START_ADULT_AGE.y))
		index += 2
		father.partner = mother
		mother.partner = father
		fathers.append(father)
		mothers.append(mother)
	for i in STARTING_CHILDREN:
		var child := _spawn_settler(cells[index], Settler.Sex.MALE if randf() < 0.5 else Settler.Sex.FEMALE, randf_range(START_CHILD_AGE.x, START_CHILD_AGE.y))
		index += 1
		child.parents = [fathers[i % fathers.size()], mothers[i % mothers.size()]]
	var builders := 0
	for settler in living_settlers():
		if builders < STARTING_BUILDERS and settler.get_age_stage() == Settler.AgeStage.ADULT:
			settler.profession = Professions.BUILDER
			builders += 1


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
			"name": settler.given_name,
			"sex": settler.sex,
			"age": settler.age,
			"partner": settler.partner.display_id if settler.partner else -1,
			"parents": settler.parents.map(func(parent: Settler) -> int: return parent.display_id),
			"profession": String(settler.profession),
			"has_tool": settler.has_tool,
			"tool_wear": settler.tool_wear,
			"home": WorldGrid.cell_to_json(settler.home.origin) if settler.home else null,
			"job": WorldGrid.cell_to_json(settler.worker.building.origin) if settler.worker.building else null,
		})
	return entries


func from_save_data(entries: Array, buildings: BuildController) -> void:
	clear_settlers()
	var by_id := {}
	for entry in entries:
		var settler := _spawn_settler(WorldGrid.cell_from_json(entry["cell"]), int(entry["sex"]) as Settler.Sex, float(entry["age"]))
		settler.given_name = String(entry["name"])
		by_id[int(entry["display_id"])] = settler
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
	for entry in entries:
		var settler: Settler = by_id[int(entry["display_id"])]
		if int(entry["partner"]) >= 0 and by_id.has(int(entry["partner"])):
			settler.partner = by_id[int(entry["partner"])]
		for parent_id in entry["parents"]:
			if by_id.has(int(parent_id)):
				settler.parents.append(by_id[int(parent_id)])


func _spawn_settler(grid_pos: Vector2i, sex: Settler.Sex, age: float) -> Settler:
	var settler := Settler.new()
	settler.sex = sex
	settler.age = age
	settler.given_name = _random_name(sex)
	settler.display_id = _next_display_id
	_next_display_id += 1
	add_child(settler)
	settler.setup(_world, _pathfinder, _buildings, grid_pos)
	settler.needs.died.connect(_on_settler_died.bind(settler))
	population_changed.emit(population())
	return settler


func _random_name(sex: Settler.Sex) -> String:
	var names: Array = MALE_NAMES if sex == Settler.Sex.MALE else FEMALE_NAMES
	return names[randi() % names.size()]


func _population_tick(dt: float) -> void:
	_update_housing()
	_update_heating(dt)


func _on_month_changed(_month: int) -> void:
	for settler in living_settlers():
		var before := settler.get_age_stage()
		settler.set_age(settler.age + 1.0 / TimeManager.MONTHS_PER_YEAR)
		if before == Settler.AgeStage.CHILD and settler.is_working_age():
			settler_grew_up.emit(settler)
		elif settler.age >= Settler.ELDER_AGE and _dies_of_old_age(settler):
			_remove_settler(settler, true)
	_update_births()


func _dies_of_old_age(settler: Settler) -> bool:
	if settler.age >= OLD_AGE_LIMIT:
		return true
	var t := (settler.age - Settler.ELDER_AGE) / (OLD_AGE_LIMIT - Settler.ELDER_AGE)
	return randf() < OLD_AGE_BASE_CHANCE + OLD_AGE_RISE * t * t


func _update_heating(dt: float) -> void:
	for house in _houses():
		if not TimeManager.is_cold():
			house.heat_left = 0.0
			continue
		house.heat_left = maxf(house.heat_left - dt, 0.0)
		if not house.is_heated() and house.residents.size() > 0:
			if house.household.take(Building.FUEL_ID, FUEL_PER_HEATING) > 0:
				house.heat_left = HEAT_DURATION


func _update_housing() -> void:
	_pair_singles()
	_house_couples()
	_house_singles()
	_house_followers()
	_house_remaining()


func _is_pairable(settler: Settler) -> bool:
	if settler.partner != null or settler.get_age_stage() != Settler.AgeStage.ADULT or settler.age < MARRIAGE_AGE:
		return false
	return settler.home == null or settler.home.residents.size() == 1 or settler.lives_with_parent()


func _is_lone(settler: Settler) -> bool:
	return settler.home != null and settler.home.residents.size() == 1


func _pair_singles() -> void:
	var pool: Array[Settler] = []
	for settler in living_settlers():
		if _is_pairable(settler):
			pool.append(settler)
	for a in pool:
		if a.partner != null:
			continue
		for b in pool:
			if b == a or b.partner != null or b.sex == a.sex or a.is_kin_of(b):
				continue
			var house := _pair_house(a, b)
			if house == null:
				continue
			a.partner = b
			b.partner = a
			for settler in [a, b]:
				if settler.home != house:
					settler.assign_home(house)
			break


func _pair_house(a: Settler, b: Settler) -> Building:
	if a.home == b.home and a.home != null:
		return null
	if _is_lone(a):
		return a.home
	if _is_lone(b):
		return b.home
	return _empty_house()


func _house_couples() -> void:
	for settler in living_settlers():
		var mate := settler.partner
		if mate == null or settler.home != null or mate.home != null or settler.display_id > mate.display_id:
			continue
		var house := _empty_house()
		if house == null:
			return
		settler.assign_home(house)
		mate.assign_home(house)


func _house_singles() -> void:
	var candidates: Array[Settler] = []
	for settler in living_settlers():
		if settler.partner == null and settler.get_age_stage() == Settler.AgeStage.ADULT and settler.age >= MARRIAGE_AGE:
			if settler.home == null:
				candidates.push_front(settler)
			elif settler.lives_with_parent():
				candidates.append(settler)
	for settler in candidates:
		var house := _empty_house()
		if house == null:
			return
		settler.assign_home(house)


func _house_followers() -> void:
	for settler in living_settlers():
		if settler.home != null:
			continue
		var targets: Array[Building] = []
		if settler.partner != null and settler.partner.home != null:
			targets.append(settler.partner.home)
		for parent in settler.parents:
			if parent.home != null:
				targets.append(parent.home)
		for house in targets:
			if house.has_free_housing():
				settler.assign_home(house)
				break


func _house_remaining() -> void:
	for settler in living_settlers():
		if settler.home != null or settler.partner != null:
			continue
		var stage := settler.get_age_stage()
		if stage == Settler.AgeStage.ADULT or (stage == Settler.AgeStage.CHILD and not settler.parents.is_empty()):
			continue
		var house := _house_with_room()
		if house:
			settler.assign_home(house)


func _empty_house() -> Building:
	for house in _houses():
		if house.residents.is_empty():
			return house
	return null


func _house_with_room() -> Building:
	var best: Building = null
	for house in _houses():
		if not house.has_free_housing():
			continue
		if best == null or house.residents.size() < best.residents.size():
			best = house
	return best


func _update_births() -> void:
	for house in _houses():
		if not house.has_free_housing() or house.food_stock() < BIRTH_MIN_FOOD:
			continue
		var mother := _fertile_mother(house)
		if mother == null or randf() >= BIRTH_CHANCE:
			continue
		var cells := house.get_access_cells()
		if cells.is_empty():
			continue
		var newborn := _spawn_settler(cells[0], Settler.Sex.MALE if randf() < 0.5 else Settler.Sex.FEMALE, 0.0)
		newborn.parents = [mother, mother.partner]
		newborn.assign_home(house)
		settler_born.emit(newborn)


func _fertile_mother(house: Building) -> Settler:
	for settler in house.residents:
		if settler.sex == Settler.Sex.FEMALE and settler.partner != null and settler.partner.home == house \
				and settler.age >= MARRIAGE_AGE and settler.age < MOTHER_MAX_AGE:
			return settler
	return null


func _on_settler_died(settler: Settler) -> void:
	_remove_settler(settler, false)


func _remove_settler(settler: Settler, old_age: bool) -> void:
	if settler.is_queued_for_deletion():
		return
	for other in living_settlers():
		if other.partner == settler:
			other.partner = null
		other.parents.erase(settler)
	settler.worker.unassign()
	settler.unassign_home()
	settler.queue_free()
	settler_died.emit(settler, old_age)
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
