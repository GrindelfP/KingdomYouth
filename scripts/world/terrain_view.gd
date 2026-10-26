class_name TerrainView
extends Node2D

signal season_applied(season: int, animate: bool)

const TILE := 32
const GROUND_TEXTURE: Texture2D = preload("res://assets/art/terrain/ground.png")
const SHORE_TEXTURE: Texture2D = preload("res://assets/art/terrain/shore.png")
const GROUND_COLUMNS := 12
const FLIPPABLE_COLUMNS := 10
const FOREST_COLUMN := 6
const ROCK_COLUMN := 8
const WATER_COLUMN := 10
const TONE_FREQUENCY := 0.07
const TONES: Array[Color] = [Color(1.0, 1.0, 1.0), Color(0.97, 0.98, 0.97), Color(1.03, 1.03, 0.99)]
const TONED_COLUMNS := 6
const GRASS_POOL: Array[int] = [0, 0, 0, 1, 1, 1, 2, 2, 3, 4, 5]
const FADE_SECONDS := 3.0
const SHIMMER_SECONDS := 0.9
const WINTER := 3
const GRADES: Array[Color] = [Color(1.02, 1.03, 0.99), Color(1.03, 1.01, 0.97), Color(1.05, 0.97, 0.9), Color(0.95, 0.98, 1.04)]
const SIDES: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
const CORNERS: Array[Vector2i] = [Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1)]

class Stack:
	extends Node2D
	var ground: TileMapLayer
	var shore: TileMapLayer
	var roads: RoadLayer

	func _init(ground_set: TileSet, shore_set: TileSet) -> void:
		z_index = -10
		ground = TileMapLayer.new()
		ground.tile_set = ground_set
		add_child(ground)
		shore = TileMapLayer.new()
		shore.tile_set = shore_set
		add_child(shore)
		roads = RoadLayer.new()
		add_child(roads)

var _world: WorldGrid
var _stacks: Array[Stack] = []
var _front := 0
var _season := -1
var _grade: CanvasModulate
var _tween: Tween
var _col := PackedInt32Array()
var _alt := PackedInt32Array()
var _shore_index := PackedInt32Array()
var _shore_row := PackedByteArray()
var _water_cells: Array[int] = []
var _phase := 0
var _tone_noise := FastNoiseLite.new()
var _shimmer_time := 0.0


func _ready() -> void:
	_world = get_parent()
	_tone_noise.seed = WorldGrid.MAP_SEED + 3
	_tone_noise.frequency = TONE_FREQUENCY
	var ground_set := _make_tileset(GROUND_TEXTURE, GROUND_COLUMNS, 4, FLIPPABLE_COLUMNS)
	var shore_set := _make_tileset(SHORE_TEXTURE, ShoreMask.keys().size(), 8, 0)
	for index in 2:
		var stack := Stack.new(ground_set, shore_set)
		stack.roads.setup(_world)
		stack.visible = index == 0
		add_child(stack)
		_stacks.append(stack)
	_grade = CanvasModulate.new()
	_grade.name = "Grade"
	add_child(_grade)
	_world.map_generated.connect(_rebuild)
	_world.trees_reloaded.connect(_rebuild)
	_world.trees_changed.connect(_on_cell_changed)
	TimeManager.season_changed.connect(_on_season_changed)


func _process(delta: float) -> void:
	if _season < 0 or _season == WINTER or _water_cells.is_empty():
		return
	_shimmer_time += delta
	if _shimmer_time < SHIMMER_SECONDS:
		return
	_shimmer_time = 0.0
	_phase = 1 - _phase
	for i in _water_cells:
		var cell := _cell_of(i)
		for stack in _stacks:
			stack.ground.set_cell(cell, 0, Vector2i(_tile_column(i), maxi(_season, 0)))


func get_season() -> int:
	return _season


func set_season(season: int, animate: bool) -> void:
	if season == _season:
		return
	var previous := _season
	_season = season
	_finish_fade()
	var back := _stacks[1 - _front]
	var front := _stacks[_front]
	_paint(back, season)
	_front = 1 - _front
	if animate and previous >= 0:
		back.modulate.a = 0.0
		back.visible = true
		move_child(back, get_child_count() - 1)
		_tween = create_tween()
		_tween.tween_property(back, "modulate:a", 1.0, FADE_SECONDS)
		_tween.parallel().tween_property(_grade, "color", GRADES[season], FADE_SECONDS)
		_tween.finished.connect(_finish_fade)
	else:
		back.modulate.a = 1.0
		back.visible = true
		front.visible = false
		_grade.color = GRADES[season]
	season_applied.emit(season, animate and previous >= 0)


func _finish_fade() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	if _stacks.is_empty() or _season < 0:
		return
	var front := _stacks[_front]
	front.modulate.a = 1.0
	front.visible = true
	_stacks[1 - _front].visible = false
	_grade.color = GRADES[_season]


func _on_season_changed(season: int) -> void:
	set_season(season, true)


func _rebuild() -> void:
	_assign_cells()
	var season := TimeManager.get_season() as int
	_season = -1
	set_season(season, false)


