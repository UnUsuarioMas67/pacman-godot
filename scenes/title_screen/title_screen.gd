extends CanvasLayer

@onready var high_score_value: Label = %HighScoreValue
@onready var press_start: HBoxContainer = %PressStart


func _ready() -> void:
	high_score_value.text = "%07d" % UserData.save_data["high_score"]
	
	# make press start text blink
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(press_start, "visible", true, 0).set_delay(0.2)
	tween.tween_property(press_start, "visible", false, 0).set_delay(0.2)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("start"):
		get_tree().change_scene_to_file("res://scenes/main/main.tscn")
