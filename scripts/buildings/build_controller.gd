class_name BuildController
extends Node2D

signal hint_changed(text: String)
signal construction_completed(building: Building)
signal construction_cancelled(def: BuildingDef)
signal crops_lost(building: Building, count: int)
signal notice(text: String)

const VALID_COLOR := Color(0.3, 0.9, 0.3, 0.4)
const INVALID_COLOR := Color(0.9, 0.2, 0.2, 0.4)
const RADIUS_FILL := Color(1.0, 1.0, 1.0, 0.08)
const RADIUS_LINE := Color(1.0, 1.0, 1.0, 0.5)
const RADIUS_SEGMENTS := 64
const START_SEARCH_RADIUS := 20
const START_MARGIN := 1
const STONE_ROAD_COST := 1
const PREVIEW_VALID := Color(0.55, 1.0, 0.55, 0.8)
const PREVIEW_INVALID := Color(1.0, 0.45, 0.45, 0.8)
const TIP_OFFSET := Vector2(16.0, 18.0)
const TIP_LAYER := 4

var building_defs: Array[BuildingDef] = [
	load("res://resources/buildings/foresters_lodge.tres"),
	load("res://resources/buildings/gatherers_hut.tres"),
	load("res://resources/buildings/hunting_cabin.tres"),
	load("res://resources/buildings/fishing_dock.tres"),
	load("res://resources/buildings/quarry.tres"),
	load("res://resources/buildings/mine.tres"),
	load("res://resources/buildings/crop_field_4.tres"),
	load("res://resources/buildings/crop_field_6.tres"),
	load("res://resources/buildings/crop_field_8.tres"),
	load("res://resources/buildings/woodcutter.tres"),
	load("res://resources/buildings/blacksmith.tres"),
	load("res://resources/buildings/stockpile.tres"),
	load("res://resources/buildings/storage_barn.tres"),
	load("res://resources/buildings/house.tres"),
]
var _world: WorldGrid
var _placing := false
var _selected := 0
var _hover := Vector2i.ZERO
var _highlight: Structure
var _road := WorldGrid.Road.NONE
var _demolishing := false
var _dragging := false
var _drag_from := Vector2i.ZERO
var _overlay: Node2D
var _hovered: Structure
var _tip_layer: CanvasLayer
var _tip_panel: PanelContainer
var _tip_label: Label


func _ready() -> void:
	_world = get_parent()
	_overlay = Node2D.new()
	_overlay.z_index = 100
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	_tip_layer = CanvasLayer.new()
	_tip_layer.layer = TIP_LAYER
	add_child(_tip_layer)
	_tip_panel = PanelContainer.new()
	_tip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip_panel.visible = false
	_tip_label = Label.new()
	_tip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip_panel.add_child(_tip_label)
	_tip_layer.add_child(_tip_panel)


func _process(_delta: float) -> void:
	if _placing:
		_hover = _world.world_to_grid(get_global_mouse_position())
	_update_hover()
	_overlay.queue_redraw()
	_update_hint()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("build_toggle"):
		if _placing:
			stop_modes()
		else:
			start_placing()
	elif event.is_action_pressed("build_cycle"):
		_selected = (_selected + 1) % building_defs.size()
		_road = WorldGrid.Road.NONE
	elif event.is_action_pressed("build_size") and _placing:
		cycle_size()
	elif event.is_action_pressed("demolish_toggle"):
		toggle_demolish()
	elif event.is_action_pressed("cancel_build") and (_placing or _demolishing):
		stop_modes()
	elif event.is_action_pressed("place_building") and _placing:
		_hover = _world.world_to_grid(get_global_mouse_position())
		if _road == WorldGrid.Road.NONE:
			try_place(selected_def(), _hover)
		else:
			_dragging = true
			_drag_from = _hover
		get_viewport().set_input_as_handled()
	elif event.is_action_released("place_building") and _dragging:
		_dragging = false
		place_road_line(_drag_from, _world.world_to_grid(get_global_mouse_position()), _road)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("place_building") and _demolishing:
		demolish_at(_world.world_to_grid(get_global_mouse_position()))
		get_viewport().set_input_as_handled()


func set_highlight(structure: Structure) -> void:
	var previous := _highlight
	_highlight = structure
	if is_instance_valid(previous):
		previous.set_outline(1 if previous == _hovered else 0)
	if is_instance_valid(structure):
		structure.set_outline(2)


