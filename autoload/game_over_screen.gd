extends CanvasLayer

signal ended

var new_high_score: bool = false

@onready var high_score: VBoxContainer = %HighScore
@onready var high_score_value: Label = %HighScoreValue
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	UserData.high_score_updated.connect(_on_high_score_updated)
	
	hide()
	high_score.hide()


func display() -> void:
	animation_player.play("display")


func _show_high_score() -> void:
	if new_high_score:
		high_score.show()
		high_score_value.text = "%07d" % UserData.save_data["high_score"]
		new_high_score = false
	else:
		high_score.hide()


func _emit_ended_signal() -> void:
	ended.emit()


func _on_high_score_updated() -> void:
	new_high_score = true
