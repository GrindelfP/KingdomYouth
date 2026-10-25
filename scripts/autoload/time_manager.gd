extends Node

signal day_changed(day: int)
signal season_changed(season: Season)

enum Season { SPRING, SUMMER, AUTUMN, WINTER }

const SECONDS_PER_DAY := 20.0
const DAYS_PER_SEASON := 10
const SEASON_NAMES := ["Spring", "Summer", "Autumn", "Winter"]
const FOOD_MULTIPLIERS := [1.0, 1.5, 1.0, 0.0]

var day := 1
var _elapsed := 0.0


func _process(delta: float) -> void:
	advance(delta)


func advance(seconds: float) -> void:
	_elapsed += seconds
	while _elapsed >= SECONDS_PER_DAY:
		_elapsed -= SECONDS_PER_DAY
		var previous_season := get_season()
		day += 1
		day_changed.emit(day)
		if get_season() != previous_season:
			season_changed.emit(get_season())


func reset() -> void:
	day = 1
	_elapsed = 0.0


func get_season() -> Season:
	return (((day - 1) / DAYS_PER_SEASON) % 4) as Season


func get_season_name() -> String:
	return SEASON_NAMES[get_season()]


func get_day_in_season() -> int:
	return (day - 1) % DAYS_PER_SEASON + 1


func get_time_of_day() -> float:
	return _elapsed / SECONDS_PER_DAY


func food_multiplier() -> float:
	return FOOD_MULTIPLIERS[get_season()]


func is_cold() -> bool:
	return get_season() == Season.WINTER


func to_save_data() -> Dictionary:
	return {"day": day, "elapsed": _elapsed}


func from_save_data(data: Dictionary) -> void:
	day = int(data["day"])
	_elapsed = float(data["elapsed"])
