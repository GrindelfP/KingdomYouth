extends Node

const Planner := preload("res://tools/soak/planner.gd")
const SAVE := "user://roundtrip_save.json"
const DIGEST := "user://roundtrip_digest.json"
const TIME_SCALE := 10.0
const SAVE_MONTH := 14

var _phase := "save"
var _world: WorldGrid
var _buildings: BuildController
var _settlers: SettlerManager
var _planner
var _frames := 0
var _site_placed := false


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--phase="):
			_phase = arg.trim_prefix("--phase=")
	seed(7)
	SaveManager.save_path = SAVE
	Engine.time_scale = TIME_SCALE
	var world: Node = load("res://scenes/world/world.tscn").instantiate()
	add_child(world)
	_world = world
	_buildings = world.get_node("Buildings")
	_settlers = world.get_node("Settlers")
	_planner = Planner.new(_world, _buildings, world.get_node("Labor"))
	if _phase == "save":
		for id: StringName in [&"house", &"house", &"house", &"foresters_lodge", &"gatherers_hut", &"crop_field_6", &"woodcutter", &"storage_barn"]:
			_planner.add(id)
		_planner.staffing = {&"foresters_lodge": 1, &"gatherers_hut": 1, &"crop_field_6": 2, &"woodcutter": 1}


func _process(_delta: float) -> void:
	_frames += 1
	if _phase == "save":
		_planner.tick()
		if TimeManager.month >= 2 and _frames == 600:
			_lay_roads()
		if TimeManager.month >= SAVE_MONTH - 1 and not _site_placed:
			_site_placed = true
			var def: BuildingDef = _buildings.building_defs[_buildings.find_def_index(&"crop_field_8")]
			_buildings.try_place(def, _planner.find_spot(def))
		if TimeManager.month >= SAVE_MONTH and TimeManager.get_month_progress() > 0.5:
			_do_save()
	elif _frames == 5:
		if _phase == "old":
			_do_old()
		else:
			_do_load()


func _do_old() -> void:
	set_process(false)
	var file := FileAccess.open(SAVE, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": SaveManager.SAVE_VERSION - 1}))
	file.close()
	var loaded := SaveManager.load_game()
	print("old save loaded=%s error=%s" % [loaded, SaveManager.last_error])
	print("OLD SAVE REJECTED" if not loaded and SaveManager.last_error.contains("older version") else "OLD SAVE CHECK FAIL")
	get_tree().quit(0 if not loaded else 1)


func _lay_roads() -> void:
	var center := WorldGrid.MAP_RECT.get_center()
	_buildings.place_road_line(center + Vector2i(-6, 8), center + Vector2i(6, 8), WorldGrid.Road.DIRT)
	_buildings.place_road_line(center + Vector2i(0, 9), center + Vector2i(0, 14), WorldGrid.Road.STONE)


func _do_save() -> void:
	set_process(false)
	Engine.time_scale = 1.0
	if not SaveManager.save_game():
		print("ROUNDTRIP FAIL: save returned false")
		get_tree().quit(1)
		return
	var digest := _digest()
	var file := FileAccess.open(DIGEST, FileAccess.WRITE)
	file.store_string(JSON.stringify(digest, "\t"))
	file.close()
	print("saved at month %d, pop %d, buildings %d, sites %d, roads %d" % [TimeManager.month, _settlers.population(), digest["buildings"].size(), digest["sites"].size(), digest["roads"]])
	get_tree().quit(0)


func _do_load() -> void:
	set_process(false)
	Engine.time_scale = 1.0
	if not SaveManager.load_game():
		print("ROUNDTRIP FAIL: load returned false: %s" % SaveManager.last_error)
		get_tree().quit(1)
		return
	var expected = JSON.parse_string(FileAccess.get_file_as_string(DIGEST))
	var actual = JSON.parse_string(JSON.stringify(_digest()))
	var bad := 0
	for key in expected:
		if JSON.stringify(expected[key], "", true) != JSON.stringify(actual.get(key), "", true):
			bad += 1
			print("MISMATCH %s\n  expected %s\n  actual   %s" % [key, JSON.stringify(expected[key], "", true).left(400), JSON.stringify(actual.get(key), "", true).left(400)])
	print("loaded: month %d pop %d, %d of %d digest sections differ" % [TimeManager.month, _settlers.population(), bad, expected.size()])
	print("ROUNDTRIP %s" % ("OK" if bad == 0 else "FAIL"))
	get_tree().quit(0 if bad == 0 else 1)


func _digest() -> Dictionary:
	var settlers := []
	for settler in _settlers.living_settlers():
		settlers.append([
			settler.given_name, snappedf(settler.age, 0.001), String(settler.profession), settler.has_tool,
			snappedf(settler.tool_wear, 0.001), str(settler.get_grid_pos()),
			settler.partner.given_name if settler.partner else "", String(settler.carried_id), settler.carried_amount,
			str(settler.home.origin) if settler.home else "",
			snappedf(settler.needs.hunger, 0.01), snappedf(settler.needs.health, 0.01)])
	settlers.sort()
	var buildings := []
	for building in _buildings.get_buildings():
		buildings.append([String(building.def.id), str(building.origin), building.desired_workers,
			building.storage.to_save_data() if building.storage else {},
			building.output.to_save_data() if building.output else {},
			building.input.to_save_data() if building.input else {},
			building.household.to_save_data() if building.household else {},
			building.field.to_save_data() if building.field else {}])
	buildings.sort_custom(func(a: Array, b: Array) -> bool: return a[1] < b[1])
	var sites := []
	for site in _buildings.get_sites():
		sites.append([String(site.def.id), str(site.origin), snappedf(site.progress, 0.001), site.delivered.to_save_data()])
	sites.sort()
	var stock := {}
	for id in ResourceCatalog.all_ids():
		stock[String(id)] = ResourceStockpile.get_amount(id)
	var trees := {}
	for cell in _world.get_tree_cells():
		trees[_world.get_tree_stage(cell)] = trees.get(_world.get_tree_stage(cell), 0) + 1
	var roads := {}
	for cell in _world.get_road_cells():
		roads[_world.get_road(cell)] = roads.get(_world.get_road(cell), 0) + 1
	return {
		"time": [TimeManager.month, snappedf(TimeManager.get_month_progress(), 0.001)],
		"settlers": settlers, "buildings": buildings, "sites": sites, "stock": stock,
		"trees": trees, "road_types": roads, "roads": _world.get_road_cells().size(),
	}
