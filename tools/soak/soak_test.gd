extends Node

const Planner := preload("res://tools/soak/planner.gd")
const WORLD_SCENE := "res://scenes/world/world.tscn"
const TIME_SCALE := 10.0
const FRAME_STEP := 1.0 / 30.0
const STUCK_SECONDS := 90.0

var _mode := "planned"
var _years := 3
var _world: WorldGrid
var _buildings: BuildController
var _settlers: SettlerManager
var _planner
var _frames := 0
var _last_logged := -1
var _min_pop := 999
var _starved_months := 0
var _idle_since: Dictionary = {}
var _frozen: Dictionary = {}
var _frozen_reports: Array[String] = []
var _stuck_reports := 0
var _peak_pop := 0
var _first_death_month := -1
var _population_zero_month := -1


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--mode="):
			_mode = arg.trim_prefix("--mode=")
		elif arg.begins_with("--years="):
			_years = int(arg.trim_prefix("--years="))
	seed(1)
	SaveManager.save_path = "user://soak_save.json"
	Engine.time_scale = TIME_SCALE
	var world: Node = load(WORLD_SCENE).instantiate()
	add_child(world)
	_world = world
	_buildings = world.get_node("Buildings")
	_settlers = world.get_node("Settlers")
	_planner = Planner.new(_world, _buildings, world.get_node("Labor"))
	_queue_plan()
	print("soak mode=%s years=%d" % [_mode, _years])
	print("year season | pop (A C E) | food firewood logs tools stone iron | stored/cap | buildings sites | house food/fw avg | avg health")


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
	_planner.builders_target = 1
	_planner.add(&"hunting_cabin", 2)
	_planner.add(&"house", 3)
	_planner.add(&"crop_field_4", 4)
	_planner.add(&"fishing_dock", 5)
	_planner.add(&"house", 6)
	_planner.add(&"quarry", 8)
	_planner.add(&"mine", 10)
	_planner.add(&"blacksmith", 12)
	_planner.add(&"house", 14)
	_planner.add(&"crop_field_6", 14)
	_planner.add(&"storage_barn", 16)
	_planner.add(&"house", 18)


func _process(_delta: float) -> void:
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
	if _first_death_month < 0 and pop < _peak_pop:
		_first_death_month = TimeManager.month
	if pop == 0 and _population_zero_month < 0:
		_population_zero_month = TimeManager.month
	if _frames % 60 != 0:
		return
	for settler in _settlers.living_settlers():
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
		var moving := state != "Idle" and state != "Work" and state != "Build" and not settler.worker.is_paused()
		var cell := settler.get_grid_pos()
		var record: Dictionary = _frozen.get(key, {})
		if not moving or record.get("cell") != cell:
			_frozen[key] = {"cell": cell, "since": TimeManager.get_time_months(), "reported": false}
		elif TimeManager.get_time_months() - float(record["since"]) > 0.75 and not record["reported"]:
			record["reported"] = true
			_frozen_reports.append("m%d %s %s %s at %s carrying %s" % [TimeManager.month, settler.given_name, settler.profession, state, cell, settler.carried_id])
	for key in _idle_since.keys():
		if not is_instance_id_valid(key):
			_idle_since.erase(key)


func _log_row() -> void:
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
			long_idle += " " + String(instance_from_id(key).profession)
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
	print("done month=%d pop=%d peak=%d min=%d first_death_month=%d extinct_month=%d frames=%d" % [
		TimeManager.month, _settlers.population(), _peak_pop, _min_pop, _first_death_month, _population_zero_month, _frames])
	print("placed: %s" % ", ".join(_planner.placed))
	print("skipped: %s" % ", ".join(_planner.skipped))
	print("frozen reports: %d" % _frozen_reports.size())
	for line in _frozen_reports.slice(0, 12):
		print("  " + line)
	Engine.time_scale = 1.0
	if FileAccess.file_exists(SaveManager.save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveManager.save_path))
	set_process(false)
	get_tree().quit(0)
