class_name BuildController
extends Node2D

signal hint_changed(text: String)
signal construction_completed(building: Building)
signal construction_cancelled(def: BuildingDef)

const VALID_COLOR := Color(0.3, 0.9, 0.3, 0.4)
const INVALID_COLOR := Color(0.9, 0.2, 0.2, 0.4)
const RADIUS_FILL := Color(1.0, 1.0, 1.0, 0.08)
const RADIUS_LINE := Color(1.0, 1.0, 1.0, 0.5)
const RADIUS_SEGMENTS := 64
const START_SEARCH_RADIUS := 20
const START_MARGIN := 1

var building_defs: Array[BuildingDef] = [
	load("res://resources/buildings/foresters_lodge.tres"),
	load("res://resources/buildings/gatherers_hut.tres"),
	load("res://resources/buildings/hunting_cabin.tres"),
	load("res://resources/buildings/fishing_dock.tres"),
	load("res://resources/buildings/quarry.tres"),
	load("res://resources/buildings/mine.tres"),
	load("res://resources/buildings/farm.tres"),
	load("res://resources/buildings/stockpile.tres"),
	load("res://resources/buildings/storage_barn.tres"),
	load("res://resources/buildings/house.tres"),
]
var _world: WorldGrid
var _placing := false
var _selected := 0
var _hover := Vector2i.ZERO
var _highlight: Structure


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


func set_highlight(structure: Structure) -> void:
	_highlight = structure


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
	return _get_rule_error(def, origin)


func _get_rule_error(def: BuildingDef, origin: Vector2i) -> String:
	if def.job == null:
		return ""
	var job := def.job
	match job.placement_rule:
		JobDef.PlacementRule.NEAR_WATER:
			if not _touches_terrain(def, origin, "water"):
				return "must be next to water"
		JobDef.PlacementRule.NEAR_ROCK:
			var center := Vector2(origin) + Vector2(def.footprint - Vector2i.ONE) / 2.0
			var found := _world.count_terrain_in_radius("rock", center, job.rule_radius)
			if found < job.rule_min_cells:
				return "needs %d rock tiles within %d tiles (found %d)" % [job.rule_min_cells, job.rule_radius, found]
	return ""


func _touches_terrain(def: BuildingDef, origin: Vector2i, terrain_name: String) -> bool:
	var cells := def.get_cells(origin)
	for cell in cells:
		for offset in Structure.ACCESS_OFFSETS:
			var neighbour: Vector2i = cell + offset
			if not cells.has(neighbour) and _world.get_terrain_name(neighbour) == terrain_name:
				return true
	return false


func try_place(def: BuildingDef, origin: Vector2i) -> bool:
	if get_placement_error(def, origin) != "":
		return false
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


func get_sites() -> Array[ConstructionSite]:
	var sites: Array[ConstructionSite] = []
	for child in get_children():
		if child is ConstructionSite and child.is_alive():
			sites.append(child as ConstructionSite)
	return sites


func get_buildings() -> Array[Building]:
	var result: Array[Building] = []
	for child in get_children():
		if child is Building:
			result.append(child as Building)
	return result


func find_site_at(grid_pos: Vector2i) -> ConstructionSite:
	for site in get_sites():
		if site.occupies(grid_pos):
			return site
	return null


func cancel_site(site: ConstructionSite) -> void:
	if not is_instance_valid(site) or not site.is_alive():
		return
	site.refund()
	_world.set_occupied(site.def.get_cells(site.origin), false)
	site.queue_free()
	construction_cancelled.emit(site.def)


func add_construction_site(def: BuildingDef, origin: Vector2i, progress: float, delivered := {}) -> ConstructionSite:
	_world.set_occupied(def.get_cells(origin), true)
	var site := ConstructionSite.new()
	add_child(site)
	site.setup(_world, def, origin)
	site.progress = progress
	site.delivered.from_save_data(delivered)
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
				"desired_workers": child.desired_workers,
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
				"delivered": child.delivered.to_save_data(),
			})
	return entries


func from_save_data(entries: Array) -> void:
	clear_buildings()
	for entry in entries:
		var def := _def_by_id(entry["id"])
		if def == null:
			continue
		var origin := WorldGrid.cell_from_json(entry["origin"])
		if entry["kind"] == "site":
			add_construction_site(def, origin, float(entry["progress"]), entry["delivered"])
		else:
			var building := add_building(def, origin)
			building.heat_left = float(entry["heat_left"])
			building.desired_workers = int(entry["desired_workers"])
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
		if _highlight != null and is_instance_valid(_highlight) and _highlight.def.job:
			_draw_radius(_highlight.def, _highlight.origin)
		return
	var def := selected_def()
	var color := VALID_COLOR if get_placement_error(def, _hover) == "" else INVALID_COLOR
	var top_left := to_local(_world.get_cell_rect(_hover).position)
	draw_rect(Rect2(top_left, Vector2(def.footprint) * _world.get_tile_size()), color)
	if def.job:
		_draw_radius(def, _hover)


func _draw_radius(def: BuildingDef, origin: Vector2i) -> void:
	if not def.job.has_work_area():
		return
	var tile := _world.get_tile_size()
	var center_cell := Vector2(origin) + Vector2(def.footprint - Vector2i.ONE) / 2.0
	var center := to_local(_world.grid_to_world(Vector2i.ZERO) + center_cell * tile)
	var radius := (def.job.work_radius + 0.5) * tile.x
	draw_circle(center, radius, RADIUS_FILL)
	draw_arc(center, radius, 0.0, TAU, RADIUS_SEGMENTS, RADIUS_LINE, 2.0)
