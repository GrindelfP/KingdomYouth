class_name ConstructionSite
extends Structure

signal completed(site: ConstructionSite)

const PROGRESS_COLOR := Color.WHITE
const MATERIALS_COLOR := Color(0.9, 0.6, 0.2)
const BAR_BACK := Color(0.1, 0.08, 0.12, 0.7)
const BAR_HEIGHT := 3.0
const BAR_GAP := 5.0
const GHOST_ALPHA := 0.55
const GHOST_TINT := Color(0.75, 0.88, 1.0)
const FIELD_Z := -5
const STAGES := 3

var required: Dictionary = {}
var delivered: Inventory
var progress := 0.0
var active_builders := 0
var _reserved: Dictionary = {}
var _frame_builders := 0
var _done := false
var _ghost: Sprite2D
var _stage_sprite: Sprite2D
var _stage := -1


func setup(world: WorldGrid, building_def: BuildingDef, grid_origin: Vector2i) -> void:
	bind_to_grid(world, building_def, grid_origin)
	required = def.cost.duplicate()
	var total := 0
	for id in required:
		total += int(required[id])
	delivered = Inventory.new(total)
	_build_visuals()


func _process(_delta: float) -> void:
	active_builders = _frame_builders
	_frame_builders = 0
	_update_visuals()
	if _outline_mode > 0:
		queue_redraw()


func missing(id: StringName) -> int:
	return maxi(int(required.get(id, 0)) - delivered.get_amount(id) - int(_reserved.get(id, 0)), 0)


func reserve(id: StringName, amount: int) -> void:
	_reserved[id] = int(_reserved.get(id, 0)) + amount


func release(id: StringName, amount: int) -> void:
	var left := maxi(int(_reserved.get(id, 0)) - amount, 0)
	if left == 0:
		_reserved.erase(id)
	else:
		_reserved[id] = left


func is_ready() -> bool:
	for id in required:
		if delivered.get_amount(id) < int(required[id]):
			return false
	return true


func material_ratio() -> float:
	if delivered.capacity <= 0:
		return 1.0
	return clampf(float(delivered.total()) / delivered.capacity, 0.0, 1.0)


func progress_ratio() -> float:
	return clampf(progress / def.build_time, 0.0, 1.0)


func status_text() -> String:
	if not is_ready():
		return "Waiting for materials"
	if active_builders == 0:
		return "Waiting for builders"
	return "Building (%d builders)" % active_builders


func add_work(seconds: float) -> void:
	if _done or not is_ready():
		return
	_frame_builders += 1
	progress += seconds
	if progress >= def.build_time:
		_done = true
		completed.emit(self)


func refund() -> void:
	for id in delivered.ids():
		ResourceStockpile.add(id, delivered.take(id, delivered.get_amount(id)))


func display_name() -> String:
	return "%s (under construction)" % def.display_name


func _build_visuals() -> void:
	if def.is_field():
		z_index = FIELD_Z
	_stage_sprite = Sprite2D.new()
	_stage_sprite.centered = false
	_stage_sprite.offset = BuildingArt.site_offset(def)
	add_child(_stage_sprite)
	if not def.is_field():
		_ghost = Sprite2D.new()
		_ghost.centered = false
		add_child(_ghost)
	_sprite = _stage_sprite
	_refresh_art()
	_update_visuals()
	_apply_outline()


func _refresh_art() -> void:
	if _ghost != null:
		var tex := BuildingArt.texture(def, _winter)
		_ghost.texture = tex
		_ghost.offset = BuildingArt.sprite_offset(tex)
	queue_redraw()


func _update_visuals() -> void:
	if _stage_sprite == null:
		return
	var stage := clampi(int(progress_ratio() * STAGES), 0, STAGES - 1)
	if stage != _stage:
		_stage = stage
		_stage_sprite.texture = BuildingArt.site_texture(def, stage)
	if _ghost != null:
		var alpha := GHOST_ALPHA * (1.0 - material_ratio())
		_ghost.visible = alpha > 0.02
		_ghost.modulate = Color(GHOST_TINT.r, GHOST_TINT.g, GHOST_TINT.b, alpha)


func _draw() -> void:
	if def.is_field():
		var tile := _world.get_tile_size()
		var top_left := local_rect().position
		for y in def.footprint.y:
			for x in def.footprint.x:
				var column := BuildingArt.field_column(CropField.CellState.EMPTY, &"", 0.0, Vector2i(x, y))
				draw_texture_rect_region(BuildingArt.FIELD_TEXTURE, Rect2(top_left + Vector2(x, y) * tile, tile), BuildingArt.field_region(column, _winter))
	if _outline_mode == 0:
		return
	var width := _size.x
	var x0 := -width * 0.5
	draw_rect(Rect2(x0, BAR_GAP - 1.0, width, BAR_HEIGHT * 2.0 + 3.0), BAR_BACK)
	draw_rect(Rect2(x0, BAR_GAP, width * progress_ratio(), BAR_HEIGHT), PROGRESS_COLOR)
	draw_rect(Rect2(x0, BAR_GAP + BAR_HEIGHT + 1.0, width * material_ratio(), BAR_HEIGHT), MATERIALS_COLOR)
