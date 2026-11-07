extends Node

var failures := 0
var notices: Array[String] = []


func _ready() -> void:
	TimeManager.set_process(false)
	TimeManager.reset()
	EconomyHistory.set_process(false)
	EconomyHistory.reset()
	var source := Inventory.new(20)
	var destination := Inventory.new(20)
	source.produce(&"berries", 12)
	destination.add(&"berries", source.take(&"berries", 5))
	var needs := Needs.new()
	needs.eat_from(destination)
	_check(_amount("produced", "berries") == 12, "creation recorded once")
	_check(_amount("consumed", "berries") == 1, "meal recorded by good")
	_check(_amount("lost", "berries") == 0, "transfer is not loss")
	_check(destination.total() + source.total() == 11, "transfer conservation")
	source.produce(&"berries", 20)
	_check(_amount("produced", "berries") == 32 and _amount("lost", "berries") == 7, "production overflow explicit")
	EconomyHistory.record("imported", &"logs", 3)
	EconomyHistory.record("exported", &"stone", 2)
	_check(_amount("imported", "logs") == 3 and _amount("exported", "stone") == 2, "trade hooks")
	TimeManager.advance(180.0)
	destination.consume(&"berries", 2)
	_check(EconomyHistory.records.size() == 2 and _amount("consumed", "berries") == 2, "season separation")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(EconomyHistory.to_save_data()))
	EconomyHistory.reset()
	EconomyHistory.from_save_data(saved)
	_check(JSON.stringify(EconomyHistory.to_save_data()) == JSON.stringify(saved), "history JSON round-trip")
	TimeManager.advance(81 * 180.0)
	_check(EconomyHistory.records.size() == 80, "20-year rolling window includes current season")
	needs.free()
	await _integration()
	print("ECONOMY %s" % ("OK" if failures == 0 else "FAIL"))
	get_tree().quit(0 if failures == 0 else 1)


func _amount(flow: String, id: String) -> int:
	return int(EconomyHistory.current()[flow].get(id, 0))


func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error("Economy check failed: " + label)


