class_name Settler
extends Node2D

signal arrived(grid_pos: Vector2i)
signal path_failed(grid_pos: Vector2i)

enum Sex { MALE, FEMALE }
enum AgeStage { CHILD, ADULT, ELDER }

const SPEED_TILES_PER_SECOND := 3.0
const REST_CALL := 25.0
const REST_FULL := 95.0
const TOOL_LIFETIME := 720.0
const NO_TOOL_SPEED := 0.5
const CHILD_AGE := 10.0
const ELDER_AGE := 60.0
const ELDER_SPEED := 0.7
const STAGE_NAMES := ["Child", "Adult", "Elder"]
const STEP_PIXELS := 9.0
const WORK_FRAME_SECONDS := 0.28
const OUTLINE_SHADER: Shader = preload("res://assets/shaders/structure_outline.gdshader")
const OUTLINE_COLORS: Array[Color] = [Color(1.0, 1.0, 1.0, 0.9), Color(1.0, 0.85, 0.3, 1.0)]

enum Facing { DOWN, UP, SIDE }

static var _outline_materials: Array[ShaderMaterial] = []

var world: WorldGrid
var pathfinder: GridPathfinder
var needs: Needs
var worker: Worker
var buildings: BuildController
var profession: StringName = Professions.LABORER
var home: Building
var display_id := 0
var given_name := ""
var sex := Sex.MALE
var age := 20.0
var partner: Settler
var parents: Array[Settler] = []
var carried_id: StringName
var carried_amount := 0
var has_tool := false
var tool_wear := 0.0
var _last_cell := Vector2i.ZERO
var _destination := Vector2i.ZERO
var _path: Array[Vector2i] = []
var _moving := false
var _home_cell := Vector2i.ZERO
var _resting := false
var _warming := false
var hovered := false
var selected := false
var _body: Sprite2D
var _carry: Sprite2D
var _facing := Facing.DOWN
var _walk_distance := 0.0
var _work_time := 0.0
var _flip := false
var _shown_row := -1
var _shown_frame := -1
var _shown_outline := -1
var _shown_carry := &""


func _ready() -> void:
	needs = Needs.new()
	add_child(needs)
	needs.ticked.connect(_on_needs_ticked)
	needs.meal_provider = _meal_source
	worker = Worker.new()
	add_child(worker)
	_body = Sprite2D.new()
	_body.centered = false
	_body.offset = SettlerArt.SPRITE_OFFSET
	_body.texture = SettlerArt.SHEET
	_body.region_enabled = true
	add_child(_body)
	_carry = Sprite2D.new()
	_carry.visible = false
	add_child(_carry)
	_sync_sprite()


func setup(world_grid: WorldGrid, grid_pathfinder: GridPathfinder, build_controller: BuildController, grid_pos: Vector2i) -> void:
	world = world_grid
	pathfinder = grid_pathfinder
	buildings = build_controller
	_last_cell = grid_pos
	global_position = world.grid_to_world(grid_pos)


func get_grid_pos() -> Vector2i:
	return _last_cell


func get_age_stage() -> AgeStage:
	if age < CHILD_AGE:
		return AgeStage.CHILD
	if age >= ELDER_AGE:
		return AgeStage.ELDER
	return AgeStage.ADULT


func get_stage_name() -> String:
	return STAGE_NAMES[get_age_stage()]


func is_working_age() -> bool:
	return age >= CHILD_AGE


func lives_with_parent() -> bool:
	for parent in parents:
		if home != null and parent.home == home:
			return true
	return false


func is_kin_of(other: Settler) -> bool:
	for parent in parents:
		if other.parents.has(parent) or other == parent:
			return true
	return other.parents.has(self)


func set_age(value: float) -> void:
	age = value


func needs_tool() -> bool:
	return not has_tool and (worker.building != null or profession == Professions.BUILDER)


func work_speed() -> float:
	var speed := 1.0 if has_tool else NO_TOOL_SPEED
	return speed * ELDER_SPEED if get_age_stage() == AgeStage.ELDER else speed


func wear_tool(seconds: float) -> void:
	if not has_tool:
		return
	tool_wear += seconds / TOOL_LIFETIME
	if tool_wear >= 1.0:
		has_tool = false
		tool_wear = 0.0


func equip_tool() -> void:
	has_tool = true
	tool_wear = 0.0


func get_home_cell() -> Vector2i:
	return _home_cell


func is_at_home() -> bool:
	return home != null and _last_cell == _home_cell and not _moving


func is_moving() -> bool:
	return _moving


func is_carrying() -> bool:
	return carried_amount > 0


func set_carried(id: StringName, amount: int) -> void:
	carried_id = id if amount > 0 else StringName()
	carried_amount = maxi(amount, 0)


func move_to(grid_pos: Vector2i) -> bool:
	_destination = grid_pos
	_moving = true
	return _replan()


func cancel_movement() -> void:
	_moving = false
	_path.clear()


func _process(delta: float) -> void:
	if _moving:
		if not world.is_walkable(_path[0]):
			_replan()
		else:
			_step(delta)
	_animate(delta)


