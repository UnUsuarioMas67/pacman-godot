extends Node
class_name GhostManager

# SFX
const SIREN_1: AudioStreamWAV = preload("res://assets/sfx/siren_1.wav")
const SIREN_2: AudioStreamWAV = preload("res://assets/sfx/siren_2.wav")
const SIREN_3: AudioStreamWAV = preload("res://assets/sfx/siren_3.wav")
const SIREN_4: AudioStreamWAV = preload("res://assets/sfx/siren_4.wav")
const POWER_PELLET: AudioStreamWAV = preload("res://assets/sfx/power_pellet.wav")

# State Constants
const CHASE_DURATION := 20.0
const SCATTER_DURATION := 7.0
const SCARED_DURATION := 10.0
const SCATTER_WAVES := 4

var global_state: Ghost.State = Ghost.State.SCATTER
var wave := 1

@onready var scare_timer = $ScareTimer
@onready var state_timer: Timer = $StateTimer
@onready var asp: AudioStreamPlayer = $AudioStreamPlayer


func _ready():
	state_timer.wait_time = (SCATTER_DURATION
			if global_state == Ghost.State.SCATTER
			else CHASE_DURATION
	)
	state_timer.timeout.connect(_on_state_timer_timeout)
	
	GameEvents.big_pill_collected.connect(_on_big_pill_collected)
	scare_timer.wait_time = SCARED_DURATION
	scare_timer.timeout.connect(_on_scare_timer_timeout)
	
	GameEvents.global_ghost_state_updated.connect(_print_debug_info)
	GameEvents.player_death_started.connect(_on_player_death_started)
	
	var level: Level = owner as Level
	level.intro_finished.connect(_on_level_intro_finished)


func _play_siren():
	if not scare_timer.is_stopped():
		asp.stream = POWER_PELLET
		asp.play()
		return
	
	var new_stream: AudioStreamWAV = SIREN_1
	
	match wave:
		2:
			new_stream = SIREN_2
		3:
			new_stream = SIREN_3
		4:
			new_stream = SIREN_4
	
	if !asp.playing or new_stream != asp.stream:
		asp.stream = new_stream
		asp.play()


func _stop_siren() -> void:
	asp.stop()


func _enter_chase():
	global_state = Ghost.State.CHASE
	
	if wave < SCATTER_WAVES:
		state_timer.start(CHASE_DURATION)
	
	_play_siren()


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
	_play_siren()
	GameEvents.global_ghost_state_updated.emit(global_state, !scare_timer.is_stopped())


func _on_scare_timer_timeout():
	state_timer.paused = false
	_play_siren()
	GameEvents.global_ghost_state_updated.emit(global_state, !scare_timer.is_stopped())


func _on_level_intro_finished():
	_play_siren()
	state_timer.paused = false
	state_timer.start(state_timer.time_left)
	GameEvents.global_ghost_state_updated.emit(global_state, !scare_timer.is_stopped())


func _on_player_death_started():
	_stop_siren()
	state_timer.paused = true
	scare_timer.stop()


func _print_debug_info(state: Ghost.State, scared_mode: bool):
	var state_name = "SCATTER" if state == Ghost.State.SCATTER else "CHASE"
	
	print_rich(
		"[color=yellow][GHOST_MANAGER][/color] Global State: [color=magenta]{0}[/color]. ".format([state_name])
		+ "Scared mode: [color=white]{0}[/color]".format([scared_mode])
	)
