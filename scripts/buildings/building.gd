class_name Building
extends Structure

signal crops_lost(count: int)

const OUTPUT_CAPACITY := 20
const FIELD_OUTPUT_CAPACITY := 40
const FIELD_UPDATE_INTERVAL := 0.25
const VISUAL_INTERVAL := 0.3
const FIELD_Z := -5
const GLOW_PULSE := 4.0
const INPUT_CAPACITY := 20
const BATCHES_PER_TRIP := 5
const HOUSEHOLD_CAPACITY := 50
const FOOD_TARGET := 30
const FIREWOOD_TARGET := 20
const RESTOCK_TRIP := Hauler.CARRY_SIZE
const FUEL_ID := &"firewood"
const TOOL_ID := &"tools"
const DIET_VARIETY_KINDS := 3

var workers: Array[Settler] = []
var residents: Array[Settler] = []
var heat_left := 0.0
var desired_workers := 0
var output_claimed := 0
var storage: Inventory
var output: Inventory
var input: Inventory
var household: Inventory
var restock_claimed := false
var field: CropField
var _field_timer := 0.0
var _visual_timer := 0.0
var _smoke: CPUParticles2D
var _glow: Sprite2D
var _piles: Node2D
var _pile_signature := ""
var _glow_time := 0.0


func setup(world: WorldGrid, building_def: BuildingDef, grid_origin: Vector2i) -> void:
	bind_to_grid(world, building_def, grid_origin)
	if def.is_storage():
		storage = Inventory.new(def.storage_capacity)
		ResourceStockpile.register_storage(self)
	if def.job:
		output = Inventory.new(FIELD_OUTPUT_CAPACITY if def.is_field() else OUTPUT_CAPACITY)
		desired_workers = def.job.slots
		if def.job.has_inputs():
			input = Inventory.new(INPUT_CAPACITY)
	if def.housing_capacity > 0:
		household = Inventory.new(HOUSEHOLD_CAPACITY)
	if def.is_field():
		field = CropField.new(def.footprint.x)
		field.cell_changed.connect(_on_field_cell_changed)
		field.cells_reloaded.connect(queue_redraw)
		field.crop_changed.connect(queue_redraw)
		world.set_open(def.get_cells(origin), true)
		TimeManager.season_changed.connect(_on_season_changed)
		TimeManager.month_changed.connect(_on_month_changed)
		z_index = FIELD_Z
	else:
		_build_visuals()
	queue_redraw()


func _exit_tree() -> void:
	if storage:
		ResourceStockpile.unregister_storage(self)
	if field:
		TimeManager.season_changed.disconnect(_on_season_changed)
		TimeManager.month_changed.disconnect(_on_month_changed)


func _process(delta: float) -> void:
	_visual_timer += delta
	if _visual_timer >= VISUAL_INTERVAL:
		_visual_timer = 0.0
		_update_effects()
	if _glow != null and _glow.visible:
		_glow_time += delta
		_glow.modulate.a = 0.55 + 0.25 * sin(_glow_time * GLOW_PULSE) + 0.1 * sin(_glow_time * 9.3)
	if field == null:
		return
	_field_timer += delta
	if _field_timer >= FIELD_UPDATE_INTERVAL:
		_field_timer = 0.0
		field.update()


func get_output_id() -> StringName:
	return field.crop if field else def.job.primary_output()


func field_cell_to_grid(cell: Vector2i) -> Vector2i:
	return origin + cell


func grid_to_field_cell(grid_pos: Vector2i) -> Vector2i:
	return grid_pos - origin


func job_def() -> JobDef:
	return def.job


func is_storage() -> bool:
	return storage != null


func is_output_blocked() -> bool:
	if output == null:
		return false
	return output.free_space() < def.job.output_total() and ResourceStockpile.find_storages(get_output_id(), get_center_cell()).is_empty()


func forest_cell_count() -> int:
	return _world.count_terrain_in_radius("forest", get_work_center(), def.job.work_radius)


func work_efficiency() -> float:
	var job := def.job
	var efficiency := 1.0
	if job.density_cells > 0:
		efficiency = minf(float(forest_cell_count()) / job.density_cells, 1.0)
	if TimeManager.is_cold():
		efficiency *= job.winter_factor
	return efficiency


func has_batch() -> bool:
	if input == null:
		return true
	for entry in def.job.inputs:
		if input.get_amount(StringName(entry["id"])) < int(entry["amount"]):
			return false
	return true


func missing_input() -> StringName:
	if input == null:
		return &""
	var worst := &""
	var worst_ratio := INF
	for entry in def.job.inputs:
		var id := StringName(entry["id"])
		var ratio := float(input.get_amount(id)) / int(entry["amount"])
		if ratio < 1.0 and ratio < worst_ratio:
			worst = id
			worst_ratio = ratio
	return worst


func input_trip_amount(id: StringName) -> int:
	var wanted := def.job.input_amount(id) * BATCHES_PER_TRIP - input.get_amount(id)
	return clampi(mini(wanted, input.free_space()), 0, Hauler.CARRY_SIZE)


func consume_batch() -> bool:
	if not has_batch():
		return false
	for entry in def.job.inputs:
		input.take(StringName(entry["id"]), int(entry["amount"]))
	return true


