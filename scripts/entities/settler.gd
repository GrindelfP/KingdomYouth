class_name Settler
extends Node2D

signal arrived(grid_pos: Vector2i)
signal path_failed(grid_pos: Vector2i)

const SPEED_TILES_PER_SECOND := 3.0
const RADIUS := 6.0
const COLOR := Color(0.95, 0.85, 0.6)

var _world: WorldGrid
var _pathfinder: GridPathfinder
var _last_cell := Vector2i.ZERO
var _destination := Vector2i.ZERO
var _path: Array[Vector2i] = []
var _moving := false
var needs: Needs


func _ready() -> void:
	needs = Needs.new()
	add_child(needs)


func setup(world: WorldGrid, pathfinder: GridPathfinder, grid_pos: Vector2i) -> void:
	_world = world
	_pathfinder = pathfinder
	_last_cell = grid_pos
	global_position = world.grid_to_world(grid_pos)


func get_grid_pos() -> Vector2i:
	return _last_cell


func is_moving() -> bool:
	return _moving


func move_to(grid_pos: Vector2i) -> bool:
	_destination = grid_pos
	_moving = true
	return _replan()


func _process(delta: float) -> void:
	if not _moving:
		return
	if not _world.is_walkable(_path[0]):
		_replan()
		return
	var target := _world.grid_to_world(_path[0])
	global_position = global_position.move_toward(target, SPEED_TILES_PER_SECOND * _world.get_tile_size().x * delta)
	if global_position == target:
		_last_cell = _path.pop_front()
		if _path.is_empty():
			_arrive()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, COLOR)


func _replan() -> bool:
	var path := _pathfinder.find_path(_last_cell, _destination)
	if path.is_empty():
		_moving = false
		_path.clear()
		path_failed.emit(_destination)
		return false
	path.pop_front()
	_path = path
	if _path.is_empty():
		_arrive()
	return true


func _arrive() -> void:
	_moving = false
	arrived.emit(_destination)
