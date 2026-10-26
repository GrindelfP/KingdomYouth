class_name InfoPanel
extends PanelContainer

const REFRESH_SECONDS := 0.5
const PANEL_WIDTH := 280.0

var _jobs: JobController
var _settlers: SettlerManager
var _build: BuildController
var _content: VBoxContainer
var _refresh_left := 0.0


func setup(jobs: JobController, settlers: SettlerManager, build: BuildController) -> void:
	_jobs = jobs
	_settlers = settlers
	_build = build
	custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	_content = VBoxContainer.new()
	add_child(_content)
	jobs.selection_changed.connect(_rebuild)
	visible = false


func _process(delta: float) -> void:
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH_SECONDS
		_rebuild()


func _rebuild() -> void:
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	var settler := _jobs.get_selected_settler()
	var building := _jobs.get_selected_building()
	visible = settler != null or building != null
	if settler:
		_build_settler_view(settler)
	elif building:
		_build_building_view(building)


func _build_settler_view(settler: Settler) -> void:
	_add_title("Settler %d" % settler.display_id)
	var job := "none"
	if settler.worker.building:
		job = "%s, %s" % [settler.worker.building.def.display_name, settler.worker.get_state_name()]
		if settler.worker.is_paused():
			job += " (paused)"
	_add_line("Job: " + job)
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
	if settler.worker.building:
		_add_button("Unassign job", func() -> void: settler.worker.unassign())
	_add_button("Close", _jobs.clear_selection)


func _build_building_view(building: Building) -> void:
	_add_title(building.def.display_name)
	var job := building.def.job
	if job:
		_add_line("Workers %d / %d" % [building.workers.size(), job.slots])
		for worker_settler in building.workers:
			_add_row("Settler %d" % worker_settler.display_id, "Remove", func() -> void: worker_settler.worker.unassign())
		if building.has_free_job_slot():
			var idle := 0
			for settler in _settlers.living_settlers():
				if settler.worker.building == null:
					idle += 1
					_add_row("Settler %d (idle)" % settler.display_id, "Assign", func() -> void: settler.worker.assign(building))
			if idle == 0:
				_add_line("No idle settlers.")
		_add_inventory("Output", building.output)
		if building.is_output_blocked():
			_add_line("Storage full: output cannot be hauled, work is stalled.")
	if building.storage:
		_add_inventory("Stored", building.storage)
	if building.def.housing_capacity > 0:
		_add_line("Residents %d / %d" % [building.residents.size(), building.def.housing_capacity])
		_add_line("Heating: " + ("on" if building.is_heated() else "off"))
	_add_button("Close", _jobs.clear_selection)


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


func _add_row(text: String, button_text: String, action: Callable) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var button := Button.new()
	button.text = button_text
	button.pressed.connect(action)
	row.add_child(button)
	_content.add_child(row)
