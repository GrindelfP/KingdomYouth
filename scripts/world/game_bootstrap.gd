class_name GameBootstrap
extends Node


func _ready() -> void:
	_start.call_deferred()


func _start() -> void:
	if SaveManager.pending_load:
		SaveManager.pending_load = false
		SaveManager.load_game()
		return
	var buildings: BuildController = get_parent().get_node("Buildings")
	var settlers: SettlerManager = get_parent().get_node("Settlers")
	var occupied: Array[Vector2i] = []
	for settler in settlers.living_settlers():
		occupied.append(settler.get_grid_pos())
	buildings.place_starting_storage(occupied)
	for id in ResourceCatalog.all_ids():
		ResourceStockpile.add(id, ResourceCatalog.get_def(id).starting_amount)
