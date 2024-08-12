extends VBoxContainer

var ghost_manager: GhostManager

@onready var state_time: Label = $StateTime
@onready var state: Label = $State
@onready var scare_time: Label = $ScareTime


func _ready() -> void:
	ghost_manager = get_parent() as GhostManager


func _process(delta: float) -> void:
	state_time.text = "%3.1f" % ghost_manager.state_timer.time_left
	state.text = (
			"Scatter" if ghost_manager.global_state == Ghost.State.SCATTER
			else "Chase"
	)
	
	scare_time.visible = not ghost_manager.scare_timer.is_stopped()
	scare_time.text = "%3.1f" % ghost_manager.scare_timer.time_left