func _step(delta: float) -> void:
	var target := world.grid_to_world(_path[0])
	var speed := SPEED_TILES_PER_SECOND * world.get_tile_size().x * world.get_speed_multiplier(_path[0])
	var before := global_position
	var direction := target - before
	if absf(direction.x) >= absf(direction.y):
		_facing = Facing.SIDE
		_flip = direction.x < 0.0
	else:
		_facing = Facing.DOWN if direction.y > 0.0 else Facing.UP
	global_position = before.move_toward(target, speed * delta)
	_walk_distance += before.distance_to(global_position)
	if global_position == target:
		_last_cell = _path.pop_front()
		if _path.is_empty():
			_arrive()


func set_hovered(value: bool) -> void:
	hovered = value


func set_selected(value: bool) -> void:
	selected = value


func tooltip_text() -> String:
	var title := given_name
	if get_age_stage() == AgeStage.CHILD:
		return "%s, child" % title
	return "%s, %s%s" % [title, Professions.display_name(profession), " (elder)" if get_age_stage() == AgeStage.ELDER else ""]


func _animate(delta: float) -> void:
	var frame := 1
	var bob := 0.0
	if _moving:
		var phase := int(_walk_distance / STEP_PIXELS) % 4
		frame = int(_facing) * 4 + phase
		bob = -1.0 if phase % 2 == 1 else 0.0
	elif worker != null and worker.is_working():
		_facing = Facing.DOWN
		_work_time += delta
		frame = SettlerArt.WORK_FRAME + int(_work_time / WORK_FRAME_SECONDS) % 2
	else:
		frame = int(_facing) * 4 + 1
	_body.flip_h = _flip and _facing == Facing.SIDE and frame < SettlerArt.WORK_FRAME
	_sync_sprite(frame)
	_carry.position.y = SettlerArt.HEAD_TOP[get_age_stage()] - 7.0 + bob


func _sync_sprite(frame := 1) -> void:
	var sheet_row := SettlerArt.row(display_id, get_age_stage(), sex, profession)
	if sheet_row != _shown_row or frame != _shown_frame:
		_shown_row = sheet_row
		_shown_frame = frame
		_body.region_rect = SettlerArt.frame_rect(sheet_row, frame)
	var outline := 2 if selected else (1 if hovered else 0)
	if outline != _shown_outline:
		_shown_outline = outline
		_body.material = _outline_material(outline)
	var carried := carried_id if carried_amount > 0 else &""
	if carried != _shown_carry:
		_shown_carry = carried
		var icon := SettlerArt.carry_texture(carried) if carried != &"" else null
		_carry.texture = icon
		_carry.visible = icon != null


static func _outline_material(mode: int) -> ShaderMaterial:
	if mode <= 0:
		return null
	if _outline_materials.is_empty():
		for color in OUTLINE_COLORS:
			var material := ShaderMaterial.new()
			material.shader = OUTLINE_SHADER
			material.set_shader_parameter("outline_color", color)
			_outline_materials.append(material)
	return _outline_materials[mode - 1]


func assign_home(house: Building) -> bool:
	var cells := house.get_access_cells()
	if cells.is_empty():
		return false
	unassign_home()
	home = house
	_home_cell = cells[0]
	house.residents.append(self)
	needs.sheltered = true
	return true


func unassign_home() -> void:
	if home:
		home.residents.erase(self)
	home = null
	needs.sheltered = false
	_resting = false
	_warming = false
	needs.diet_modifier = 0.0


func _meal_source() -> Inventory:
	return home.household if is_at_home() else null


func _on_needs_ticked() -> void:
	needs.at_home = is_at_home()
	needs.warm = needs.at_home and home.is_heated()
	needs.diet_modifier = _diet_modifier()
	_update_resting()
	_update_warming()
	var recovering := _resting or _warming
	if recovering:
		worker.pause()
	else:
		worker.resume()
		if needs.is_critical():
			worker.serve_hunger()
	if recovering and not _moving and not is_at_home():
		move_to(_home_cell)


func _diet_modifier() -> float:
	if home == null:
		return 0.0
	var kinds := home.diet_kinds()
	if kinds >= Building.DIET_VARIETY_KINDS:
		return Needs.DIET_BONUS
	if kinds == 1:
		return -Needs.DIET_PENALTY
	return 0.0


func _update_warming() -> void:
	if home == null or not TimeManager.is_cold() or not home.is_heated():
		_warming = false
	elif needs.warmth < Needs.COLD_CALL:
		_warming = true
	elif needs.warmth >= Needs.WARM_FULL:
		_warming = false


func _update_resting() -> void:
	if home == null:
		_resting = false
	elif needs.rest <= REST_CALL:
		_resting = true
	elif needs.rest >= REST_FULL:
		_resting = false


func _replan() -> bool:
	var path := pathfinder.find_path(_last_cell, _destination)
	if path.is_empty():
		_moving = false
		_path.clear()
		path_failed.emit(_destination)
		return false
	path.pop_front()
	_path = path
	if _path.is_empty():
		_arrive()
	return true


func _arrive() -> void:
	_moving = false
	arrived.emit(_destination)
