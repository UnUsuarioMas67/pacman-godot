extends VBoxContainer

const LIFE_SCENE: PackedScene = preload("res://scenes/ui/life.tscn")

@export var score_manager: ScoreManager
@export var lives_manager: LivesManager

@onready var score_value: Label = %ScoreValue
@onready var lives_container: HBoxContainer = %LivesContainer
@onready var level: Label = %Level


func _ready() -> void:
	score_manager.score_updated.connect(_on_score_updated)
	lives_manager.lives_updated.connect(_on_lives_updated)
	GameEvents.level_changed.connect(_on_level_changed)
	
	await lives_manager.ready
	for life in lives_container.get_children():
		life.queue_free()
	
	for life in lives_manager.starting_lives:
		var life_instance = LIFE_SCENE.instantiate()
		lives_container.add_child(life_instance)


func _on_score_updated(new_score: int, score_gained: int) -> void:
	score_value.text = "%07d" % new_score


func _on_lives_updated(lives_left: int) -> void:
	# loop through lives_container children in reverse order
	for life in range(lives_container.get_child_count() - 1, lives_left - 1, -1):
		lives_container.get_child(life).hide()


func _on_level_changed(new_level: int) -> void:
	level.text = "Level: " + str(new_level)
