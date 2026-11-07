extends Node

var failures := 0


func _ready() -> void:
	TimeManager.set_process(false)
	TimeManager.reset()
	EconomyHistory.set_process(false)
	EconomyHistory.reset()
	var source := Inventory.new(20)
	var destination := Inventory.new(20)
	source.produce(&"berries", 12)
	destination.add(&"berries", source.take(&"berries", 5))
	var needs := Needs.new()
	needs.eat_from(destination)
	_check(_amount("produced", "berries") == 12, "creation recorded once")
	_check(_amount("consumed", "berries") == 1, "meal recorded by good")
	_check(_amount("lost", "berries") == 0, "transfer is not loss")
	_check(destination.total() + source.total() == 11, "transfer conservation")
	source.produce(&"berries", 20)
	_check(_amount("produced", "berries") == 32 and _amount("lost", "berries") == 7, "production overflow explicit")
	EconomyHistory.record("imported", &"logs", 3)
	EconomyHistory.record("exported", &"stone", 2)
	_check(_amount("imported", "logs") == 3 and _amount("exported", "stone") == 2, "trade hooks")
	TimeManager.advance(180.0)
	destination.consume(&"berries", 2)
	_check(EconomyHistory.records.size() == 2 and _amount("consumed", "berries") == 2, "season separation")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(EconomyHistory.to_save_data()))
	EconomyHistory.reset()
	EconomyHistory.from_save_data(saved)
	_check(JSON.stringify(EconomyHistory.to_save_data()) == JSON.stringify(saved), "history JSON round-trip")
	TimeManager.advance(81 * 180.0)
	_check(EconomyHistory.records.size() == 80, "20-year rolling window includes current season")
	needs.free()
	print("ECONOMY %s" % ("OK" if failures == 0 else "FAIL"))
	get_tree().quit(0 if failures == 0 else 1)


func _amount(flow: String, id: String) -> int:
	return int(EconomyHistory.current()[flow].get(id, 0))


func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error("Economy check failed: " + label)
