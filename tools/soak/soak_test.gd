extends Node

const Planner := preload("res://tools/soak/planner.gd")
const WORLD_SCENE := "res://scenes/world/world.tscn"
const TIME_SCALE := 10.0
const STUCK_SECONDS := 90.0

var _mode := "planned"
var _years := 20
var _seed := 1
var _births := 0
var _grown := 0
var _grown_ids: Dictionary = {}
var _worked: Dictionary = {}
var _successors: Dictionary = {}
var _successor_houses: Dictionary = {}
var _deaths := {"hunger": 0, "cold": 0, "exposure": 0, "old_age": 0}
var _expected: Dictionary = {}
var _flow_seen: Dictionary = {}
var _audit_failures: Array[String] = []
var _world: WorldGrid
var _buildings: BuildController
var _settlers: SettlerManager
var _planner
var _frames := 0
var _last_logged := -1
var _min_pop := 999
var _idle_since: Dictionary = {}
var _frozen: Dictionary = {}
var _frozen_reports: Array[String] = []
var _peak_pop := 0
var _first_death_month := -1
var _population_zero_month := -1


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--mode="):
			_mode = arg.trim_prefix("--mode=")
		elif arg.begins_with("--years="):
			_years = int(arg.trim_prefix("--years="))
		elif arg.begins_with("--seed="):
			_seed = int(arg.trim_prefix("--seed="))
	if not _mode in ["planned", "nowood", "neglect"] or _years < 1:
		get_tree().quit(2)
		return
	seed(_seed)
	SaveManager.save_path = "user://soak_save.json"
	Engine.time_scale = TIME_SCALE
	var world: Node = load(WORLD_SCENE).instantiate()
	add_child(world)
	_world = world
	_buildings = world.get_node("Buildings")
	_settlers = world.get_node("Settlers")
	_settlers.settler_born.connect(func(_settler: Settler) -> void: _births += 1)
	_settlers.settler_grew_up.connect(func(settler: Settler) -> void:
		_grown += 1
		_grown_ids[settler.display_id] = true)
	_settlers.settler_died.connect(_on_death)
	_planner = Planner.new(_world, _buildings, world.get_node("Labor"))
	_queue_plan()
	print("soak mode=%s years=%d random_seed=%d map_seed=%d" % [_mode, _years, _seed, WorldGrid.MAP_SEED])
	print("year season | pop (A C E) | stored food, stored+occupied-house fuel, stored logs tools stone iron | stored/cap | buildings sites | occupied-house food/fw sums | avg health")


func _queue_plan() -> void:
	if _mode == "neglect":
		for i in 3:
			_planner.add(&"house")
		return
	for id: StringName in [&"house", &"house", &"house", &"foresters_lodge", &"gatherers_hut", &"crop_field_6", &"woodcutter"]:
		if _mode == "nowood" and id == &"woodcutter":
			continue
		_planner.add(id)
	_planner.staffing = {&"foresters_lodge": 1, &"gatherers_hut": 1, &"crop_field_6": 2, &"crop_field_4": 2, &"woodcutter": 1, &"hunting_cabin": 1, &"fishing_dock": 1, &"quarry": 1, &"mine": 1, &"blacksmith": 1}
	_planner.long_run = true
	_planner.allow_fuel = _mode != "nowood"
	_planner.add(&"quarry", 8)
	_planner.add(&"mine", 10)
	_planner.add(&"blacksmith", 12)
	_planner.add(&"hunting_cabin", 14)


func _process(_delta: float) -> void:
	if _frames == 0:
		_expected = _inventory()[&"total"].duplicate()
		_remember_flows(false)
	_frames += 1
	_planner.tick()
	_track()
	var month := TimeManager.month
	if month != _last_logged and month % TimeManager.MONTHS_PER_SEASON == 0:
		_last_logged = month
		_log_row()
	if month >= _years * TimeManager.MONTHS_PER_YEAR or (_mode == "neglect" and _settlers.population() == 0):
		_finish()


