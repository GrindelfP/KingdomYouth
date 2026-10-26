class_name AmbientLife
extends Node2D

const LEAF_TEXTURE: Texture2D = preload("res://assets/art/terrain/leaf.png")
const SNOW_TEXTURE: Texture2D = preload("res://assets/art/terrain/snow.png")
const PETAL_TEXTURE: Texture2D = preload("res://assets/art/terrain/petal.png")
const SPRING := 0
const AUTUMN := 2
const WINTER := 3
const MARGIN := 1.15

var _camera: Camera2D
var _leaves: CPUParticles2D
var _snow: CPUParticles2D
var _petals: CPUParticles2D


func _ready() -> void:
	z_index = 30
	var world := get_parent()
	_camera = world.get_node("Camera")
	_leaves = _make(LEAF_TEXTURE, 90, 9.0, Vector2(18.0, 22.0), 10.0, 16.0, 38.0)
	_snow = _make(SNOW_TEXTURE, 260, 7.0, Vector2(-6.0, 38.0), 14.0, 4.0, 4.0)
	_petals = _make(PETAL_TEXTURE, 40, 10.0, Vector2(14.0, 14.0), 8.0, 10.0, 24.0)
	var colors := Gradient.new()
	colors.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	colors.colors = PackedColorArray([Color(1.0, 1.0, 1.0), Color(1.0, 0.82, 0.62), Color(0.85, 0.6, 0.45)])
	_leaves.color_initial_ramp = colors
	var view: TerrainView = world.get_node("TerrainView")
	view.season_applied.connect(_on_season_applied)


func _process(_delta: float) -> void:
	var half := get_viewport_rect().size / (2.0 * _camera.zoom.x) * MARGIN
	global_position = _camera.get_screen_center_position()
	for particles in [_leaves, _snow, _petals]:
		particles.emission_rect_extents = half


func _make(texture: Texture2D, amount: int, lifetime: float, gravity: Vector2, velocity: float, sway: float, spin: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = texture
	p.amount = amount
	p.lifetime = lifetime
	p.preprocess = lifetime
	p.local_coords = false
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(700.0, 400.0)
	p.direction = Vector2(0.4, 1.0)
	p.spread = 35.0
	p.gravity = gravity
	p.initial_velocity_min = velocity * 0.5
	p.initial_velocity_max = velocity
	p.tangential_accel_min = -sway
	p.tangential_accel_max = sway
	p.angular_velocity_min = -spin
	p.angular_velocity_max = spin
	p.emitting = false
	add_child(p)
	return p


func _on_season_applied(season: int, _animate: bool) -> void:
	_leaves.emitting = season == AUTUMN
	_snow.emitting = season == WINTER
	_petals.emitting = season == SPRING
