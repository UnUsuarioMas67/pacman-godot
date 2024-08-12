extends Node
class_name LivesManager

signal lives_updated(new_lives: int)

@export var starting_lives: int = 3

var lives: int


func _ready() -> void:
	GameEvents.player_death_finished.connect(_on_player_death)
	lives = starting_lives


func _on_player_death() -> void:
	lives = max(lives - 1, 0)
	lives_updated.emit(lives)