func food_stock() -> int:
	return household.category_total(ResourceDef.Category.FOOD) if household else 0


func firewood_stock() -> int:
	return household.get_amount(FUEL_ID) if household else 0


func needs_food() -> bool:
	return household != null and food_stock() * 2 < FOOD_TARGET


func needs_firewood() -> bool:
	return household != null and firewood_stock() * 2 < FIREWOOD_TARGET


func diet_kinds() -> int:
	return household.kind_count(ResourceDef.Category.FOOD) if household else 0


func is_heated() -> bool:
	return heat_left > 0.0


func has_free_housing() -> bool:
	return def.housing_capacity > 0 and residents.size() < def.housing_capacity


func has_free_job_slot() -> bool:
	return def.job != null and workers.size() < def.job.slots


func _on_field_cell_changed(_cell: Vector2i) -> void:
	queue_redraw()


func _on_month_changed(_month: int) -> void:
	field.update()
	queue_redraw()


func _on_season_changed(season: int) -> void:
	if season == TimeManager.Season.SPRING:
		field.begin_season()
	elif season == TimeManager.Season.WINTER:
		var lost := field.frost()
		if lost > 0:
			crops_lost.emit(lost)


func _build_visuals() -> void:
	_sprite = Sprite2D.new()
	_sprite.centered = false
	add_child(_sprite)
	if def.is_storage() and def.id == &"stockpile":
		_piles = Node2D.new()
		add_child(_piles)
	var tex := BuildingArt.texture(def, _winter)
	if BuildingArt.SMOKE_POINTS.has(def.id):
		_smoke = _make_smoke(BuildingArt.sprite_point_to_local(BuildingArt.SMOKE_POINTS[def.id], tex))
		add_child(_smoke)
	if BuildingArt.GLOW_POINTS.has(def.id):
		_glow = Sprite2D.new()
		_glow.texture = BuildingArt.GLOW_TEXTURE
		_glow.position = BuildingArt.sprite_point_to_local(BuildingArt.GLOW_POINTS[def.id], tex)
		_glow.scale = Vector2(1.5, 1.0)
		var material := CanvasItemMaterial.new()
		material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_glow.material = material
		_glow.visible = false
		add_child(_glow)
	_refresh_art()
	_apply_outline()


func _make_smoke(at: Vector2) -> CPUParticles2D:
	var smoke := CPUParticles2D.new()
	smoke.texture = BuildingArt.SMOKE_TEXTURE
	smoke.position = at
	smoke.amount = 18
	smoke.lifetime = 2.6
	smoke.local_coords = false
	smoke.direction = Vector2(0.3, -1.0)
	smoke.spread = 14.0
	smoke.gravity = Vector2(5.0, -4.0)
	smoke.initial_velocity_min = 7.0
	smoke.initial_velocity_max = 12.0
	smoke.scale_amount_min = 1.0
	smoke.scale_amount_max = 1.7
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.7, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.75), Color(1, 1, 1, 0.0)])
	smoke.color_ramp = fade
	smoke.emitting = false
	return smoke


func _refresh_art() -> void:
	if field != null:
		queue_redraw()
		return
	if _sprite == null:
		return
	var tex := BuildingArt.texture(def, _winter)
	_sprite.texture = tex
	_sprite.offset = BuildingArt.sprite_offset(tex)
	_pile_signature = ""
	_update_effects()


func _update_effects() -> void:
	if _smoke != null:
		_smoke.emitting = is_heated() if def.housing_capacity > 0 else not workers.is_empty()
	if _glow != null:
		_glow.visible = not workers.is_empty()
	if _piles != null:
		_refresh_piles()


func _refresh_piles() -> void:
	var stages := {}
	var signature := "%d" % int(_winter)
	for good in BuildingArt.PILE_GOODS:
		var stage := BuildingArt.pile_stage(storage.get_amount(good))
		stages[good] = stage
		signature += str(stage)
	if signature == _pile_signature:
		return
	_pile_signature = signature
	for child in _piles.get_children():
		child.queue_free()
	var order: Array[StringName] = [&"logs", &"stone", &"firewood", &"iron", &"tools"]
	for good in order:
		var stage: int = stages[good]
		if stage == 0:
			continue
		var pile := Sprite2D.new()
		pile.centered = false
		pile.texture = BuildingArt.pile_texture(good, stage, _winter)
		pile.position = BuildingArt.PILE_SLOTS[good] - BuildingArt.PILE_BASE
		_piles.add_child(pile)


func _draw() -> void:
	if field == null:
		return
	var tile := _world.get_tile_size()
	var top_left := local_rect().position
	var row_winter := _winter
	for y in field.size:
		for x in field.size:
			var cell := Vector2i(x, y)
			var state := field.get_state(cell)
			var column := BuildingArt.field_column(state, field.crop, field.get_growth(cell), cell)
			draw_texture_rect_region(BuildingArt.FIELD_TEXTURE, Rect2(top_left + Vector2(cell) * tile, tile), BuildingArt.field_region(column, row_winter))
	draw_texture(BuildingArt.fence_texture(def.footprint.x), BuildingArt.fence_offset(def.footprint.x))
	if _outline_mode > 0:
		draw_rect(local_rect().grow(2.0), OUTLINE_COLORS[_outline_mode], false, 2.0)
