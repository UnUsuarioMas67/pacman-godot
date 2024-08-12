extends Node2D

@onready var level: Level = $Level


func _ready():
	GameEvents.level_completed.connect(
		func():
			await get_tree().create_timer(0.5).timeout
			get_tree().reload_current_scene()
	)
	
	level.begin()
