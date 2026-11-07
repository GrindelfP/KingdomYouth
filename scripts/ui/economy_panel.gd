class_name EconomyPanel
extends PanelContainer

var _build: BuildController
var _settlers: SettlerManager
var _jobs: JobController
var _inventory: Label
var _season: OptionButton
var _progress: Label
var _table: GridContainer
var _warning_labels: Dictionary = {}
var _warning_buttons: Dictionary = {}
var _warning_cursor := {"food": 0, "fuel": 0}
var _last_refresh := 0
var _selected_season := -1


func setup(build: BuildController, settlers: SettlerManager, jobs: JobController) -> void:
	_build = build
	_settlers = settlers
	_jobs = jobs
	position = Vector2(16, 140)
	size = Vector2(920, 480)
	theme_type_variation = &"WoodBar"
	var body := VBoxContainer.new()
	add_child(body)
	var title := HBoxContainer.new()
	body.add_child(title)
	var heading := _label("Town economy — inventory and seasonal flows")
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_child(heading)
	var close := Button.new()
	close.text = "Close"
	close.pressed.connect(hide)
	title.add_child(close)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 18)
	body.add_child(columns)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 360
	columns.add_child(left)
	_inventory = _label("")
	left.add_child(_inventory)
	left.add_child(_label("Household shortages (occupied homes)"))
	for kind in ["food", "fuel"]:
		var text := _label("")
		text.custom_minimum_size.x = 350
		text.autowrap_mode = TextServer.AUTOWRAP_WORD
		left.add_child(text)
		_warning_labels[kind] = text
		var button := Button.new()
		button.text = "Go to next home: " + kind
		button.pressed.connect(_focus_next.bind(kind))
		left.add_child(button)
		_warning_buttons[kind] = button
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 500
	columns.add_child(right)
	_season = OptionButton.new()
	_season.item_selected.connect(func(index: int) -> void:
		_selected_season = _season.get_item_id(index)
		refresh())
	right.add_child(_season)
	_progress = _label("")
	right.add_child(_progress)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(500, 280)
	right.add_child(scroll)
	_table = GridContainer.new()
	_table.columns = 6
	_table.add_theme_constant_override("h_separation", 12)
	scroll.add_child(_table)
	var note := _label("Made / Used / In / Out / Lost, per good.\nTransfers are excluded. In/Out are trade hooks.\nMade includes demolition recovery.\nStanding crops are not yet goods.")
	right.add_child(note)
	visible = false


func _process(_delta: float) -> void:
	if visible and Time.get_ticks_msec() - _last_refresh >= 500:
		refresh()


func refresh() -> void:
	_last_refresh = Time.get_ticks_msec()
	var data := TownInventory.snapshot(_build.get_buildings(), _build.get_sites(), _settlers.living_settlers())
	var food := ResourceCatalog.ids_in_category(ResourceDef.Category.FOOD)
	var fuel: Array[StringName] = [&"firewood"]
	var lines := PackedStringArray(["Inventory now: food / firewood"])
	for entry in [[&"storage", "Stored (available)"], [&"households", "Households"], [&"workplace", "Workplace"], [&"construction", "Construction"], [&"transit", "In transit"], [&"total", "Town total"]]:
		lines.append("%s: %d / %d" % [entry[1], TownInventory.amount(data, entry[0], food), TownInventory.amount(data, entry[0], fuel)])
	lines.append("Only stored goods can be withdrawn.\n")
	_inventory.text = "\n".join(lines)
	for kind in ["food", "fuel"]:
		var homes: Array = EconomyHistory.shortages[kind]
		var locations := PackedStringArray()
		for at in homes.slice(0, 3):
			locations.append("(%d,%d)" % [at[0], at[1]])
		_warning_labels[kind].text = "%s: %d homes%s\n%s" % [kind.capitalize(), homes.size(), " at " + ", ".join(locations) if not locations.is_empty() else "", "Check supply, resident labor and paths." if not homes.is_empty() else ("No winter household fuel shortages." if kind == "fuel" else "No empty household food reserves.")]
		_warning_buttons[kind].disabled = homes.is_empty()
	var current := EconomyHistory.current()
	_season.clear()
	var selected := EconomyHistory.records.size() - 1
	for entry in EconomyHistory.records:
		var index := int(entry["season"])
		_season.add_item("Year %d — %s%s" % [index / 4 + 1, TimeManager.SEASON_NAMES[index % 4], " (current)" if index == int(current["season"]) else ""], index)
		if index == _selected_season:
			selected = _season.item_count - 1
	if _selected_season == -1:
		selected = _season.item_count - 1
	_season.select(selected)
	var record: Dictionary = EconomyHistory.records[selected]
	_progress.text = "Current season: %d%% • Tracking since year %d, month %d" % [int(fmod(TimeManager.get_time_months(), 3.0) / 3.0 * 100.0), int(EconomyHistory.tracking_started) / 12 + 1, int(EconomyHistory.tracking_started) % 12 + 1]
	for child in _table.get_children():
		_table.remove_child(child)
		child.queue_free()
	for title in ["Good", "Made", "Used", "In", "Out", "Lost"]:
		_table.add_child(_label(title))
	for id in ResourceCatalog.all_ids():
		_table.add_child(_label(ResourceCatalog.display_name(id)))
		for flow in EconomyHistory.FLOWS:
			_table.add_child(_label(str(record[flow].get(String(id), 0))))


func _focus_next(kind: String) -> void:
	var homes: Array = EconomyHistory.shortages[kind]
	if homes.is_empty():
		return
	var index: int = int(_warning_cursor[kind]) % homes.size()
	_warning_cursor[kind] = index + 1
	var at: Array = homes[index]
	var building := _build.find_building(Vector2i(int(at[0]), int(at[1])))
	if building != null:
		_jobs.focus_building(building)
		hide()


func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"LightLabel"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
