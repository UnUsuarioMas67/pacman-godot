extends Node

var current_level: Level
var ghost_manager: GhostManager
var debug_mode: bool = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		debug_mode = !debug_mode
