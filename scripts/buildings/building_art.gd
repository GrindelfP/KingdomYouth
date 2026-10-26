class_name BuildingArt
extends RefCounted

const DIR := "res://assets/art/buildings/"
const PAD_X := 8
const PAD_BOTTOM := 6
const FENCE_TOP := 12
const FENCE_MARGIN := 8
const SITE_EXTRA := 14
const TILE := 32
const FIELD_TEXTURE: Texture2D = preload("res://assets/art/buildings/field_tiles.png")
const PILE_TEXTURE: Texture2D = preload("res://assets/art/buildings/piles.png")
const SMOKE_TEXTURE: Texture2D = preload("res://assets/art/buildings/smoke.png")
const GLOW_TEXTURE: Texture2D = preload("res://assets/art/buildings/glow.png")
const PILE_SIZE := Vector2i(40, 32)
const PILE_BASE := Vector2(20.0, 29.0)
const PILE_GOODS: Array[StringName] = [&"logs", &"stone", &"firewood", &"iron", &"tools"]
const PILE_STAGES := 4
const PILE_THRESHOLDS: Array[int] = [1, 20, 60, 140]
const PILE_SLOTS := {
	&"logs": Vector2(-38.0, -76.0),
	&"stone": Vector2(0.0, -76.0),
	&"firewood": Vector2(38.0, -76.0),
	&"iron": Vector2(-24.0, -30.0),
	&"tools": Vector2(24.0, -30.0),
}
const SMOKE_POINTS := {&"house": Vector2(57.0, 12.0), &"blacksmith": Vector2(20.0, 8.0)}
const GLOW_POINTS := {&"blacksmith": Vector2(28.0, 75.0)}
const FIELD_EMPTY := 0
const FIELD_PLOWED := 2
const FIELD_PLANTED := 4
const FIELD_GROWING_WHEAT := 5
const FIELD_GROWING_CABBAGE := 7
const FIELD_RIPE_WHEAT := 9
const FIELD_RIPE_CABBAGE := 11
const FIELD_HARVESTED := 13

static var _cache: Dictionary = {}


static func texture(def: BuildingDef, winter: bool) -> Texture2D:
	var path := "%s%s%s.png" % [DIR, def.id, "_winter" if winter else ""]
	if not _cache.has(path):
		_cache[path] = load(path)
	return _cache[path]


static func sprite_offset(tex: Texture2D) -> Vector2:
	return Vector2(-tex.get_width() / 2.0, -float(tex.get_height() - PAD_BOTTOM))


static func site_texture(def: BuildingDef, stage: int) -> AtlasTexture:
	var n := def.footprint.x
	if def.is_field():
		return _region("fence_%d" % n, stage, n * TILE + FENCE_MARGIN * 2, n * TILE + FENCE_TOP + FENCE_MARGIN)
	var size := clampi(n, 2, 4)
	return _region("site_%d" % size, stage, size * TILE + PAD_X * 2, size * TILE + SITE_EXTRA + PAD_BOTTOM)


static func site_offset(def: BuildingDef) -> Vector2:
	var n := def.footprint.x
	if def.is_field():
		return fence_offset(n)
	var size := clampi(n, 2, 4)
	return Vector2(-(size * TILE + PAD_X * 2) / 2.0, -float(size * TILE + SITE_EXTRA))


static func fence_texture(n: int) -> AtlasTexture:
	return _region("fence_%d" % n, 3, n * TILE + FENCE_MARGIN * 2, n * TILE + FENCE_TOP + FENCE_MARGIN)


static func fence_offset(n: int) -> Vector2:
	return Vector2(-(n * TILE + FENCE_MARGIN * 2) / 2.0, -float(n * TILE + FENCE_TOP))


static func field_region(column: int, winter: bool) -> Rect2:
	return Rect2(column * TILE, (1 if winter else 0) * TILE, TILE, TILE)


static func field_column(state: int, crop: StringName, growth: float, cell: Vector2i) -> int:
	var variant := (cell.x * 7 + cell.y * 13 + cell.x * cell.y) % 2
	var cabbage := crop == &"cabbage"
	match state:
		CropField.CellState.PLOWED:
			return FIELD_PLOWED + variant
		CropField.CellState.PLANTED:
			return FIELD_PLANTED
		CropField.CellState.GROWING:
			return (FIELD_GROWING_CABBAGE if cabbage else FIELD_GROWING_WHEAT) + (1 if growth >= 0.6 else 0)
		CropField.CellState.RIPE:
			return (FIELD_RIPE_CABBAGE if cabbage else FIELD_RIPE_WHEAT) + variant
		CropField.CellState.HARVESTED:
			return FIELD_HARVESTED + variant
	return FIELD_EMPTY + variant


static func pile_texture(good: StringName, stage: int, winter: bool) -> AtlasTexture:
	var key := "pile_%s_%d_%d" % [good, stage, int(winter)]
	if not _cache.has(key):
		var atlas := AtlasTexture.new()
		atlas.atlas = PILE_TEXTURE
		var column := PILE_GOODS.find(good) * PILE_STAGES + stage - 1
		atlas.region = Rect2(column * PILE_SIZE.x, (1 if winter else 0) * PILE_SIZE.y, PILE_SIZE.x, PILE_SIZE.y)
		_cache[key] = atlas
	return _cache[key]


static func pile_stage(amount: int) -> int:
	var stage := 0
	for index in PILE_THRESHOLDS.size():
		if amount >= PILE_THRESHOLDS[index]:
			stage = index + 1
	return stage


static func sprite_point_to_local(point: Vector2, tex: Texture2D) -> Vector2:
	return point + sprite_offset(tex)


static func _region(file: String, column: int, width: int, height: int) -> AtlasTexture:
	var key := "%s_%d" % [file, column]
	if not _cache.has(key):
		var atlas := AtlasTexture.new()
		atlas.atlas = load("%s%s.png" % [DIR, file])
		atlas.region = Rect2(column * width, 0, width, height)
		_cache[key] = atlas
	return _cache[key]
