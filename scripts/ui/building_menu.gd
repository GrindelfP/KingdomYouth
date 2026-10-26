class_name BuildingMenu
extends PanelContainer

const GROUP_COLUMNS := 3
const GROUPS := [
	["Roads", []],
	["Storage", [&"stockpile", &"storage_barn"]],
	["Housing", [&"house"]],
	["Food", [&"crop_field_4", &"crop_field_6", &"crop_field_8", &"gatherers_hut", &"hunting_cabin", &"fishing_dock"]],
	["Resources", [&"foresters_lodge", &"quarry", &"mine"]],
	["Industry", [&"woodcutter", &"blacksmith"]],
]


func setup(build: BuildController) -> void:
	var column := VBoxContainer.new()
	add_child(column)
	var title := Label.new()
	title.text = "Build"
	column.add_child(title)
	var grid := GridContainer.new()
	grid.columns = GROUP_COLUMNS
	column.add_child(grid)
	for group in GROUPS:
		var section := VBoxContainer.new()
		grid.add_child(section)
		var header := Label.new()
		header.text = group[0]
		section.add_child(header)
		if group[0] == "Roads":
			section.add_child(_make_button("Dirt road (free)", build.select_road.bind(WorldGrid.Road.DIRT)))
			section.add_child(_make_button("Stone road (1 stone/tile)", build.select_road.bind(WorldGrid.Road.STONE)))
		for id: StringName in group[1]:
			var index := build.find_def_index(id)
			if index >= 0:
				var def := build.building_defs[index]
				section.add_child(_make_button("%s (%s)" % [def.display_name, _cost_text(def.cost)], build.select_building.bind(index)))
	column.add_child(_make_button("Demolish (X)", build.toggle_demolish))
	var help := Label.new()
	help.text = "B toggles placing, Tab cycles, R resizes fields, X demolishes, Esc cancels"
	column.add_child(help)


func _make_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	return button


static func _cost_text(cost: Dictionary) -> String:
	if cost.is_empty():
		return "free"
	var parts := PackedStringArray()
	for type: StringName in cost:
		parts.append("%d %s" % [cost[type], ResourceCatalog.display_name(type)])
	return ", ".join(parts)
