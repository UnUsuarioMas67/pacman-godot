extends Node
class_name ScoreManager
 
signal score_updated(new_score: int)

const PILL_VALUE: int = 10
const BIG_PILL_VALUE: int = 50
const GHOST_COMBO_VALUES: Array[int] = [200, 400, 800, 1600]

var score: int = 0
var ghost_combo: int = 0


func _ready() -> void:
	GameEvents.pill_collected.connect(_on_pill_collected)
	GameEvents.big_pill_collected.connect(_on_big_pill_collected)
	GameEvents.ghost_eaten.connect(_on_ghost_eaten)
	GameEvents.global_ghost_state_updated.connect(_on_global_ghost_state_updated)


func _on_pill_collected() -> void:
	score += PILL_VALUE
	score_updated.emit(score)


func _on_big_pill_collected() -> void:
	score += BIG_PILL_VALUE
	score_updated.emit(score)


func _on_ghost_eaten(ghost: Ghost) -> void:
	score += GHOST_COMBO_VALUES[ghost_combo]
	ghost_combo = (ghost_combo + 1) % GHOST_COMBO_VALUES.size()
	score_updated.emit(score)


func _on_global_ghost_state_updated(_global_state: Ghost.State, _scared_mode: bool) -> void:
	if !_scared_mode:
		ghost_combo = 0