func _assign_cells() -> void:
	var bounds := _world.get_map_bounds()
	var total := bounds.size.x * bounds.size.y
	_col.resize(total)
	_alt.resize(total)
	_shore_index.resize(total)
	_shore_row.resize(total)
	_water_cells.clear()
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			var cell := Vector2i(x, y)
			var i := _index_of(cell)
			_choose_variant(cell)
			_assign_shore(cell)
			if _col[i] >= WATER_COLUMN:
				_water_cells.append(i)


func _choose_variant(cell: Vector2i) -> void:
	var i := _index_of(cell)
	var terrain_name := _world.get_terrain_name(cell)
	var base := 0
	var count := GRASS_POOL.size()
	match terrain_name:
		"forest":
			base = FOREST_COLUMN
			count = 2
		"rock":
			base = ROCK_COLUMN
			count = 2
		"water":
			base = WATER_COLUMN
			count = 2
	var noise := _tone_noise.get_noise_2d(cell.x, cell.y)
	var tone := 1 if noise < -0.18 else (2 if noise > 0.22 else 0)
	var left := _variant_key(cell + Vector2i.LEFT)
	var up := _variant_key(cell + Vector2i.UP)
	var column := base
	var alt := 0
	for attempt in 8:
		var h := _hash(cell, attempt)
		var pick := h % count
		column = GRASS_POOL[pick] if count == GRASS_POOL.size() else base + pick
		alt = (tone * 2 if column < TONED_COLUMNS else 0) + ((h >> 9) & 1) if column < FLIPPABLE_COLUMNS else 0
		var key := column * 2 + (alt & 1)
		if key != left and key != up:
			break
	_col[i] = column
	_alt[i] = alt


func _variant_key(cell: Vector2i) -> int:
	if not _world.is_in_bounds(cell):
		return -1
	var i := _index_of(cell)
	if i >= _col.size():
		return -1
	return _col[i] * 2 + (_alt[i] & 1)


func _assign_shore(cell: Vector2i) -> void:
	var i := _index_of(cell)
	var is_water := _world.get_terrain_name(cell) == "water"
	var sides := 0
	var corners := 0
	for bit in 4:
		if _differs(cell + SIDES[bit], is_water):
			sides |= 1 << bit
		if _differs(cell + CORNERS[bit], is_water):
			corners |= 1 << bit
	var key := ShoreMask.key(sides, corners)
	if key == 0:
		_shore_index[i] = -1
	else:
		_shore_index[i] = ShoreMask.index_of(key)
	_shore_row[i] = 1 if is_water else 0


func _differs(cell: Vector2i, is_water: bool) -> bool:
	if not _world.is_in_bounds(cell):
		return false
	return (_world.get_terrain_name(cell) == "water") != is_water


func _on_cell_changed(cell: Vector2i) -> void:
	if _season < 0:
		return
	_choose_variant(cell)
	var i := _index_of(cell)
	for stack in _stacks:
		stack.ground.set_cell(cell, 0, Vector2i(_tile_column(i), _season), _alt[i] & 1 if _season == WINTER else _alt[i])


func _paint(stack: Stack, season: int) -> void:
	stack.shore.clear()
	var bounds := _world.get_map_bounds()
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			var cell := Vector2i(x, y)
			var i := _index_of(cell)
			var alt := _alt[i] & 1 if season == WINTER else _alt[i]
			stack.ground.set_cell(cell, 0, Vector2i(_tile_column(i), season), alt)
			if _shore_index[i] >= 0:
				stack.shore.set_cell(cell, 0, Vector2i(_shore_index[i], season * 2 + _shore_row[i]))
	stack.roads.season = season


func _tile_column(i: int) -> int:
	var column := _col[i]
	if column >= WATER_COLUMN:
		return WATER_COLUMN + ((column - WATER_COLUMN + _phase) % 2)
	return column


func _index_of(cell: Vector2i) -> int:
	var bounds := _world.get_map_bounds()
	return (cell.y - bounds.position.y) * bounds.size.x + (cell.x - bounds.position.x)


func _cell_of(i: int) -> Vector2i:
	var bounds := _world.get_map_bounds()
	return Vector2i(i % bounds.size.x, i / bounds.size.x) + bounds.position


static func _hash(cell: Vector2i, salt: int) -> int:
	var h := (cell.x * 374761393 + cell.y * 668265263 + salt * 1274126177 + WorldGrid.MAP_SEED) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1103515245) & 0x7fffffff
	return h ^ (h >> 16)


static func _make_tileset(texture: Texture2D, columns: int, rows: int, flippable: int) -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE, TILE)
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(TILE, TILE)
	tile_set.add_source(source, 0)
	for row in rows:
		for column in columns:
			var coords := Vector2i(column, row)
			source.create_tile(coords)
			if column < flippable:
				for alt in range(1, 6):
					source.create_alternative_tile(coords, alt)
					var data := source.get_tile_data(coords, alt)
					data.flip_h = alt % 2 == 1
					data.modulate = TONES[alt / 2]
	return tile_set