func _update_hover() -> void:
	var target: Structure = null
	if not _placing and get_viewport().gui_get_hovered_control() == null:
		var cell := _world.world_to_grid(get_global_mouse_position())
		target = find_site_at(cell)
		if target == null:
			target = find_building_at(cell)
	if target != _hovered:
		if is_instance_valid(_hovered):
			_hovered.set_outline(2 if _hovered == _highlight else 0)
		_hovered = target
		if target != null and target != _highlight:
			target.set_outline(1)
	_tip_panel.visible = _hovered != null and is_instance_valid(_hovered)
	if _tip_panel.visible:
		_tip_label.text = _hovered.display_name()
		_tip_panel.position = get_viewport().get_mouse_position() + TIP_OFFSET


func is_placing() -> bool:
	return _placing or _demolishing


func start_placing() -> void:
	_placing = true
	_demolishing = false
	_dragging = false


func select_building(index: int) -> void:
	_selected = index
	_road = WorldGrid.Road.NONE
	start_placing()


func select_road(type: WorldGrid.Road) -> void:
	_road = type
	start_placing()


func toggle_demolish() -> void:
	var was_on := _demolishing
	stop_modes()
	_demolishing = not was_on


func stop_modes() -> void:
	_placing = false
	_demolishing = false
	_dragging = false


func find_def_index(id: StringName) -> int:
	for index in building_defs.size():
		if building_defs[index].id == id:
			return index
	return -1


func cycle_size() -> void:
	if _road != WorldGrid.Road.NONE:
		return
	var family := selected_def().family
	if family == &"":
		return
	for step in range(1, building_defs.size()):
		var index := (_selected + step) % building_defs.size()
		if building_defs[index].family == family:
			_selected = index
			return


func cancel_placement() -> void:
	stop_modes()


func selected_def() -> BuildingDef:
	return building_defs[_selected]


func find_building_at(grid_pos: Vector2i) -> Building:
	for building in get_buildings():
		if building.occupies(grid_pos):
			return building
	return null


