class_name BuildingMenu
extends PanelContainer

const THUMB_DIR := "res://assets/art/ui/thumb_%s.png"
const BUTTON_SIZE := Vector2(88, 66)
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


func setup(build: BuildController) -> void:
	_build = build
	var column := VBoxContainer.new()
	add_child(column)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	column.add_child(row)
	for group in GROUPS:
		if row.get_child_count() > 0:
			var divider := VSeparator.new()
			row.add_child(divider)
		var section := VBoxContainer.new()
		row.add_child(section)
		var header := Label.new()
		header.text = group[0]
		header.theme_type_variation = &"SectionLabel"
		section.add_child(header)
		var grid := GridContainer.new()
		grid.columns = group[2]
		section.add_child(grid)
		_fill_group(grid, group)
	var help := Label.new()
	help.text = "B place, Tab cycle, R resize, X demolish, Esc cancel. Hover for cost."
	help.theme_type_variation = &"HintLabel"
	column.add_child(help)


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


func _fill_group(grid: GridContainer, group: Array) -> void:
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


func _add(grid: GridContainer, title: String, thumb: String, tip: String, entry: Dictionary, action: Callable) -> void:
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
