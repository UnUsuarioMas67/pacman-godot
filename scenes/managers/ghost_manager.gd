extends Node

const CHASE_DURATION := 20.0
const SCATTER_DURATION := 7.0
const SCARED_DURATION := 10.0
const SCATTER_WAVES := 4

var global_state: Ghost.State = Ghost.State.SCATTER
var wave := 1

@onready var scare_timer = $ScareTimer
@onready var state_timer: Timer = $StateTimer


func _ready():
	state_timer.wait_time = (SCATTER_DURATION
			if global_state == Ghost.State.SCATTER
			else CHASE_DURATION
	)
	state_timer.timeout.connect(_on_state_timer_timeout)
	state_timer.start()
	
	GameEvents.big_pill_collected.connect(_on_big_pill_collected)
	scare_timer.wait_time = SCARED_DURATION
	scare_timer.timeout.connect(_on_scare_timer_timeout)
	
	GameEvents.global_ghost_state_updated.connect(_print_debug_info)
	
	await get_tree().physics_frame
	GameEvents.global_ghost_state_updated.emit(global_state, !scare_timer.is_stopped())


func _enter_chase():
	global_state = Ghost.State.CHASE
	
	if wave < SCATTER_WAVES:
		state_timer.start(CHASE_DURATION)


func _enter_scatter():
	# ENTER SCATTER STATE
	global_state = Ghost.State.SCATTER
	
	wave += 1
	# scatter duration decreases by 2 seconds on the third wave
	var scatter_duration = (SCATTER_DURATION
			if wave < 3
			else SCATTER_DURATION - 2.0
	)
	state_timer.start(scatter_duration)


func _on_state_timer_timeout():
	if global_state == Ghost.State.SCATTER:
		_enter_chase()
	else:
		_enter_scatter()
	
	GameEvents.global_ghost_state_updated.emit(global_state, !scare_timer.is_stopped())


func _on_big_pill_collected():
	state_timer.paused = true
	
	scare_timer.start()
	GameEvents.global_ghost_state_updated.emit(global_state, !scare_timer.is_stopped())


func _on_scare_timer_timeout():
	state_timer.paused = false
	GameEvents.global_ghost_state_updated.emit(global_state, !scare_timer.is_stopped())


func _print_debug_info(global_state: Ghost.State, scared_mode: bool):
	var state_name = "SCATTER" if global_state == Ghost.State.SCATTER else "CHASE"
	
	print_rich(
		"[color=yellow][GHOST_MANAGER][/color] Global State: [color=magenta]{0}[/color]. ".format([state_name])
		+ "Scared mode: [color=white]{0}[/color]".format([scared_mode])
	)
