extends Node

# ---States---
# CHASE = 0,
# SCATTER = 1,
# SCARED = 2,
# IDLE = 3,
# DEAD = 4,
# TEST_STATE = 5,

const CHASE_DURATION := 20.0
const SCATTER_DURATION := 7.0
const SCARED_DURATION := 10.0
const SCATTER_WAVES := 4

var global_state: Ghost.State : set = _set_global_state
var prev_global_state := Ghost.State.SCATTER
var wave := 1
var is_in_scatter := true

@onready var scatter_timer = $ScatterTimer
@onready var chase_timer = $ChaseTimer
@onready var scare_timer = $ScareTimer


func _ready():
	scatter_timer.wait_time = SCATTER_DURATION
	scatter_timer.timeout.connect(_on_scatter_timer_timeout)
	scatter_timer.start()
	
	chase_timer.wait_time = CHASE_DURATION
	chase_timer.timeout.connect(_on_chase_timer_timeout)
	
	GameEvents.big_pill_collected.connect(_on_big_pill_collected)
	scare_timer.wait_time = SCARED_DURATION
	scare_timer.timeout.connect(_on_scare_timer_timeout)
	
	global_state = Ghost.State.SCATTER


func _set_global_state(new_state: Ghost.State):
	if global_state != Ghost.State.SCARED:
		prev_global_state = global_state 
	global_state = new_state
	
	var ghosts = get_tree().get_nodes_in_group("ghost") as Array[Ghost]
	for ghost in ghosts:
		if (
			(ghost.current_state == Ghost.State.DEAD or ghost.current_state == Ghost.State.HOME)
			and global_state == Ghost.State.SCARED
		):
			ghost.queue_state = prev_global_state
			continue
		if ghost.current_state == Ghost.State.DEAD or ghost.current_state == Ghost.State.HOME:
			ghost.queue_state = global_state
			continue
		
		ghost.current_state = global_state
		ghost.queue_state = prev_global_state


func _on_scatter_timer_timeout():
	# ENTER CHASE STATE
	global_state = Ghost.State.CHASE
	
	is_in_scatter = false
	
	if wave < SCATTER_WAVES:
		chase_timer.start()


func _on_chase_timer_timeout():
	# ENTER SCATTER STATE
	global_state = Ghost.State.SCATTER
	
	is_in_scatter = true
	wave += 1
	# scatter duration decreases by 2 seconds on the third wave
	var scatter_duration = (SCATTER_DURATION
			if wave < 3
			else SCATTER_DURATION - 2.0
	)
	scatter_timer.start()
	
	print('Scatter Wave: ' + str(wave))


func _on_big_pill_collected():
	if is_in_scatter:
		scatter_timer.paused = true
	else:
		chase_timer.paused = true
	
	# ENTER SCARED STATE
	global_state = Ghost.State.SCARED
	 
	scare_timer.start()


func _on_scare_timer_timeout():
	global_state = Ghost.State.SCATTER if is_in_scatter else Ghost.State.CHASE
	
	if is_in_scatter:
		scatter_timer.paused = false
	else:
		chase_timer.paused = false
