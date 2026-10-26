class_name BuildingMenu
extends Control

const THUMB_DIR := "res://assets/art/ui/thumb_%s.png"
const BUTTON_SIZE := Vector2(88, 66)
const TAB_WIDTH := 84.0
const TAB_HEIGHT := 26.0
const BAR_MARGIN := 8.0
const POPUP_LIFT := 52.0
const GROUPS := [
	["Roads", [], 1],
	["Storage", [&"stockpile", &"storage_barn"], 1],
	["Housing", [&"house"], 1],
	["Food", [&"crop_field_4", &"crop_field_6", &"crop_field_8", &"gatherers_hut", &"hunting_cabin", &"fishing_dock"], 3],
	["Resources", [&"foresters_lodge", &"quarry", &"mine"], 2],
	["Industry", [&"woodcutter", &"blacksmith"], 1],
	["Tools", [], 1],
]

var _build: BuildController
var _entries: Array[Dictionary] = []
var _tabs: Array[Button] = []
var _pages: Array[HBoxContainer] = []
var _bar: PanelContainer
var _popup: PanelContainer
var _open_index := -1
var _last_index := 2


func setup(build: BuildController) -> void:
	_build = build
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar = PanelContainer.new()
	_bar.theme_type_variation = &"WoodBar"
	_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_bar.offset_bottom = -BAR_MARGIN
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	_bar.add_child(tabs)
	add_child(_bar)
	_popup = PanelContainer.new()
	_popup.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_popup.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_popup.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_popup.offset_bottom = -POPUP_LIFT
	_popup.visible = false
	var holder := VBoxContainer.new()
	_popup.add_child(holder)
	add_child(_popup)
	for index in GROUPS.size():
		var group: Array = GROUPS[index]
		var tab := Button.new()
		tab.text = group[0]
		tab.toggle_mode = true
		tab.focus_mode = Control.FOCUS_NONE
		tab.theme_type_variation = &"SmallButton"
		tab.custom_minimum_size = Vector2(TAB_WIDTH, TAB_HEIGHT)
		tab.pressed.connect(_on_tab_pressed.bind(index))
		tabs.add_child(tab)
		_tabs.append(tab)
		var page := HBoxContainer.new()
		page.add_theme_constant_override("separation", 4)
		page.visible = false
		holder.add_child(page)
		_pages.append(page)
		_fill_group(page, group)
	var help := Label.new()
	help.text = "Tab cycle, R resize, X demolish, Esc cancel. Hover for cost."
	help.theme_type_variation = &"HintLabel"
	help.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(help)


func is_open() -> bool:
	return _open_index >= 0


func open_page(index: int) -> void:
	_open_index = index
	_last_index = index
	for page_index in _pages.size():
		_pages[page_index].visible = page_index == index
	_popup.visible = true
	_popup.reset_size()
	_sync_tabs()


func close_popup() -> void:
	_open_index = -1
	_popup.visible = false
	_sync_tabs()


func _on_tab_pressed(index: int) -> void:
	if _open_index == index:
		close_popup()
	else:
		open_page(index)


func _sync_tabs() -> void:
	for index in _tabs.size():
		_tabs[index].set_pressed_no_signal(index == _open_index)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("build_toggle"):
		if _build.is_placing():
			_build.stop_modes()
			close_popup()
		elif is_open():
			close_popup()
		else:
			open_page(_last_index)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cancel_build") and is_open():
		close_popup()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	for entry in _entries:
		var active := false
		match entry["kind"]:
			"building":
				active = _build.active_index() == entry["index"]
			"road":
				active = _build.active_road() == entry["road"]
			"demolish":
				active = _build.is_demolishing()
		entry["button"].set_pressed_no_signal(active)


func _fill_group(grid: Container, group: Array) -> void:
	match group[0]:
		"Roads":
			_add(grid, "Dirt road", "thumb_road_dirt", "Dirt road\nFree\nDrag to lay a line.", {"kind": "road", "road": WorldGrid.Road.DIRT}, _build.select_road.bind(WorldGrid.Road.DIRT))
			_add(grid, "Stone road", "thumb_road_stone", "Stone road\n1 stone per tile\nFaster travel. Drag to lay a line.", {"kind": "road", "road": WorldGrid.Road.STONE}, _build.select_road.bind(WorldGrid.Road.STONE))
		"Tools":
			_add(grid, "Demolish", "thumb_demolish", "Demolish (X)\nReturns half of the cost.", {"kind": "demolish"}, _build.toggle_demolish)
	for id: StringName in group[1]:
		var index := _build.find_def_index(id)
		if index >= 0:
			var def := _build.building_defs[index]
			_add(grid, def.display_name, "thumb_%s" % id, "%s\n%s" % [def.display_name, _cost_text(def.cost)], {"kind": "building", "index": index}, _build.select_building.bind(index))


func _add(grid: Container, title: String, thumb: String, tip: String, entry: Dictionary, action: Callable) -> void:
	var button := Button.new()
	button.text = title
	button.icon = load(THUMB_DIR % thumb.trim_prefix("thumb_")) as Texture2D
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.theme_type_variation = &"SmallButton"
	button.custom_minimum_size = BUTTON_SIZE
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = tip
	button.pressed.connect(action)
	button.pressed.connect(close_popup)
	grid.add_child(button)
	entry["button"] = button
	_entries.append(entry)


static func _cost_text(cost: Dictionary) -> String:
	if cost.is_empty():
		return "Free"
	var parts := PackedStringArray()
	for type: StringName in cost:
		parts.append("%d %s" % [cost[type], ResourceCatalog.display_name(type)])
	return ", ".join(parts)
