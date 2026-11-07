extends Node

var failures := 0


func _ready() -> void:
	var store := Building.new()
	store.storage = Inventory.new(100)
	var home := Building.new()
	home.household = Inventory.new(7)
	var work := Building.new()
	work.input = Inventory.new(20)
	work.output = Inventory.new(20)
	var site := ConstructionSite.new()
	site.delivered = Inventory.new(20)
	var settler := Settler.new()
	var hauler := Hauler.new(settler)
	var buildings := [store, home, work]
	var sites := [site]
	var settlers := [settler]
	store.storage.add(&"berries", 20)
	store.storage.add(&"firewood", 10)
	home.household.add(&"berries", 2)
	work.input.add(&"firewood", 3)
	work.output.add(&"berries", 4)
	site.delivered.add(&"firewood", 2)
	settler.set_carried(&"berries", 1)
	var data := TownInventory.snapshot(buildings, sites, settlers)
	_check(data[&"storage"].get(&"berries") == 20 and data[&"storage"].get(&"firewood") == 10, "storage fixture")
	_check(data[&"households"].get(&"berries") == 2 and data[&"workplace"].get(&"berries") == 4 and data[&"workplace"].get(&"firewood") == 3, "home and work fixture")
	_check(data[&"construction"].get(&"firewood") == 2 and data[&"transit"].get(&"berries") == 1, "construction and transit fixture")
	_check(data[&"total"].get(&"berries") == 27 and data[&"total"].get(&"firewood") == 15, "independent totals")
	settler.set_carried(&"", 0)
	store.storage.add(&"berries", 1)
	site.reserve(&"berries", 5)
	hauler._take(store.get_instance_id(), store.storage, &"berries", 10, func(_n: int) -> void: pass)
	_check(TownInventory.snapshot(buildings, sites, settlers)[&"total"].get(&"berries") == 27, "pickup and reservation")
	hauler._put(home.get_instance_id(), home.household, func(_n: int) -> void: pass)
	_check(settler.carried_amount == 5 and TownInventory.snapshot(buildings, sites, settlers)[&"total"].get(&"berries") == 27, "partial delivery")
	hauler._put(work.get_instance_id(), work.input, func(_n: int) -> void: pass)
	_check(settler.carried_amount == 0 and TownInventory.snapshot(buildings, sites, settlers)[&"total"].get(&"berries") == 27, "work delivery")
	site.release(&"berries", 5)
	_check(TownInventory.snapshot(buildings, sites, settlers)[&"total"].get(&"berries") == 27, "claim cancellation")
	home.household.take(&"berries", 1)
	_check(TownInventory.snapshot(buildings, sites, settlers)[&"total"].get(&"berries") == 26, "consumption")
	var copy := Inventory.new(100)
	copy.from_save_data(store.storage.to_save_data())
	_check(copy.to_save_data() == store.storage.to_save_data(), "inventory serialization")
	var extra := Inventory.new(10)
	extra.add(&"firewood", 4)
	data = TownInventory.snapshot(buildings, sites, settlers, {&"market": [extra]})
	_check(data[&"market"].get(&"firewood") == 4 and data[&"total"].get(&"firewood") == 19, "separate future location")
	for node in [store, home, work, site, settler]:
		node.free()
	print("INVENTORY %s" % ("OK" if failures == 0 else "FAIL"))
	get_tree().quit(0 if failures == 0 else 1)


func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error("Inventory check failed: " + label)
