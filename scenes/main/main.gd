extends Node2D

const LEVEL_SCENE: PackedScene = preload("res://scenes/level/level.tscn")

var current_level: int = 1

@onready var level: Level = $Level
@onready var lives_manager: LivesManager = $LivesManager


func _ready():
	GameEvents.level_completed.connect(
		func():
			await get_tree().create_timer(0.5).timeout
			current_level += 1
			GameEvents.level_changed.emit(current_level)
			reload_level()
	)
	
	GameEvents.level_changed.emit(current_level)
	_initialize_level(level)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_game"):
		get_tree().reload_current_scene()


func reload_level() -> void:
	remove_child(level)
	level.queue_free()
	
	level = LEVEL_SCENE.instantiate()
	add_child(level)
	_initialize_level(level)


func _initialize_level(new_level: Level):
	new_level.play_intro()
	new_level.stopped.connect(func():
		if lives_manager.lives > 0:
			new_level.play_intro()
		else:
			get_tree().reload_current_scene()
	)
	
