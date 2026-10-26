class_name ResourceCatalog
extends RefCounted

const GOODS_DIR := "res://resources/goods"

static var _defs: Dictionary = {}
static var _ordered: Array[ResourceDef] = []


static func _ensure_loaded() -> void:
	if not _ordered.is_empty():
		return
	for file in DirAccess.get_files_at(GOODS_DIR):
		var name := file.trim_suffix(".remap")
		if not name.ends_with(".tres"):
			continue
		var def := load("%s/%s" % [GOODS_DIR, name]) as ResourceDef
		if def == null:
			continue
		_defs[def.id] = def
		_ordered.append(def)
	_ordered.sort_custom(func(a: ResourceDef, b: ResourceDef) -> bool: return a.sort_order < b.sort_order)


static func has(id: StringName) -> bool:
	_ensure_loaded()
	return _defs.has(id)


static func get_def(id: StringName) -> ResourceDef:
	_ensure_loaded()
	return _defs.get(id)


static func display_name(id: StringName) -> String:
	var def := get_def(id)
	return def.display_name if def else String(id)


static func all_ids() -> Array[StringName]:
	_ensure_loaded()
	var ids: Array[StringName] = []
	for def in _ordered:
		ids.append(def.id)
	return ids


static func ids_in_category(category: ResourceDef.Category) -> Array[StringName]:
	_ensure_loaded()
	var ids: Array[StringName] = []
	for def in _ordered:
		if def.category == category:
			ids.append(def.id)
	return ids
