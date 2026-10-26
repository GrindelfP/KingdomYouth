class_name ShoreMask
extends RefCounted

const N := 1
const E := 2
const S := 4
const W := 8
const NE := 1
const SE := 2
const SW := 4
const NW := 8

const CORNER_SIDES := {NE: N | E, SE: S | E, SW: S | W, NW: N | W}

static var _keys: Array[int] = []
static var _index: Dictionary = {}


static func key(sides: int, corners: int) -> int:
	var kept := 0
	for corner in CORNER_SIDES:
		if corners & corner and not (sides & CORNER_SIDES[corner]):
			kept |= corner
	return sides | (kept << 4)


static func sides_of(k: int) -> int:
	return k & 15


static func corners_of(k: int) -> int:
	return k >> 4


static func keys() -> Array[int]:
	_build()
	return _keys


static func index_of(k: int) -> int:
	_build()
	return _index[k]


static func _build() -> void:
	if not _keys.is_empty():
		return
	var seen := {}
	for sides in 16:
		for corners in 16:
			seen[key(sides, corners)] = true
	var all := seen.keys()
	all.sort()
	for k in all:
		_index[k] = _keys.size()
		_keys.append(k)
