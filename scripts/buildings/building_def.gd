class_name BuildingDef
extends Resource

@export var id: StringName
@export var display_name: String
@export var footprint := Vector2i.ONE
@export var cost: Dictionary = {}
@export var build_time := 5.0


func get_cells(origin: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in footprint.x:
		for y in footprint.y:
			cells.append(origin + Vector2i(x, y))
	return cells
