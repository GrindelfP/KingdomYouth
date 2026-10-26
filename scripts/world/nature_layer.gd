class_name NatureLayer
extends Node2D

const TREE_TEXTURE: Texture2D = preload("res://assets/art/terrain/trees.png")
const ROCK_TEXTURE: Texture2D = preload("res://assets/art/terrain/rocks.png")
const TREE_SIZE := Vector2i(32, 48)
const ROCK_SIZE := Vector2i(32, 32)
const TREE_BASE := Vector2(16.0, 44.0)
const ROCK_BASE := Vector2(16.0, 27.0)
const STAGES := 3
const TREE_VARIANTS := 3
const ROCK_VARIANTS := 3
const FADE_SECONDS := 3.0
const BOULDER_CHANCE := 62
const CELL_BASE_OFFSET := 15.0
const CLUSTER_FREQUENCY := 0.09

var _world: WorldGrid
var _season := 0
var _trees: Dictionary = {}
var _rocks: Dictionary = {}
var _tree_textures: Array = []
var _rock_textures: Array = []
var _ghosts: Array[Sprite2D] = []
var _tween: Tween
var _cluster := FastNoiseLite.new()


func _ready() -> void:
	y_sort_enabled = true
	_world = get_parent()
	_cluster.seed = WorldGrid.MAP_SEED + 7
	_cluster.frequency = CLUSTER_FREQUENCY
	_build_textures()
	_world.map_generated.connect(_rebuild)
	_world.trees_reloaded.connect(_rebuild)
	_world.trees_changed.connect(_on_tree_changed)
	var view: TerrainView = _world.get_node("TerrainView")
	view.season_applied.connect(_on_season_applied)


func get_tree_sprite(grid_pos: Vector2i) -> Sprite2D:
	return _trees.get(grid_pos)


func _build_textures() -> void:
	for season in 4:
		var trees := []
		for variant in TREE_VARIANTS:
			for stage in STAGES:
				trees.append(_region(TREE_TEXTURE, Vector2i((variant * STAGES + stage) * TREE_SIZE.x, season * TREE_SIZE.y), TREE_SIZE))
		_tree_textures.append(trees)
		var rocks := []
		for variant in ROCK_VARIANTS:
			rocks.append(_region(ROCK_TEXTURE, Vector2i(variant * ROCK_SIZE.x, season * ROCK_SIZE.y), ROCK_SIZE))
		_rock_textures.append(rocks)


func _region(texture: Texture2D, origin: Vector2i, size: Vector2i) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(origin, size)
	return atlas


func _rebuild() -> void:
	_finish_fade()
	for sprite in _trees.values():
		sprite.queue_free()
	for sprite in _rocks.values():
		sprite.queue_free()
	_trees.clear()
	_rocks.clear()
	var bounds := _world.get_map_bounds()
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			var cell := Vector2i(x, y)
			if _world.get_terrain_name(cell) == "rock" and _hash(cell, 4) % 100 < BOULDER_CHANCE:
				_rocks[cell] = _make_sprite(cell, _rock_textures[_season][_hash(cell, 3) % ROCK_VARIANTS], ROCK_BASE, 1)
	for cell in _world.get_tree_cells():
		_set_tree(cell)


func _on_tree_changed(cell: Vector2i) -> void:
	_set_tree(cell)


func _set_tree(cell: Vector2i) -> void:
	var stage := _world.get_tree_stage(cell)
	if stage == WorldGrid.NO_TREE:
		if _trees.has(cell):
			_trees[cell].queue_free()
			_trees.erase(cell)
		return
	var texture: Texture2D = _tree_textures[_season][_variant_of(cell) * STAGES + stage]
	if _trees.has(cell):
		_trees[cell].texture = texture
	else:
		_trees[cell] = _make_sprite(cell, texture, TREE_BASE, 0)


func _make_sprite(cell: Vector2i, texture: Texture2D, base: Vector2, salt: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.offset = -base
	sprite.texture = texture
	var jitter := Vector2(float(_hash(cell, 11 + salt) % 11) - 5.0, -float(_hash(cell, 17 + salt) % 5))
	if salt == 1:
		jitter = Vector2.ZERO
	sprite.position = _world.grid_to_world(cell) + Vector2(0.0, CELL_BASE_OFFSET) + jitter
	add_child(sprite)
	return sprite


func _variant_of(cell: Vector2i) -> int:
	var noise := _cluster.get_noise_2d(cell.x, cell.y)
	var roll := _hash(cell, 5) % 100
	if noise < -0.12:
		return 2 if roll < 85 else roll % 2
	if noise > 0.18:
		return 1 if roll < 55 else (0 if roll < 90 else 2)
	return 0 if roll < 60 else (1 if roll < 80 else 2)


func _on_season_applied(season: int, animate: bool) -> void:
	var previous := _season
	_season = season
	_finish_fade()
	if animate:
		for sprite in _trees.values():
			_add_ghost(sprite)
		for sprite in _rocks.values():
			_add_ghost(sprite)
	for cell in _trees:
		var sprite: Sprite2D = _trees[cell]
		sprite.texture = _tree_textures[season][_variant_of(cell) * STAGES + _world.get_tree_stage(cell)]
	for cell in _rocks:
		var sprite: Sprite2D = _rocks[cell]
		sprite.texture = _rock_textures[season][_hash(cell, 3) % ROCK_VARIANTS]
	if animate and previous != season and not _ghosts.is_empty():
		_tween = create_tween()
		_tween.tween_method(_set_ghost_alpha, 1.0, 0.0, FADE_SECONDS)
		_tween.finished.connect(_finish_fade)


func _add_ghost(sprite: Sprite2D) -> void:
	var ghost := Sprite2D.new()
	ghost.centered = false
	ghost.offset = sprite.offset
	ghost.texture = sprite.texture
	sprite.add_child(ghost)
	_ghosts.append(ghost)


func _set_ghost_alpha(alpha: float) -> void:
	for ghost in _ghosts:
		ghost.modulate.a = alpha


func _finish_fade() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	for ghost in _ghosts:
		if is_instance_valid(ghost):
			ghost.queue_free()
	_ghosts.clear()


static func _hash(cell: Vector2i, salt: int) -> int:
	var h := (cell.x * 374761393 + cell.y * 668265263 + salt * 1274126177 + WorldGrid.MAP_SEED) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1103515245) & 0x7fffffff
	return h ^ (h >> 16)
