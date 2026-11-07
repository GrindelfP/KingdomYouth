class_name TownInventory
extends RefCounted

const LOCATIONS := [&"storage", &"households", &"workplace", &"construction", &"transit"]


static func snapshot(buildings: Array, sites: Array, settlers: Array, extra_locations: Dictionary = {}) -> Dictionary:
	var result := {}
	for location in LOCATIONS:
		result[location] = {}
	var seen := []
	for building in buildings:
		_add_inventory(result, &"storage", building.storage, seen)
		_add_inventory(result, &"households", building.household, seen)
		_add_inventory(result, &"workplace", building.input, seen)
		_add_inventory(result, &"workplace", building.output, seen)
	for site in sites:
		_add_inventory(result, &"construction", site.delivered, seen)
	for settler in settlers:
		if settler.carried_amount > 0:
			_add_amount(result[&"transit"], settler.carried_id, settler.carried_amount)
	for location in extra_locations:
		assert(not LOCATIONS.has(location) and location != &"total")
		result[location] = {}
		for inventory in extra_locations[location]:
			_add_inventory(result, location, inventory, seen)
	var total := {}
	for location in result:
		for id in result[location]:
			_add_amount(total, id, result[location][id])
	result[&"total"] = total
	return result


static func amount(snapshot_data: Dictionary, location: StringName, ids: Array[StringName]) -> int:
	var sum := 0
	for id in ids:
		sum += int(snapshot_data.get(location, {}).get(id, 0))
	return sum


static func _add_inventory(result: Dictionary, location: StringName, inventory: Inventory, seen: Array) -> void:
	if inventory == null or seen.has(inventory):
		return
	seen.append(inventory)
	for id in inventory.ids():
		_add_amount(result[location], id, inventory.get_amount(id))


static func _add_amount(items: Dictionary, id: StringName, value: int) -> void:
	items[id] = int(items.get(id, 0)) + value
