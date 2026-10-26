extends Node

signal month_changed(month: int)
signal season_changed(season: Season)
signal year_changed(year: int)
signal speed_changed(index: int)

enum Season { SPRING, SUMMER, AUTUMN, WINTER }

const SECONDS_PER_MONTH := 60.0
const MONTHS_PER_SEASON := 3
const MONTHS_PER_YEAR := 12
const MONTH_NAMES := [
	"Early Spring", "Mid Spring", "Late Spring",
	"Early Summer", "Mid Summer", "Late Summer",
	"Early Autumn", "Mid Autumn", "Late Autumn",
	"Early Winter", "Mid Winter", "Late Winter",
]
const SEASON_NAMES := ["Spring", "Summer", "Autumn", "Winter"]
const FOOD_MULTIPLIERS := [1.0, 1.5, 1.0, 0.0]
const SPEEDS := [0.0, 1.0, 2.0, 5.0]
const DEFAULT_SPEED_INDEX := 1

var month := 0
var _elapsed := 0.0
var _speed_index := DEFAULT_SPEED_INDEX
var _resume_index := DEFAULT_SPEED_INDEX


func _process(delta: float) -> void:
	advance(delta)


func advance(seconds: float) -> void:
	_elapsed += seconds
	while _elapsed >= SECONDS_PER_MONTH:
		_elapsed -= SECONDS_PER_MONTH
		_step_month()


func _step_month() -> void:
	var previous_season := get_season()
	var previous_year := get_year()
	month += 1
	month_changed.emit(month)
	if get_season() != previous_season:
		season_changed.emit(get_season())
	if get_year() != previous_year:
		year_changed.emit(get_year())


func reset() -> void:
	month = 0
	_elapsed = 0.0
	set_speed(DEFAULT_SPEED_INDEX)


func set_speed(index: int) -> void:
	_speed_index = clampi(index, 0, SPEEDS.size() - 1)
	if _speed_index > 0:
		_resume_index = _speed_index
	Engine.time_scale = SPEEDS[_speed_index]
	speed_changed.emit(_speed_index)


func toggle_pause() -> void:
	set_speed(_resume_index if _speed_index == 0 else 0)


func get_speed_index() -> int:
	return _speed_index


func get_month_in_year() -> int:
	return month % MONTHS_PER_YEAR


func get_month_name() -> String:
	return MONTH_NAMES[get_month_in_year()]


func get_season() -> Season:
	return (get_month_in_year() / MONTHS_PER_SEASON) as Season


func get_season_name() -> String:
	return SEASON_NAMES[get_season()]


func get_year() -> int:
	return month / MONTHS_PER_YEAR + 1


func get_month_progress() -> float:
	return _elapsed / SECONDS_PER_MONTH


func food_multiplier() -> float:
	return FOOD_MULTIPLIERS[get_season()]


func is_cold() -> bool:
	return get_season() == Season.WINTER


func to_save_data() -> Dictionary:
	return {"month": month, "elapsed": _elapsed}


func from_save_data(data: Dictionary) -> void:
	month = int(data["month"])
	_elapsed = float(data["elapsed"])
