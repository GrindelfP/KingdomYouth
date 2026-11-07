extends Node

signal shortage_started(kind: String)

const KEEP_SEASONS := 80
const FLOWS := ["produced", "consumed", "imported", "exported", "lost"]

@export var food_warning_threshold := 0
@export var fuel_warning_threshold := 0
@export var warning_interval := 1.0

var records: Array = []
var shortages: Dictionary = {"food": [], "fuel": []}
var tracking_started := 0.0
var _timer := 0.0


func _ready() -> void:
	TimeManager.season_changed.connect(func(_season: int) -> void: _ensure_current())
	reset()


func reset() -> void:
	records.clear()
	shortages = {"food": [], "fuel": []}
	tracking_started = TimeManager.get_time_months()
	_timer = 0.0
	_ensure_current()


func _process(delta: float) -> void:
	if delta <= 0.0:
		return
	_timer += delta
	if _timer < warning_interval:
		return
	_timer = 0.0
	var world := get_tree().get_first_node_in_group("world")
	if world != null:
		refresh_shortages(world.get_node("Buildings").get_buildings())


func record(flow: String, id: StringName, amount: int) -> void:
	assert(FLOWS.has(flow) and ResourceCatalog.has(id) and amount >= 0)
	if amount == 0:
		return
	_ensure_current()
	var goods: Dictionary = records.back()[flow]
	var key := String(id)
	goods[key] = int(goods.get(key, 0)) + amount


func current() -> Dictionary:
	_ensure_current()
	return records.back().duplicate(true)


func refresh_shortages(buildings: Array) -> void:
	var next := {"food": [], "fuel": []}
	for building: Building in buildings:
		if building.household == null or building.residents.is_empty() or not building.is_alive():
			continue
		var at := [building.origin.x, building.origin.y]
		if building.food_stock() <= food_warning_threshold:
			next["food"].append(at)
		if TimeManager.is_cold() and building.firewood_stock() <= fuel_warning_threshold and not building.is_heated():
			next["fuel"].append(at)
	for kind in next:
		var started: bool = shortages[kind].is_empty() and not next[kind].is_empty()
		shortages[kind] = next[kind]
		if started:
			shortage_started.emit(kind)


func to_save_data() -> Dictionary:
	_ensure_current()
	return {"records": records.duplicate(true), "shortages": shortages.duplicate(true), "tracking_started": tracking_started}


func from_save_data(data: Dictionary) -> void:
	reset()
	if data.is_empty():
		return
	records = data.get("records", []).duplicate(true)
	shortages = data.get("shortages", {"food": [], "fuel": []}).duplicate(true)
	tracking_started = float(data.get("tracking_started", TimeManager.get_time_months()))
	_ensure_current()


func _ensure_current() -> void:
	var season_index := TimeManager.month / TimeManager.MONTHS_PER_SEASON
	if records.is_empty() or int(records.back()["season"]) != season_index:
		var entry := {"season": season_index}
		for flow in FLOWS:
			entry[flow] = {}
		records.append(entry)
	while not records.is_empty() and int(records.front()["season"]) <= season_index - KEEP_SEASONS:
		records.pop_front()
