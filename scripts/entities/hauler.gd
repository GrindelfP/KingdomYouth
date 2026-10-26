class_name Hauler
extends RefCounted

const NO_TARGET := Vector2i(-1, -1)
const CARRY_SIZE := 10

var _settler: Settler
var _target := NO_TARGET
var _on_arrived := Callable()


func _init(settler: Settler) -> void:
	_settler = settler


func is_walking() -> bool:
	return _target != NO_TARGET


func cancel() -> void:
	_target = NO_TARGET
	_on_arrived = Callable()
	_settler.cancel_movement()


func walk_to(target: Structure, on_arrived: Callable) -> bool:
	var cell := reachable_access_cell(target)
	if cell == NO_TARGET:
		return false
	_target = cell
	_on_arrived = on_arrived
	_settler.move_to(cell)
	return true


func fetch(source: Structure, inventory: Inventory, id: StringName, amount: int, done: Callable) -> bool:
	return walk_to(source, _take.bind(source.get_instance_id(), inventory, id, mini(amount, CARRY_SIZE), done))


func deliver(sink: Structure, inventory: Inventory, done: Callable) -> bool:
	return walk_to(sink, _put.bind(sink.get_instance_id(), inventory, done))


func deliver_to_storage(done: Callable) -> bool:
	for storage in ResourceStockpile.find_storages(_settler.carried_id, _settler.get_grid_pos()):
		if deliver(storage, storage.storage, _after_storage_deposit.bind(done)):
			return true
	return false


func handle_arrived(grid_pos: Vector2i) -> bool:
	if _target == NO_TARGET or grid_pos != _target:
		return false
	var callback := _on_arrived
	_target = NO_TARGET
	_on_arrived = Callable()
	callback.call()
	return true


func handle_failed(grid_pos: Vector2i) -> bool:
	if _target == NO_TARGET or grid_pos != _target:
		return false
	_target = NO_TARGET
	_on_arrived = Callable()
	return true


func reachable_access_cell(target: Structure) -> Vector2i:
	var from := _settler.get_grid_pos()
	var cells := target.get_access_cells()
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.distance_squared_to(from) < b.distance_squared_to(from))
	for cell in cells:
		if is_reachable(cell):
			return cell
	return NO_TARGET


func is_reachable(to: Vector2i) -> bool:
	return not _settler.pathfinder.find_path(_settler.get_grid_pos(), to).is_empty()


func _take(source_id: int, inventory: Inventory, id: StringName, amount: int, done: Callable) -> void:
	var taken := 0
	if _is_alive(source_id):
		taken = inventory.take(id, amount)
	_settler.set_carried(id, taken)
	done.call(taken)


func _put(sink_id: int, inventory: Inventory, done: Callable) -> void:
	var accepted := 0
	if _is_alive(sink_id):
		accepted = inventory.add(_settler.carried_id, _settler.carried_amount)
		_settler.set_carried(_settler.carried_id, _settler.carried_amount - accepted)
	done.call(accepted)


func _is_alive(instance_id: int) -> bool:
	var target := instance_from_id(instance_id) as Structure
	return target != null and target.is_alive()


func _after_storage_deposit(_accepted: int, done: Callable) -> void:
	if _settler.is_carrying() and deliver_to_storage(done):
		return
	done.call()