func _track() -> void:
	var pop := _settlers.population()
	_peak_pop = maxi(_peak_pop, pop)
	_min_pop = mini(_min_pop, pop)
	if pop == 0 and _population_zero_month < 0:
		_population_zero_month = TimeManager.month
	if _frames % 60 != 0:
		return
	for settler in _settlers.living_settlers():
		if _grown_ids.has(settler.display_id) and settler.worker.is_working():
			_worked[settler.display_id] = true
		if not settler.parents.is_empty() and settler.partner != null and settler.home != null and not settler.lives_with_parent():
			_successors[settler.display_id] = true
			_successor_houses[settler.home.origin] = true
		var idle := settler.worker.get_state_name() == "Idle" and not settler.worker.is_paused() and settler.is_working_age() and not settler.is_carrying()
		var key := settler.get_instance_id()
		if idle:
			if not _idle_since.has(key):
				_idle_since[key] = TimeManager.get_time_months()
		else:
			_idle_since.erase(key)
	for settler in _settlers.living_settlers():
		var state: String = settler.worker.get_state_name()
		var key := settler.get_instance_id()
		var moving := (settler.is_moving() or state in ["Travel", "Pickup", "Deliver", "Return"]) and not settler.worker.is_paused()
		var cell := settler.get_grid_pos()
		var record: Dictionary = _frozen.get(key, {})
		if not moving or record.get("cell") != cell:
			_frozen[key] = {"cell": cell, "since": TimeManager.get_time_months(), "reported": false}
		elif (TimeManager.get_time_months() - float(record["since"])) * TimeManager.SECONDS_PER_MONTH > STUCK_SECONDS and not record["reported"]:
			record["reported"] = true
			_frozen_reports.append("m%d %s %s %s at %s carrying %s" % [TimeManager.month, settler.given_name, settler.profession, state, cell, settler.carried_id])
	for key in _idle_since.keys():
		if not is_instance_id_valid(key):
			_idle_since.erase(key)


func _log_row() -> void:
	_audit()
	var inventory := _inventory()
	var food_ids := ResourceCatalog.ids_in_category(ResourceDef.Category.FOOD)
	var locations := []
	for location in TownInventory.LOCATIONS + [&"total"]:
		locations.append("%s=%d/%d/%d" % [location, TownInventory.amount(inventory, location, food_ids), TownInventory.amount(inventory, location, [&"firewood"]), TownInventory.amount(inventory, location, [&"tools"])])
	var labor := _world.get_node("Labor") as LaborManager
	var staffing := {}
	for profession in labor.profession_ids():
		var count := labor.get_count(profession)
		if count > 0:
			staffing[profession] = count
	print("  food/fuel/tools %s births=%d grew=%d worked=%d successors=%d households=%d deaths=%s workforce=%d staffing=%s" % [" ".join(locations), _births, _grown, _worked.size(), _successors.size(), _successor_houses.size(), _deaths, _settlers.count_by_stage()[1] + _settlers.count_by_stage()[2], staffing])
	var stages := _settlers.count_by_stage()
	var food_hh := 0
	var fw_hh := 0
	var houses := 0
	var buildings := 0
	for building in _buildings.get_buildings():
		buildings += 1
		if building.household != null and not building.residents.is_empty():
			houses += 1
			food_hh += building.food_stock()
			fw_hh += building.firewood_stock()
	var health := 0.0
	var living := _settlers.living_settlers()
	for settler in living:
		health += settler.needs.health
	var long_idle := ""
	for key in _idle_since:
		if TimeManager.get_time_months() - _idle_since[key] > 1.5 and is_instance_id_valid(key):
			var settler := instance_from_id(key) as Settler
			var reason := WorkplaceStatus.for_worker(settler.worker.building, settler) if settler.worker.building != null else "Unassigned labor reserve"
			long_idle += " %s[%s]" % [settler.profession, reason]
	print("Y%d %-6s | %3d (%d %d %d) | %4d %4d %4d %3d %3d %3d | %4d/%4d | %2d %2d | %3d/%3d | %5.1f | idle>1.5mo:%s" % [
		TimeManager.get_year(), TimeManager.get_season_name(), _settlers.population(),
		stages[1], stages[0], stages[2],
		ResourceStockpile.get_food_total(), ResourceStockpile.get_amount(&"firewood") + fw_hh,
		ResourceStockpile.get_amount(&"logs"), ResourceStockpile.get_amount(&"tools"),
		ResourceStockpile.get_amount(&"stone"), ResourceStockpile.get_amount(&"iron"),
		ResourceStockpile.get_stored_total(), ResourceStockpile.get_capacity(),
		buildings, _buildings.get_sites().size(), food_hh, fw_hh,
		health / maxf(1.0, living.size()), long_idle])


