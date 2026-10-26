extends Node

const SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 4

var pending_load := false


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


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
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true


func load_game() -> bool:
	var world := _world()
	if world == null or not has_save():
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("version", 0)) != SAVE_VERSION:
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
