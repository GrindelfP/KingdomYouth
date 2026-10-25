class_name GameBootstrap
extends Node


func _ready() -> void:
	_start.call_deferred()


func _start() -> void:
	if SaveManager.pending_load:
		SaveManager.pending_load = false
		SaveManager.load_game()
