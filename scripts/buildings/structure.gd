class_name Structure
extends Node2D

const ACCESS_OFFSETS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

var def: BuildingDef
var origin: Vector2i
const OUTLINE_SHADER: Shader = preload("res://assets/shaders/structure_outline.gdshader")
const OUTLINE_COLORS: Array[Color] = [Color(0, 0, 0, 0), Color(1.0, 1.0, 1.0, 0.85), Color(1.0, 0.85, 0.3, 1.0)]
const WINTER := 3

static var _outline_materials: Array[ShaderMaterial] = []

var _world: WorldGrid
var _size: Vector2
var _winter := false
var _outline_mode := 0
var _sprite: Sprite2D


func bind_to_grid(world: WorldGrid, building_def: BuildingDef, grid_origin: Vector2i) -> void:
	_world = world
	def = building_def
	origin = grid_origin
	_size = Vector2(def.footprint) * world.get_tile_size()
	global_position = world.get_cell_rect(origin).position + Vector2(_size.x * 0.5, _size.y)
	var view := world.get_node_or_null("TerrainView") as TerrainView
	if view != null:
		_winter = view.get_season() == WINTER
		view.season_applied.connect(_on_season_applied)


func local_rect() -> Rect2:
	return Rect2(Vector2(-_size.x * 0.5, -_size.y), _size)


func display_name() -> String:
	return def.display_name


func set_outline(mode: int) -> void:
	if mode == _outline_mode:
		return
	_outline_mode = mode
	_apply_outline()
	queue_redraw()


func _apply_outline() -> void:
	if _sprite != null:
		_sprite.material = _outline_material(_outline_mode)


static func _outline_material(mode: int) -> ShaderMaterial:
	if mode <= 0:
		return null
	if _outline_materials.is_empty():
		for index in OUTLINE_COLORS.size():
			var material := ShaderMaterial.new()
			material.shader = OUTLINE_SHADER
			material.set_shader_parameter("outline_color", OUTLINE_COLORS[index])
			_outline_materials.append(material)
	return _outline_materials[mode]


func _on_season_applied(season: int, _animate: bool) -> void:
	_winter = season == WINTER
	_refresh_art()


func _refresh_art() -> void:
	pass


func world() -> WorldGrid:
	return _world


func is_alive() -> bool:
	return is_instance_valid(self) and not is_queued_for_deletion()


func occupies(grid_pos: Vector2i) -> bool:
	return def.get_cells(origin).has(grid_pos)


func get_center_cell() -> Vector2i:
	return origin + (def.footprint - Vector2i.ONE) / 2


func get_work_center() -> Vector2:
	return Vector2(origin) + Vector2(def.footprint - Vector2i.ONE) / 2.0


func get_access_cells() -> Array[Vector2i]:
	var footprint_cells := def.get_cells(origin)
	var cells: Array[Vector2i] = []
	for cell in footprint_cells:
		for offset in ACCESS_OFFSETS:
			var neighbour: Vector2i = cell + offset
			if not footprint_cells.has(neighbour) and not cells.has(neighbour) and _world.is_walkable(neighbour):
				cells.append(neighbour)
	return cells
