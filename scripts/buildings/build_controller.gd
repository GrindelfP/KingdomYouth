class_name BuildController
extends Node2D

signal hint_changed(text: String)
signal construction_completed(building: Building)

const VALID_COLOR := Color(0.3, 0.9, 0.3, 0.4)
const INVALID_COLOR := Color(0.9, 0.2, 0.2, 0.4)
const START_SEARCH_RADIUS := 20
const START_MARGIN := 1

var building_defs: Array[BuildingDef] = [
	load("res://resources/buildings/woodcutters_lodge.tres"),
	load("res://resources/buildings/farm.tres"),
	load("res://resources/buildings/stockpile.tres"),
	load("res://resources/buildings/storage_barn.tres"),
	load("res://resources/buildings/house.tres"),
]
var _world: WorldGrid
var _placing := false
var _selected := 0
var _hover := Vector2i.ZERO


func _ready() -> void:
	_world = get_parent()


func _process(_delta: float) -> void:
	if _placing:
		_hover = _world.world_to_grid(get_global_mouse_position())
	queue_redraw()
	_update_hint()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("build_toggle"):
		_placing = not _placing
	elif event.is_action_pressed("build_cycle"):
		_selected = (_selected + 1) % building_defs.size()
	elif event.is_action_pressed("cancel_build") and _placing:
		_placing = false
	elif event.is_action_pressed("place_building") and _placing:
		_hover = _world.world_to_grid(get_global_mouse_position())
		try_place(selected_def(), _hover)
		get_viewport().set_input_as_handled()


func is_placing() -> bool:
	return _placing


func select_building(index: int) -> void:
	_selected = index
	_placing = true


func cancel_placement() -> void:
	_placing = false


func selected_def() -> BuildingDef:
	return building_defs[_selected]


func get_placement_error(def: BuildingDef, origin: Vector2i) -> String:
	var cells := def.get_cells(origin)
	for cell in cells:
		if not _world.is_in_bounds(cell):
			return "outside the map"
	for cell in cells:
		if _world.is_occupied(cell):
			return "tile is occupied"
		if not _world.is_buildable(cell):
			return "terrain is not buildable"
	if not ResourceStockpile.can_afford(def.cost):
		return "not enough resources"
	return ""


func try_place(def: BuildingDef, origin: Vector2i) -> bool:
	if get_placement_error(def, origin) != "":
		return false
	ResourceStockpile.spend(def.cost)
	_world.set_occupied(def.get_cells(origin), true)
	var site := ConstructionSite.new()
	add_child(site)
	site.setup(_world, def, origin)
	site.completed.connect(_on_site_completed)
	return true


func place_starting_storage(avoid: Array[Vector2i]) -> void:
	for def_id in [&"stockpile", &"storage_barn"]:
		var def := _def_by_id(String(def_id))
		var origin := _find_free_origin(def, WorldGrid.MAP_RECT.get_center(), avoid)
		if origin != Vector2i(-1, -1):
			add_building(def, origin)


func add_building(def: BuildingDef, origin: Vector2i) -> Building:
	_world.set_occupied(def.get_cells(origin), true)
	var building := Building.new()
	add_child(building)
	building.setup(_world, def, origin)
	return building


func add_construction_site(def: BuildingDef, origin: Vector2i, progress: float) -> ConstructionSite:
	_world.set_occupied(def.get_cells(origin), true)
	var site := ConstructionSite.new()
	add_child(site)
	site.setup(_world, def, origin)
	site.progress = progress
	site.completed.connect(_on_site_completed)
	return site


func clear_buildings() -> void:
	for child in get_children():
		remove_child(child)
		child.free()
	_world.clear_occupancy()


func find_building(origin: Vector2i) -> Building:
	for child in get_children():
		if child is Building and child.origin == origin:
			return child
	return null


func to_save_data() -> Array:
	var entries := []
	for child in get_children():
		if child is Building:
			entries.append({
				"kind": "building",
				"id": String(child.def.id),
				"origin": WorldGrid.cell_to_json(child.origin),
				"heat_left": child.heat_left,
				"birth_cooldown": child.birth_cooldown,
				"storage": child.storage.to_save_data() if child.storage else {},
				"output": child.output.to_save_data() if child.output else {},
			})
		elif child is ConstructionSite:
			entries.append({
				"kind": "site",
				"id": String(child.def.id),
				"origin": WorldGrid.cell_to_json(child.origin),
				"progress": child.progress,
			})
	return entries


func from_save_data(entries: Array) -> void:
	clear_buildings()
	for entry in entries:
		var def := _def_by_id(entry["id"])
		var origin := WorldGrid.cell_from_json(entry["origin"])
		if entry["kind"] == "site":
			add_construction_site(def, origin, float(entry["progress"]))
		else:
			var building := add_building(def, origin)
			building.heat_left = float(entry["heat_left"])
			building.birth_cooldown = float(entry["birth_cooldown"])
			if building.storage:
				building.storage.from_save_data(entry["storage"])
			if building.output:
				building.output.from_save_data(entry["output"])


func _find_free_origin(def: BuildingDef, near: Vector2i, avoid: Array[Vector2i]) -> Vector2i:
	var candidates: Array[Vector2i] = []
	for x in range(-START_SEARCH_RADIUS, START_SEARCH_RADIUS + 1):
		for y in range(-START_SEARCH_RADIUS, START_SEARCH_RADIUS + 1):
			candidates.append(near + Vector2i(x, y) - (def.footprint - Vector2i.ONE) / 2)
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.distance_squared_to(near) < b.distance_squared_to(near))
	for origin in candidates:
		if _is_free_with_margin(def, origin, avoid):
			return origin
	return Vector2i(-1, -1)


func _is_free_with_margin(def: BuildingDef, origin: Vector2i, avoid: Array[Vector2i]) -> bool:
	for x in range(-START_MARGIN, def.footprint.x + START_MARGIN):
		for y in range(-START_MARGIN, def.footprint.y + START_MARGIN):
			var cell := origin + Vector2i(x, y)
			var inside := x >= 0 and y >= 0 and x < def.footprint.x and y < def.footprint.y
			if not _world.is_in_bounds(cell) or _world.is_occupied(cell) or avoid.has(cell):
				return false
			if inside and not _world.is_buildable(cell):
				return false
			if not inside and not _world.is_walkable(cell):
				return false
	return true


func _def_by_id(id: String) -> BuildingDef:
	for def in building_defs:
		if String(def.id) == id:
			return def
	return null


func _on_site_completed(site: ConstructionSite) -> void:
	var building := Building.new()
	add_child(building)
	building.setup(_world, site.def, site.origin)
	site.queue_free()
	construction_completed.emit(building)


func _update_hint() -> void:
	var def := selected_def()
	if not _placing:
		hint_changed.emit("")
		return
	var reason := get_placement_error(def, _hover)
	hint_changed.emit("Build %s: %s" % [def.display_name, reason if reason != "" else "click to place, Esc to cancel"])


func _draw() -> void:
	if not _placing:
		return
	var def := selected_def()
	var color := VALID_COLOR if get_placement_error(def, _hover) == "" else INVALID_COLOR
	var top_left := to_local(_world.get_cell_rect(_hover).position)
	draw_rect(Rect2(top_left, Vector2(def.footprint) * _world.get_tile_size()), color)
