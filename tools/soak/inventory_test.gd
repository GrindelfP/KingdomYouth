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
	settler.set_carried(&"berries", 2)
	home.queue_free()
	hauler._put(home.get_instance_id(), home.household, func(_n: int) -> void: pass)
	_check(settler.carried_amount == 2, "failed delivery retains cargo")
	for node in [store, home, work, site, settler]:
		node.free()
	await _check_removals()
	print("INVENTORY %s" % ("OK" if failures == 0 else "FAIL"))
	get_tree().quit(0 if failures == 0 else 1)


func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error("Inventory check failed: " + label)


func _check_removals() -> void:
	var world: Node = load("res://scenes/world/world.tscn").instantiate()
	add_child(world)
	await get_tree().process_frame
	await get_tree().process_frame
	var build: BuildController = world.get_node("Buildings")
	var people: SettlerManager = world.get_node("Settlers")
	var def: BuildingDef = build.building_defs[build.find_def_index(&"house")]
	var site := build.add_construction_site(def, Vector2i(2, 2), 0.0)
	var moved := ResourceStockpile.get_storages()[0].storage.take(&"firewood", 3)
	site.delivered.add(&"firewood", moved)
	var before := TownInventory.snapshot(build.get_buildings(), build.get_sites(), people.living_settlers())
	build.cancel_site(site)
	var after := TownInventory.snapshot(build.get_buildings(), build.get_sites(), people.living_settlers())
	_check(after[&"total"].get(&"firewood", 0) == before[&"total"].get(&"firewood", 0), "site cancellation refund")
	var home := build.add_building(def, Vector2i(5, 5))
	moved = ResourceStockpile.get_storages()[0].storage.take(&"firewood", 3)
	home.household.add(&"firewood", moved)
	before = TownInventory.snapshot(build.get_buildings(), build.get_sites(), people.living_settlers())
	build.demolish_building(home)
	after = TownInventory.snapshot(build.get_buildings(), build.get_sites(), people.living_settlers())
	_check(after[&"total"].get(&"firewood", 0) == before[&"total"].get(&"firewood", 0), "demolition refund")
	var home2 := build.add_building(def, Vector2i(8, 8))
	home2.household.add(&"firewood", 2)
	var stored := ResourceStockpile.get_amount(&"firewood")
	ResourceStockpile.remove(&"firewood", stored)
	_check(not ResourceStockpile.remove(&"firewood", 1) and home2.household.get_amount(&"firewood") == 2, "household stock is not spendable")
	for storage in ResourceStockpile.get_storages():
		if storage.def.accepts(&"firewood"):
			storage.storage.add(&"firewood", storage.storage.free_space())
	var overflow_site := build.add_construction_site(def, Vector2i(11, 11), 0.0)
	overflow_site.delivered.add(&"firewood", 3)
	before = TownInventory.snapshot(build.get_buildings(), build.get_sites(), people.living_settlers())
	build.cancel_site(overflow_site)
	after = TownInventory.snapshot(build.get_buildings(), build.get_sites(), people.living_settlers())
	_check(int(before[&"total"].get(&"firewood", 0)) - int(after[&"total"].get(&"firewood", 0)) == 3, "full storage refund overflow loss")
	world.queue_free()
