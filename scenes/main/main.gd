extends Node2D

const LEVEL_SCENE: PackedScene = preload("res://scenes/level/level.tscn")

@onready var level: Level = $Level


func _ready():
	GameEvents.level_completed.connect(
		func():
			await get_tree().create_timer(0.5).timeout
			reload_level()
	)
	
	_initialize_level(level)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_game"):
		get_tree().reload_current_scene()


func reload_level() -> void:
	remove_child(level)
	level.queue_free()
	
	var new_level = LEVEL_SCENE.instantiate()
	add_child(new_level)
	
	_initialize_level(new_level)


func _initialize_level(new_level: Level):
	new_level.play_intro()
	new_level.stopped.connect(func():
		level.play_intro()
	)
	
