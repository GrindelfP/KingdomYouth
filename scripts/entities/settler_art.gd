class_name SettlerArt
extends RefCounted

const SHEET: Texture2D = preload("res://assets/art/settlers/settlers.png")
const CELL := Vector2(16, 20)
const FRAMES := 14
const WORK_FRAME := 12
const HAIR_VARIANTS := 3
const STAGES := 3
const SPRITE_OFFSET := Vector2(-8, -13)
const HEAD_TOP: Array[float] = [-5.0, -9.0, -8.0]
const PROFESSIONS: Array[StringName] = [&"laborer", &"builder", &"farmer", &"forester", &"gatherer", &"hunter", &"fisher", &"quarryman", &"miner", &"woodcutter", &"blacksmith"]
const CARRY_DIR := "res://assets/art/settlers/carry_%s.png"

static var _carry_cache: Dictionary = {}


static func row(hair: int, stage: int, sex: int, profession: StringName) -> int:
	var index := maxi(PROFESSIONS.find(profession), 0)
	return ((hair % HAIR_VARIANTS * STAGES + stage) * 2 + sex) * PROFESSIONS.size() + index


static func frame_rect(sheet_row: int, frame: int) -> Rect2:
	return Rect2(frame * CELL.x, sheet_row * CELL.y, CELL.x, CELL.y)


static func carry_texture(id: StringName) -> Texture2D:
	if not _carry_cache.has(id):
		var path := CARRY_DIR % id
		_carry_cache[id] = load(path) if ResourceLoader.exists(path) else null
	return _carry_cache[id]