func _finish() -> void:
	if _last_logged != TimeManager.month:
		_log_row()
	_audit()
	print("done month=%d pop=%d peak=%d min=%d first_death_month=%d extinct_month=%d frames=%d" % [
		TimeManager.month, _settlers.population(), _peak_pop, _min_pop, _first_death_month, _population_zero_month, _frames])
	print("placed: %s" % ", ".join(_planner.placed))
	print("skipped: %s" % ", ".join(_planner.skipped))
	print("frozen reports: %d" % _frozen_reports.size())
	for line in _frozen_reports.slice(0, 12):
		print("  " + line)
	print("demography births=%d grew=%d worked=%d successors=%d households=%d deaths=%s inventory_failures=%d" % [_births, _grown, _worked.size(), _successors.size(), _successor_houses.size(), _deaths, _audit_failures.size()])
	for line in _audit_failures.slice(0, 12):
		print("  " + line)
	var passed := _frozen_reports.is_empty() and _audit_failures.is_empty()
	if _mode == "planned":
		passed = passed and _settlers.population() > 0
		if _years >= 20:
			passed = passed and not _worked.is_empty() and not _successor_houses.is_empty()
			passed = passed and _deaths["hunger"] == 0 and _deaths["cold"] == 0 and _deaths["exposure"] == 0
	else:
		passed = passed and _settlers.population() == 0 and _deaths["hunger" if _mode == "neglect" else "cold"] > 0
	print("VERDICT: %s" % ("PASS" if passed else "FAIL"))
	Engine.time_scale = 1.0
	if FileAccess.file_exists(SaveManager.save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveManager.save_path))
	set_process(false)
	get_tree().quit(0 if passed else 1)


func _on_death(settler: Settler, old_age: bool) -> void:
	var cause := "old_age" if old_age else ("hunger" if settler.needs.is_starving() else ("cold" if settler.needs.warmth <= 0.0 else "exposure"))
	_deaths[cause] += 1
	if _first_death_month < 0:
		_first_death_month = TimeManager.month
	print("death month=%d id=%d age=%.1f cause=%s profession=%s" % [TimeManager.month, settler.display_id, settler.age, cause, settler.profession])


func _inventory() -> Dictionary:
	return TownInventory.snapshot(_buildings.get_buildings(), _buildings.get_sites(), _settlers.living_settlers())


func _remember_flows(apply: bool) -> void:
	for record: Dictionary in EconomyHistory.records:
		for flow: String in EconomyHistory.FLOWS:
			for id: String in record[flow]:
				var key := "%d/%s/%s" % [record["season"], flow, id]
				var amount := int(record[flow][id])
				var difference := amount - int(_flow_seen.get(key, 0))
				_flow_seen[key] = amount
				if apply:
					var sign_value := 1 if flow in ["produced", "imported"] else -1
					_expected[StringName(id)] = int(_expected.get(StringName(id), 0)) + difference * sign_value


func _audit() -> void:
	_remember_flows(true)
	var actual: Dictionary = _inventory()[&"total"]
	for id in ResourceCatalog.all_ids():
		var difference := int(actual.get(id, 0)) - int(_expected.get(id, 0))
		if difference != 0:
			_audit_failures.append("month=%d %s unexplained=%d" % [TimeManager.month, id, difference])
			_expected[id] = int(actual.get(id, 0))
