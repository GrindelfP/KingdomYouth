class_name CameraController
extends Camera2D

@onready var world_grid: WorldGrid = get_parent()
@export var pan_speed := 600.0
@export var min_zoom := 0.5
@export var max_zoom := 3.0
@export var zoom_factor := 1.15
@export var zoom_smoothing := 12.0

var _target_zoom := 1.0
var _dragging := false
var _bounds: Rect2


func _ready() -> void:
	_target_zoom = clampf(zoom.x, min_zoom, max_zoom)
	zoom = Vector2.ONE * _target_zoom
	_bounds = world_grid.get_world_bounds()
	position = _bounds.get_center()


func _process(delta: float) -> void:
	var direction := Input.get_vector("camera_pan_left", "camera_pan_right", "camera_pan_up", "camera_pan_down")
	position += direction * pan_speed * delta / zoom.x

	var blend := 1.0 - exp(-zoom_smoothing * delta)
	zoom = Vector2.ONE * lerpf(zoom.x, _target_zoom, blend)
	_clamp_to_bounds()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("camera_zoom_in"):
		_target_zoom = clampf(_target_zoom * zoom_factor, min_zoom, max_zoom)
	elif event.is_action_pressed("camera_zoom_out"):
		_target_zoom = clampf(_target_zoom / zoom_factor, min_zoom, max_zoom)
	elif event.is_action_pressed("camera_drag"):
		_dragging = true
	elif event.is_action_released("camera_drag"):
		_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		position -= event.relative / zoom.x
		_clamp_to_bounds()


func get_hovered_grid_pos() -> Vector2i:
	return world_grid.world_to_grid(get_global_mouse_position())


func _clamp_to_bounds() -> void:
	var half_view := get_viewport_rect().size / (2.0 * zoom.x)
	position = Vector2(
		_clamp_axis(position.x, _bounds.position.x + half_view.x, _bounds.end.x - half_view.x, _bounds.get_center().x),
		_clamp_axis(position.y, _bounds.position.y + half_view.y, _bounds.end.y - half_view.y, _bounds.get_center().y),
	)


func _clamp_axis(value: float, low: float, high: float, center: float) -> float:
	if low > high:
		return center
	return clampf(value, low, high)
