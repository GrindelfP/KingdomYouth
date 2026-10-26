class_name Inventory
extends RefCounted

signal changed(id: StringName)

var capacity := 0
var _items: Dictionary = {}


func _init(max_capacity: int = 0) -> void:
	capacity = max_capacity


func get_amount(id: StringName) -> int:
	return _items.get(id, 0)


func total() -> int:
	var sum := 0
	for id in _items:
		sum += _items[id]
	return sum


func free_space() -> int:
	return maxi(capacity - total(), 0)


func is_empty() -> bool:
	return total() == 0


func ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for id in ResourceCatalog.all_ids():
		if get_amount(id) > 0:
			result.append(id)
	return result


func add(id: StringName, amount: int) -> int:
	var accepted := mini(amount, free_space())
	if accepted <= 0:
		return 0
	_items[id] = get_amount(id) + accepted
	changed.emit(id)
	return accepted


func take(id: StringName, amount: int) -> int:
	var taken := mini(amount, get_amount(id))
	if taken <= 0:
		return 0
	_items[id] = get_amount(id) - taken
	if _items[id] == 0:
		_items.erase(id)
	changed.emit(id)
	return taken


func category_total(category: ResourceDef.Category) -> int:
	var sum := 0
	for id in ResourceCatalog.ids_in_category(category):
		sum += get_amount(id)
	return sum


func kind_count(category: ResourceDef.Category) -> int:
	var count := 0
	for id in ResourceCatalog.ids_in_category(category):
		if get_amount(id) > 0:
			count += 1
	return count


func take_best(category: ResourceDef.Category, amount: int) -> int:
	var taken := 0
	while taken < amount:
		var best := &""
		for id in ResourceCatalog.ids_in_category(category):
			if get_amount(id) > 0 and (best == &"" or get_amount(id) > get_amount(best)):
				best = id
		if best == &"":
			break
		taken += take(best, 1)
	return taken


func to_save_data() -> Dictionary:
	var data := {}
	for id in _items:
		data[String(id)] = _items[id]
	return data


func from_save_data(data: Dictionary) -> void:
	var previous := _items.keys()
	_items.clear()
	for key in data:
		var id := StringName(key)
		if ResourceCatalog.has(id):
			_items[id] = int(data[key])
	for id in previous:
		changed.emit(id)
	for id in _items:
		changed.emit(id)