func _integration() -> void:
	TimeManager.reset()
	var world: WorldGrid = load("res://scenes/world/world.tscn").instantiate()
	add_child(world)
	await get_tree().process_frame
	await get_tree().process_frame
	world.process_mode = Node.PROCESS_MODE_DISABLED
	EconomyHistory.reset()
	var build: BuildController = world.get_node("Buildings")
	var people: SettlerManager = world.get_node("Settlers")
	var settler := people.living_settlers()[0]
	settler.worker.cancel_task()
	var work := build.add_building(_def(build, &"woodcutter"), Vector2i(5, 5))
	_check(WorkplaceStatus.describe(work).begins_with("No workers"), "no-worker reason")
	work.desired_workers = 0
	_check(WorkplaceStatus.describe(work).begins_with("Intentionally paused"), "intentional pause distinct")
	work.desired_workers = 1
	settler.worker.assign(work)
	settler.worker.resume()
	work.input.add(&"logs", 2)
	settler.worker._action = Worker.Action.HARVEST
	settler.worker._finish_work()
	_check(_amount("produced", "firewood") == 3 and _amount("consumed", "logs") == 1, "real crafting completion")
	work.input.take(&"logs", 1)
	var stored_logs := ResourceStockpile.get_amount(&"logs")
	ResourceStockpile.remove(&"logs", stored_logs)
	_check(WorkplaceStatus.describe(work).begins_with("No input: Logs"), "no-input reason")
	ResourceStockpile.add(&"logs", stored_logs)
	var source_building := ResourceStockpile.find_sources(&"logs", settler.get_grid_pos())[0]
	var transfer_history := JSON.stringify(EconomyHistory.to_save_data())
	settler.worker._hauler._take(source_building.get_instance_id(), source_building.storage, &"logs", 1, func(_n: int) -> void: pass)
	settler.worker._hauler._put(work.get_instance_id(), work.input, func(_n: int) -> void: pass)
	_check(JSON.stringify(EconomyHistory.to_save_data()) == transfer_history, "real pickup/delivery excluded from history")
	work.input.take(&"logs", 1)
	var blocked: Array[Vector2i] = []
	for storage in ResourceStockpile.get_storages():
		blocked.append_array(storage.get_access_cells())
	world.set_occupied(blocked, true)
	_check(WorkplaceStatus.describe(work).begins_with("No reachable input"), "unreachable input reason")
	work.input.add(&"logs", 1)
	work.output.add(&"firewood", work.output.free_space())
	_check(WorkplaceStatus.describe(work).begins_with("No reachable destination"), "unreachable destination reason")
	world.set_occupied(blocked, false)
	for storage in ResourceStockpile.get_storages():
		storage.storage.add(&"firewood", storage.storage.free_space())
	_check(WorkplaceStatus.describe(work).begins_with("Full storage"), "full-storage reason")
	work.output.take(&"firewood", work.output.total())
	var access := work.get_access_cells()
	world.set_occupied(access, true)
	_check(WorkplaceStatus.describe(work).begins_with("No reachable work"), "unreachable-work reason")
	world.set_occupied(access, false)
	settler.worker.pause()
	_check(WorkplaceStatus.describe(work).begins_with("Paused for personal needs"), "needs pause distinct")
	settler.worker.resume()
	var field := build.add_building(_def(build, &"crop_field_4"), Vector2i(10, 10))
	settler.worker.assign(field)
	TimeManager.month = 9
	_check(WorkplaceStatus.describe(field).begins_with("Off-season"), "off-season reason")
	TimeManager.month = 0
	field.field._states[0] = CropField.CellState.RIPE
	settler.worker._action = Worker.Action.REAP
	settler.worker._field_cell = Vector2i.ZERO
	settler.worker._finish_field_work(field.def.job)
	_check(_amount("produced", "wheat") == int(field.def.job.outputs[0]["amount"]), "real field harvest")
	var home := build.add_building(_def(build, &"house"), Vector2i(18, 18))
	settler.assign_home(home)
	EconomyHistory.shortage_started.connect(func(kind: String) -> void: notices.append(kind))
	EconomyHistory.refresh_shortages(build.get_buildings())
	EconomyHistory.refresh_shortages(build.get_buildings())
	_check(notices == ["food"] and EconomyHistory.shortages["food"].size() == 1, "empty home warned once despite stored food")
	TimeManager.month = 9
	EconomyHistory.refresh_shortages(build.get_buildings())
	_check(notices == ["food", "fuel"], "winter empty fuel warned despite stored fuel")
	home.household.add(&"firewood", 2)
	var fuel_before := _amount("consumed", "firewood")
	people._update_heating(1.0)
	_check(_amount("consumed", "firewood") == fuel_before + SettlerManager.FUEL_PER_HEATING, "real heating consumption")
	home.household.take(&"firewood", home.firewood_stock())
	settler.set_carried(&"tools", 1)
	settler.worker._on_tool_taken(1)
	_check(_amount("consumed", "tools") == 1, "tool equip consumption")
	var site := build.add_construction_site(_def(build, &"house"), Vector2i(22, 22), 0.0)
	for id in site.required:
		site.delivered.add(id, int(site.required[id]))
	var logs_before := _amount("consumed", "logs")
	var logs_cost := int(site.required.get(&"logs", 0))
	site.add_work(site.def.build_time)
	_check(_amount("consumed", "logs") == logs_before + logs_cost, "construction consumed on completion")
	for cell in world.get_cells_in_radius(Vector2(32, 32), 8.0):
		if world.can_place_road(cell, WorldGrid.Road.STONE):
			var stone_before := _amount("consumed", "stone")
			_check(build.place_road_line(cell, cell, WorldGrid.Road.STONE) == 1 and _amount("consumed", "stone") == stone_before + BuildController.STONE_ROAD_COST, "real road consumption")
			break
	var overflow := build.add_construction_site(_def(build, &"house"), Vector2i(26, 26), 0.0)
	overflow.delivered.add(&"firewood", 3)
	for storage in ResourceStockpile.get_storages():
		storage.storage.add(&"firewood", storage.storage.free_space())
	build.cancel_site(overflow)
	_check(_amount("lost", "firewood") == 3, "refund overflow recorded as loss not use")
	EconomyHistory.refresh_shortages(build.get_buildings())
	TimeManager.set_speed(0)
	var ui: Hud = world.get_node("UI")
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	ui._open_shortages()
	_check(ui._inventory_panel.visible and ui._inventory_panel._warning_buttons["food"].disabled == false, "warnings inspectable while paused")
	var paused_history := JSON.stringify(EconomyHistory.to_save_data())
	for index in 5:
		EconomyHistory._process(0.0)
		TimeManager.advance(0.0)
		ui._inventory_panel.refresh()
	_check(JSON.stringify(EconomyHistory.to_save_data()) == paused_history, "paused inspection does not replay flows")
	if OS.get_cmdline_user_args().has("--visual"):
		await _capture("economy-panel-review")
	ui._inventory_panel._focus_next("food")
	_check(world.get_node("Jobs").get_selected_building() == home, "shortage navigation selects home")
	if OS.get_cmdline_user_args().has("--visual"):
		await _capture("economy-home-review")
		settler.worker.assign(work)
		work.output.add(&"firewood", work.output.free_space())
		world.get_node("Jobs").focus_building(work)
		await _capture("economy-workplace-review")
	var old_path := SaveManager.save_path
	SaveManager.save_path = "user://economy_test_save.json"
	_check(SaveManager.save_game(), "integration save")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(EconomyHistory.to_save_data()))
	var count := notices.size()
	_check(SaveManager.load_game(), "integration load")
	_check(JSON.stringify(saved, "", true) == JSON.stringify(EconomyHistory.to_save_data(), "", true), "persistent actual history and warning episodes")
	EconomyHistory.refresh_shortages(build.get_buildings())
	_check(notices.size() == count, "load does not repeat warning toast")
	var restored_home := build.find_building(Vector2i(18, 18))
	restored_home.household.add(&"berries", 2)
	EconomyHistory.refresh_shortages(build.get_buildings())
	_check(EconomyHistory.shortages["food"].is_empty(), "warning clears after delivery")
	restored_home.household.take(&"berries", 2)
	EconomyHistory.refresh_shortages(build.get_buildings())
	_check(notices.size() == count + 1, "new shortage episode warns again")
	var legacy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveManager.save_path))
	legacy.erase("economy")
	var file := FileAccess.open(SaveManager.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	_check(SaveManager.load_game() and EconomyHistory.current()["consumed"].is_empty(), "v10 without history loads without invented past")
	SaveManager.save_path = old_path
	TimeManager.set_speed(1)
	world.queue_free()
	await get_tree().process_frame


func _def(build: BuildController, id: StringName) -> BuildingDef:
	return build.building_defs[build.find_def_index(id)]


func _capture(label: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path := "user://" + label + ".png"
	get_viewport().get_texture().get_image().save_png(path)
	print("VISUAL " + ProjectSettings.globalize_path(path))
