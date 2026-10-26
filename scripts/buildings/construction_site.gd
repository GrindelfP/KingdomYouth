class_name ConstructionSite
extends Structure

signal completed(site: ConstructionSite)

const SITE_COLOR := Color(0.55, 0.5, 0.4, 0.8)
const PROGRESS_COLOR := Color.WHITE
const MATERIALS_COLOR := Color(0.9, 0.6, 0.2)
const BAR_HEIGHT := 4.0
const FONT_SIZE := 10

var required: Dictionary = {}
var delivered: Inventory
var progress := 0.0
var active_builders := 0
var _reserved: Dictionary = {}
var _frame_builders := 0
var _done := false


func setup(world: WorldGrid, building_def: BuildingDef, grid_origin: Vector2i) -> void:
	bind_to_grid(world, building_def, grid_origin)
	required = def.cost.duplicate()
	var total := 0
	for id in required:
		total += int(required[id])
	delivered = Inventory.new(total)


func _process(_delta: float) -> void:
	active_builders = _frame_builders
	_frame_builders = 0
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


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, _size), SITE_COLOR)
	draw_rect(Rect2(Vector2.ZERO, Vector2(_size.x * progress_ratio(), BAR_HEIGHT)), PROGRESS_COLOR)
	draw_rect(Rect2(Vector2(0.0, BAR_HEIGHT), Vector2(_size.x * material_ratio(), BAR_HEIGHT)), MATERIALS_COLOR)
	if not is_ready():
		draw_string(ThemeDB.fallback_font, Vector2(2.0, _size.y - 3.0), "waiting for materials", HORIZONTAL_ALIGNMENT_LEFT, _size.x, FONT_SIZE, Color.BLACK)
