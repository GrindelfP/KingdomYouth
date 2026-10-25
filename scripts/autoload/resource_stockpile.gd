extends Node

signal resource_changed(type: Type, new_amount: int)

enum Type { WOOD, FOOD, STONE }

const STARTING_AMOUNTS := {
	Type.WOOD: 50,
	Type.FOOD: 20,
	Type.STONE: 0,
}

var _amounts: Dictionary = {}


func _ready() -> void:
	for type in Type.values():
		_amounts[type] = STARTING_AMOUNTS.get(type, 0)


func get_amount(type: Type) -> int:
	return _amounts[type]


func add(type: Type, amount: int) -> void:
	assert(amount >= 0)
	_set_amount(type, get_amount(type) + amount)


func remove(type: Type, amount: int) -> bool:
	assert(amount >= 0)
	if get_amount(type) < amount:
		return false
	_set_amount(type, get_amount(type) - amount)
	return true


func can_afford(cost: Dictionary) -> bool:
	for type in cost:
		if get_amount(type) < cost[type]:
			return false
	return true


func spend(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	for type in cost:
		remove(type, cost[type])
	return true


func _set_amount(type: Type, new_amount: int) -> void:
	_amounts[type] = new_amount
	resource_changed.emit(type, new_amount)
