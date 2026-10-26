extends Node

const SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 10

var pending_load := false
var save_path := SAVE_PATH
var last_error := ""


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func save_game() -> bool:
	var world := _world()
	if world == null:
		return false
	var data := {
		"version": SAVE_VERSION,
		"time": TimeManager.to_save_data(),
		"terrain": world.to_save_data(),
		"buildings": world.get_node("Buildings").to_save_data(),
		"settlers": world.get_node("Settlers").to_save_data(),
	}
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true


func load_game() -> bool:
	last_error = ""
	var world := _world()
	if world == null or not has_save():
		last_error = "No saved game yet."
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if typeof(parsed) != TYPE_DICTIONARY:
		last_error = "The save file is damaged and cannot be loaded."
		return false
	var version := int(parsed.get("version", 0))
	if version < SAVE_VERSION:
		last_error = "This save is from an older version of the game (v%d, current v%d) and cannot be loaded." % [version, SAVE_VERSION]
		return false
	if version > SAVE_VERSION:
		last_error = "This save was made by a newer version of the game (v%d) and cannot be loaded." % version
		return false
	for key in ["time", "terrain", "buildings", "settlers"]:
		if not parsed.has(key):
			last_error = "The save file is damaged and cannot be loaded."
			return false
	var buildings: BuildController = world.get_node("Buildings")
	var settlers: SettlerManager = world.get_node("Settlers")
	TimeManager.from_save_data(parsed["time"])
	settlers.clear_settlers()
	buildings.clear_buildings()
	world.from_save_data(parsed["terrain"])
	buildings.from_save_data(parsed["buildings"])
	settlers.from_save_data(parsed["settlers"], buildings)
	return true


func start_new_game() -> void:
	ResourceStockpile.reset()
	TimeManager.reset()
	pending_load = false
	get_tree().reload_current_scene()


func _world() -> WorldGrid:
	return get_tree().get_first_node_in_group("world") as WorldGrid
