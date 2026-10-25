extends CanvasModulate

const NIGHT_COLOR := Color(0.35, 0.38, 0.6)
const DAY_COLOR := Color.WHITE


func _process(_delta: float) -> void:
	var daylight := (sin(TAU * (TimeManager.get_time_of_day() + 0.25)) + 1.0) * 0.5
	color = NIGHT_COLOR.lerp(DAY_COLOR, daylight)
