extends Node

signal resource_changed(id: StringName, new_amount: int)

var _amounts: Dictionary = {}


func _ready() -> void:
	reset()


func reset() -> void:
	_amounts.clear()
	for id in ResourceCatalog.all_ids():
		_amounts[id] = ResourceCatalog.get_def(id).starting_amount
		resource_changed.emit(id, _amounts[id])


func to_save_data() -> Dictionary:
	var data := {}
	for id in _amounts:
		data[String(id)] = _amounts[id]
	return data


func from_save_data(data: Dictionary) -> void:
	for id in ResourceCatalog.all_ids():
		_set_amount(id, int(data.get(String(id), 0)))


func get_amount(id: StringName) -> int:
	return _amounts.get(id, 0)


func add(id: StringName, amount: int) -> void:
	assert(amount >= 0)
	assert(ResourceCatalog.has(id))
	_set_amount(id, get_amount(id) + amount)


func remove(id: StringName, amount: int) -> bool:
	assert(amount >= 0)
	if get_amount(id) < amount:
		return false
	_set_amount(id, get_amount(id) - amount)
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


func _set_amount(id: StringName, new_amount: int) -> void:
	_amounts[id] = new_amount
	resource_changed.emit(id, new_amount)
