class_name BuildingDef
extends Resource

@export var id: StringName
@export var display_name: String
@export var footprint := Vector2i.ONE
@export var cost: Dictionary = {}
@export var build_time := 5.0
@export var job: JobDef
@export var housing_capacity := 0
@export var storage_capacity := 0
@export var storage_categories: Array[int] = []


func get_cells(origin: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in footprint.x:
		for y in footprint.y:
			cells.append(origin + Vector2i(x, y))
	return cells


func is_storage() -> bool:
	return storage_capacity > 0


func accepts(good_id: StringName) -> bool:
	if storage_categories.is_empty():
		return true
	var def := ResourceCatalog.get_def(good_id)
	return def != null and storage_categories.has(int(def.category))