static func road_line_cells(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var cell := from
	cells.append(cell)
	while cell.x != to.x:
		cell.x += signi(to.x - cell.x)
		cells.append(cell)
	while cell.y != to.y:
		cell.y += signi(to.y - cell.y)
		cells.append(cell)
	return cells


func place_road_line(from: Vector2i, to: Vector2i, type: WorldGrid.Road) -> int:
	var candidates: Array[Vector2i] = []
	for cell in road_line_cells(from, to):
		if _world.can_place_road(cell, type):
			candidates.append(cell)
	var count := candidates.size()
	if type == WorldGrid.Road.STONE:
		count = mini(count, ResourceStockpile.get_amount(&"stone") / STONE_ROAD_COST)
		if count < candidates.size():
			notice.emit("Not enough stone: built %d of %d stone road tiles." % [count, candidates.size()])
		if count == 0:
			return 0
		ResourceStockpile.spend({&"stone": count * STONE_ROAD_COST})
	for index in count:
		_world.set_road(candidates[index], type)
	return count


func road_error(grid_pos: Vector2i, type: WorldGrid.Road) -> String:
	if _world.can_place_road(grid_pos, type):
		return ""
	if not _world.is_in_bounds(grid_pos) or _world.get_terrain_name(grid_pos) != "grass":
		return "roads need open grass"
	if _world.get_road(grid_pos) >= type:
		return "already a road"
	return "tile is occupied or has trees"


func demolish_at(grid_pos: Vector2i) -> bool:
	var site := find_site_at(grid_pos)
	if site:
		cancel_site(site)
		return true
	var building := find_building_at(grid_pos)
	if building:
		demolish_building(building)
		return true
	if _world.get_road(grid_pos) != WorldGrid.Road.NONE:
		_world.set_road(grid_pos, WorldGrid.Road.NONE)
		return true
	return false


func demolish_building(building: Building) -> void:
	if not building.is_alive():
		return
	for worker in building.workers.duplicate():
		worker.worker.unassign()
	for resident in building.residents.duplicate():
		resident.unassign_home()
	remove_child(building)
	if _hovered == building:
		_hovered = null
	if _highlight == building:
		_highlight = null
	_world.set_occupied(building.def.get_cells(building.origin), false)
	for inventory in [building.storage, building.output, building.input, building.household]:
		if inventory == null:
			continue
		for id in inventory.ids():
			ResourceStockpile.add(id, inventory.take(id, inventory.get_amount(id)))
	for id in building.def.cost:
		ResourceStockpile.add(id, int(building.def.cost[id]) / 2)
	building.queue_free()
	notice.emit("Demolished %s. Half of its cost was returned to storage." % building.def.display_name)


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
	_watch(building)
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
		if child is Structure:
			remove_child(child)
			child.free()
	_hovered = null
	_highlight = null
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
				"storage": child.storage.to_save_data() if child.storage else {},
				"output": child.output.to_save_data() if child.output else {},
				"input": child.input.to_save_data() if child.input else {},
				"household": child.household.to_save_data() if child.household else {},
				"field": child.field.to_save_data() if child.field else {},
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
			if building.storage:
				building.storage.from_save_data(entry["storage"])
			if building.output:
				building.output.from_save_data(entry["output"])
			if building.input:
				building.input.from_save_data(entry["input"])
			if building.household:
				building.household.from_save_data(entry["household"])
			if building.field:
				building.field.from_save_data(entry["field"])


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


func _watch(building: Building) -> void:
	building.crops_lost.connect(func(count: int) -> void: crops_lost.emit(building, count))


func _on_site_completed(site: ConstructionSite) -> void:
	var building := Building.new()
	add_child(building)
	building.setup(_world, site.def, site.origin)
	_watch(building)
	site.queue_free()
	construction_completed.emit(building)


func _update_hint() -> void:
	if _demolishing:
		hint_changed.emit("Demolish: click a building, construction site or road. Esc to stop.")
		return
	if not _placing:
		hint_changed.emit("")
		return
	if _road != WorldGrid.Road.NONE:
		var road_name := "Dirt road" if _road == WorldGrid.Road.DIRT else "Stone road"
		var reason := road_error(_hover, _road)
		var cost := "free" if _road == WorldGrid.Road.DIRT else "1 stone per tile"
		hint_changed.emit("Build %s (%s): %s" % [road_name, cost, reason if reason != "" else "drag a straight or L-shaped line, release to place"])
		return
	var def := selected_def()
	var error := get_placement_error(def, _hover)
	hint_changed.emit("Build %s: %s" % [def.display_name, error if error != "" else "click to place, Esc to cancel"])


func _draw_overlay() -> void:
	if not _placing:
		if _highlight != null and is_instance_valid(_highlight) and _highlight.def.job:
			_draw_radius(_highlight.def, _highlight.origin)
		return
	if _road != WorldGrid.Road.NONE:
		_draw_road_preview()
		return
	var def := selected_def()
	var color := VALID_COLOR if get_placement_error(def, _hover) == "" else INVALID_COLOR
	var top_left := to_local(_world.get_cell_rect(_hover).position)
	var footprint_size := Vector2(def.footprint) * _world.get_tile_size()
	_overlay.draw_rect(Rect2(top_left, footprint_size), color)
	_draw_preview_sprite(def, top_left + Vector2(footprint_size.x * 0.5, footprint_size.y), get_placement_error(def, _hover) == "")
	if def.job:
		_draw_radius(def, _hover)


func _draw_preview_sprite(def: BuildingDef, bottom_centre: Vector2, valid: bool) -> void:
	var tint := PREVIEW_VALID if valid else PREVIEW_INVALID
	if def.is_field():
		_overlay.draw_texture(BuildingArt.fence_texture(def.footprint.x), bottom_centre + BuildingArt.fence_offset(def.footprint.x), tint)
		return
	var view := _world.get_node_or_null("TerrainView") as TerrainView
	var winter := view != null and view.get_season() == Structure.WINTER
	var tex := BuildingArt.texture(def, winter)
	_overlay.draw_texture(tex, bottom_centre + BuildingArt.sprite_offset(tex), tint)


func _draw_road_preview() -> void:
	var cells := road_line_cells(_drag_from, _hover) if _dragging else [_hover]
	for cell in cells:
		var color := VALID_COLOR if _world.can_place_road(cell, _road) else INVALID_COLOR
		_overlay.draw_rect(Rect2(to_local(_world.get_cell_rect(cell).position), _world.get_tile_size()), color)


func _draw_radius(def: BuildingDef, origin: Vector2i) -> void:
	if not def.job.has_work_area():
		return
	var tile := _world.get_tile_size()
	var center_cell := Vector2(origin) + Vector2(def.footprint - Vector2i.ONE) / 2.0
	var center := to_local(_world.grid_to_world(Vector2i.ZERO) + center_cell * tile)
	var radius := (def.job.work_radius + 0.5) * tile.x
	_overlay.draw_circle(center, radius, RADIUS_FILL)
	_overlay.draw_arc(center, radius, 0.0, TAU, RADIUS_SEGMENTS, RADIUS_LINE, 2.0)
