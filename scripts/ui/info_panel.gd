class_name InfoPanel
extends PanelContainer

const REFRESH_SECONDS := 0.5
const PANEL_WIDTH := 280.0

var _jobs: JobController
var _settlers: SettlerManager
var _build: BuildController
var _labor: LaborManager
var _content: VBoxContainer
var _refresh_left := 0.0


func setup(jobs: JobController, settlers: SettlerManager, build: BuildController, labor: LaborManager) -> void:
	_jobs = jobs
	_settlers = settlers
	_build = build
	_labor = labor
	custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	_content = VBoxContainer.new()
	add_child(_content)
	jobs.selection_changed.connect(_rebuild)
	visible = false


func _process(delta: float) -> void:
	_refresh_left -= delta
	if _refresh_left <= 0.0 and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_refresh_left = REFRESH_SECONDS
		_rebuild()


func _rebuild() -> void:
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	var settler := _jobs.get_selected_settler()
	var building := _jobs.get_selected_building()
	var site := _jobs.get_selected_site()
	visible = settler != null or building != null or site != null
	if settler:
		_build_settler_view(settler)
	elif site:
		_build_site_view(site)
	elif building:
		_build_building_view(building)


func _build_settler_view(settler: Settler) -> void:
	_add_title("Settler %d" % settler.display_id)
	_add_line("Profession: " + Professions.display_name(settler.profession))
	var task := settler.worker.get_state_name()
	if settler.worker.building:
		task = "%s, %s" % [settler.worker.building.def.display_name, task]
	if settler.worker.is_paused():
		task += " (paused)"
	_add_line("Task: " + task)
	var home := "none (exposed)"
	if settler.home:
		home = "%s at %s" % [settler.home.def.display_name, settler.home.origin]
	_add_line("Home: " + home)
	if settler.is_carrying():
		_add_line("Carrying: %d %s" % [settler.carried_amount, ResourceCatalog.display_name(settler.carried_id)])
	_add_bar("Hunger", settler.needs.hunger)
	_add_bar("Rest", settler.needs.rest)
	_add_bar("Warmth", settler.needs.warmth)
	_add_bar("Health", settler.needs.health)
	_add_button("Close", _jobs.clear_selection)


func _build_site_view(site: ConstructionSite) -> void:
	_add_title("%s (under construction)" % site.def.display_name)
	_add_line(site.status_text())
	_add_line("Progress %d%%" % roundi(site.progress_ratio() * 100.0))
	for id in site.required:
		_add_line("  %s: %d / %d" % [ResourceCatalog.display_name(id), site.delivered.get_amount(id), site.required[id]])
	_add_button("Cancel construction", _jobs.cancel_selected_site)
	_add_button("Close", _jobs.clear_selection)


func _build_building_view(building: Building) -> void:
	_add_title(building.def.display_name)
	var job := building.def.job
	if job:
		_add_line("Workers %d / %d" % [building.workers.size(), building.desired_workers])
		_add_stepper("Desired workers: %d" % building.desired_workers,
			func() -> void: _labor.set_desired_workers(building, building.desired_workers - 1),
			func() -> void: _labor.set_desired_workers(building, building.desired_workers + 1))
		for worker_settler in building.workers:
			_add_line("  Settler %d" % worker_settler.display_id)
		_add_work_area_lines(building)
		_add_inventory("Output", building.output)
		if building.is_output_blocked():
			_add_line("Storage full: output cannot be hauled, work is stalled.")
	if building.storage:
		_add_inventory("Stored", building.storage)
	if building.def.housing_capacity > 0:
		_add_line("Residents %d / %d" % [building.residents.size(), building.def.housing_capacity])
		_add_line("Heating: " + ("on" if building.is_heated() else "off"))
	_add_button("Close", _jobs.clear_selection)


func _add_work_area_lines(building: Building) -> void:
	var job := building.def.job
	var world := building.world()
	var center := building.get_work_center()
	match job.target_mode:
		JobDef.TargetMode.FOREST_CELL:
			_add_line("Forest tiles in radius: %d" % building.forest_cell_count())
		JobDef.TargetMode.FORESTER:
			_add_line("Trees in radius: %d (mature %d)" % [
				world.count_trees_in_radius(center, job.work_radius),
				world.count_trees_in_radius(center, job.work_radius, WorldGrid.STAGE_MATURE)])
	if job.placement_rule == JobDef.PlacementRule.NEAR_ROCK:
		_add_line("Rock tiles nearby: %d" % world.count_terrain_in_radius("rock", center, job.rule_radius))
	if job.density_cells > 0 or (TimeManager.is_cold() and job.winter_factor < 1.0):
		_add_line("Work rate: %d%%" % roundi(building.work_efficiency() * 100.0))


func _add_inventory(title: String, inventory: Inventory) -> void:
	_add_line("%s %d / %d" % [title, inventory.total(), inventory.capacity])
	for id in inventory.ids():
		_add_line("  %s: %d" % [ResourceCatalog.display_name(id), inventory.get_amount(id)])


func _add_title(text: String) -> void:
	var label := Label.new()
	label.text = text
	_content.add_child(label)


func _add_line(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_content.add_child(label)


func _add_bar(text: String, value: float) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = "%s %d" % [text, roundi(value)]
	label.custom_minimum_size = Vector2(110, 0)
	row.add_child(label)
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = value
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(bar)
	_content.add_child(row)


func _add_button(text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	_content.add_child(button)


func _add_stepper(text: String, on_minus: Callable, on_plus: Callable) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	for entry in [["-", on_minus], ["+", on_plus]]:
		var button := Button.new()
		button.text = entry[0]
		button.pressed.connect(entry[1])
		row.add_child(button)
	_content.add_child(row)
