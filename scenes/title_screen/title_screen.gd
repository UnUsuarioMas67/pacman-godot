extends CanvasLayer

@onready var high_score_value: Label = %HighScoreValue


func _ready() -> void:
	high_score_value.text = "%07d" % UserData.save_data["high_score"]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("start"):
		get_tree().change_scene_to_file("res://scenes/main/main.tscn")
