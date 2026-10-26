class_name GridPathfinder
extends Node

var _world: WorldGrid
var _astar := AStar2D.new()


func _ready() -> void:
	_world = get_parent()
	_world.map_generated.connect(_build)
	_world.walkability_changed.connect(_on_walkability_changed)
	_world.roads_changed.connect(_on_roads_changed)


func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	if not (_world.is_in_bounds(from) and _world.is_in_bounds(to)):
		return path
	for point in _astar.get_point_path(_id(from), _id(to)):
		path.append(Vector2i(point))
	return path


func _build() -> void:
	_astar.clear()
	var bounds := _world.get_map_bounds()
	for x in range(bounds.position.x, bounds.end.x):
		for y in range(bounds.position.y, bounds.end.y):
			var cell := Vector2i(x, y)
			_astar.add_point(_id(cell), Vector2(cell))
			_astar.set_point_disabled(_id(cell), not _world.is_walkable(cell))
			_astar.set_point_weight_scale(_id(cell), _weight_for(cell))
	for x in range(bounds.position.x, bounds.end.x):
		for y in range(bounds.position.y, bounds.end.y):
			var cell := Vector2i(x, y)
			if x + 1 < bounds.end.x:
				_astar.connect_points(_id(cell), _id(cell + Vector2i.RIGHT))
			if y + 1 < bounds.end.y:
				_astar.connect_points(_id(cell), _id(cell + Vector2i.DOWN))


func _on_walkability_changed(grid_pos: Vector2i) -> void:
	if _world.is_in_bounds(grid_pos):
		_astar.set_point_disabled(_id(grid_pos), not _world.is_walkable(grid_pos))


func _on_roads_changed(grid_pos: Vector2i) -> void:
	if _world.is_in_bounds(grid_pos):
		_astar.set_point_weight_scale(_id(grid_pos), _weight_for(grid_pos))


func _weight_for(grid_pos: Vector2i) -> float:
	return 1.0 / _world.get_speed_multiplier(grid_pos)


func _id(grid_pos: Vector2i) -> int:
	return grid_pos.x + grid_pos.y * _world.get_map_bounds().size.x
