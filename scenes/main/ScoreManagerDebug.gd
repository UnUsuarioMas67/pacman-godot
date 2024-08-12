extends VBoxContainer

var score_manager: ScoreManager

@onready var score_label: Label = $ScoreLabel
@onready var combo_label: Label = $ComboLabel


func _ready() -> void:
	score_manager = get_parent() as ScoreManager
	score_manager.score_updated.connect(_on_score_updated)


func _on_score_updated(new_score: int) -> void:
	score_label.text = "Score: " + str(new_score)
	combo_label.text = "Combo: " + str(score_manager.ghost_combo)
