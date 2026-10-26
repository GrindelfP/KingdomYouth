class_name BuildingMenu
extends PanelContainer


func setup(build: BuildController) -> void:
	var column := VBoxContainer.new()
	add_child(column)
	var title := Label.new()
	title.text = "Build"
	column.add_child(title)
	for index in build.building_defs.size():
		var def := build.building_defs[index]
		var button := Button.new()
		button.text = "%s (%s)" % [def.display_name, _cost_text(def.cost)]
		button.pressed.connect(build.select_building.bind(index))
		column.add_child(button)
	var help := Label.new()
	help.text = "B toggles placing, Tab cycles, Esc cancels"
	column.add_child(help)


static func _cost_text(cost: Dictionary) -> String:
	if cost.is_empty():
		return "free"
	var parts := PackedStringArray()
	for type: StringName in cost:
		parts.append("%d %s" % [cost[type], ResourceCatalog.display_name(type)])
	return ", ".join(parts)
