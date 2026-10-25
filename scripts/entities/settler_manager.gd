class_name SettlerManager
extends Node2D

const STARTING_SETTLER_COUNT := 5

var _world: WorldGrid
var _pathfinder: GridPathfinder


func _ready() -> void:
	_world = get_parent()
	_pathfinder = get_parent().get_node("Pathfinder")
	_world.map_generated.connect(_spawn_starting_settlers)


func _spawn_starting_settlers() -> void:
	var bounds := _world.get_map_bounds()
	var center := bounds.get_center()
	var cells: Array[Vector2i] = []
	for x in range(bounds.position.x, bounds.end.x):
		for y in range(bounds.position.y, bounds.end.y):
			var grid_pos := Vector2i(x, y)
			if _world.is_walkable(grid_pos):
				cells.append(grid_pos)
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.distance_squared_to(center) < b.distance_squared_to(center))
	for i in mini(STARTING_SETTLER_COUNT, cells.size()):
		var settler := Settler.new()
		add_child(settler)
		settler.setup(_world, _pathfinder, cells[i])
