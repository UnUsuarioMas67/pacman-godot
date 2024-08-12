extends VBoxContainer

@export var score_manager: ScoreManager
@export var lives_manager: LivesManager

@onready var score_value: Label = %ScoreValue
@onready var lives: HBoxContainer = $PanelContainer3/Lives


func _ready() -> void:
	score_manager.score_updated.connect(_on_score_updated)
	lives_manager.lives_updated.connect(_on_lives_updated)


func _on_score_updated(new_score: int) -> void:
	score_value.text = "%07d" % new_score


func _on_lives_updated(new_lives: int) -> void:
	pass
