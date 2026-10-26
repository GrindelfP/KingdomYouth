extends Node

signal resource_changed(id: StringName, new_amount: int)
signal storage_changed

var _storages: Array[Building] = []


func _ready() -> void:
	reset()


func reset() -> void:
	_storages.clear()
	for id in ResourceCatalog.all_ids():
		resource_changed.emit(id, 0)
	storage_changed.emit()


func register_storage(building: Building) -> void:
	if _storages.has(building):
		return
	_storages.append(building)
	building.storage.changed.connect(_on_inventory_changed)
	storage_changed.emit()
	for id in building.storage.ids():
		_on_inventory_changed(id)


func unregister_storage(building: Building) -> void:
	if not _storages.has(building):
		return
	_storages.erase(building)
	building.storage.changed.disconnect(_on_inventory_changed)
	storage_changed.emit()
	for id in ResourceCatalog.all_ids():
		if building.storage.get_amount(id) > 0:
			_on_inventory_changed(id)


func get_storages() -> Array[Building]:
	return _storages.duplicate()


func find_storages(id: StringName, from: Vector2i) -> Array[Building]:
	var result: Array[Building] = []
	for building in _storages:
		if building.def.accepts(id) and building.storage.free_space() > 0:
			result.append(building)
	result.sort_custom(func(a: Building, b: Building) -> bool:
		return _distance(a, from) < _distance(b, from))
	return result


func find_sources(id: StringName, from: Vector2i) -> Array[Building]:
	var result: Array[Building] = []
	for building in _storages:
		if building.storage.get_amount(id) > 0:
			result.append(building)
	result.sort_custom(func(a: Building, b: Building) -> bool:
		return _distance(a, from) < _distance(b, from))
	return result


func get_amount(id: StringName) -> int:
	var total := 0
	for building in _storages:
		total += building.storage.get_amount(id)
	return total


func get_capacity(category: int = -1) -> int:
	var total := 0
	for building in _storages:
		if category < 0 or building.def.storage_categories.is_empty() or building.def.storage_categories.has(category):
			total += building.def.storage_capacity
	return total


func get_stored_total() -> int:
	var total := 0
	for building in _storages:
		total += building.storage.total()
	return total


func get_free_space(id: StringName) -> int:
	var total := 0
	for building in _storages:
		if building.def.accepts(id):
			total += building.storage.free_space()
	return total


func add(id: StringName, amount: int) -> int:
	assert(amount >= 0)
	assert(ResourceCatalog.has(id))
	var left := amount
	for building in find_storages(id, WorldGrid.MAP_RECT.get_center()):
		left -= building.storage.add(id, left)
		if left <= 0:
			break
	return amount - left


func remove(id: StringName, amount: int) -> bool:
	assert(amount >= 0)
	if get_amount(id) < amount:
		return false
	var left := amount
	for building in _by_distance(WorldGrid.MAP_RECT.get_center()):
		left -= building.storage.take(id, left)
		if left <= 0:
			break
	return true


func can_afford(cost: Dictionary) -> bool:
	for id in cost:
		if get_amount(id) < cost[id]:
			return false
	return true


func spend(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	for id in cost:
		remove(id, cost[id])
	return true


func get_category_total(category: ResourceDef.Category) -> int:
	var total := 0
	for id in ResourceCatalog.ids_in_category(category):
		total += get_amount(id)
	return total


func get_food_total() -> int:
	return get_category_total(ResourceDef.Category.FOOD)


func remove_food(amount: int) -> bool:
	assert(amount >= 0)
	if get_food_total() < amount:
		return false
	var kinds := ResourceCatalog.ids_in_category(ResourceDef.Category.FOOD)
	for i in amount:
		var best: StringName = kinds[0]
		for id in kinds:
			if get_amount(id) > get_amount(best):
				best = id
		remove(best, 1)
	return true


func _by_distance(from: Vector2i) -> Array[Building]:
	var result := _storages.duplicate()
	result.sort_custom(func(a: Building, b: Building) -> bool:
		return _distance(a, from) < _distance(b, from))
	return result


func _distance(building: Building, from: Vector2i) -> int:
	var delta := building.get_center_cell() - from
	return absi(delta.x) + absi(delta.y)


func _on_inventory_changed(id: StringName) -> void:
	resource_changed.emit(id, get_amount(id))
