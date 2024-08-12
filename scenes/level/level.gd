extends Node2D
class_name Level

signal intro_finished
signal stopped

var total_pills: int = 0
var pills_eaten: int = 0

@onready var actors: Node2D = $Actors
@onready var intro_sound: AudioStreamPlayer = $Sounds/IntroSound
@onready var ghost_retreat_sound: AudioStreamPlayer = $Sounds/GhostRetreatSound


func _ready():
	GameEvents.pill_collected.connect(_on_pill_collected)
	GameEvents.player_death_started.connect(_on_player_death)
	GameEvents.ghost_eaten.connect(_on_ghost_eaten)
	GameEvents.ghost_reformed.connect(_on_ghost_reformed)
	
	Callable(func ():
		total_pills = get_tree().get_nodes_in_group("pill").size()
	).call_deferred()
	
	Globals.current_level = self


func play_intro():
	for actor in actors.get_children():
		if "is_active" in actor:
			actor.is_active = false
		if actor.has_method("reset"):
			actor.reset()
	
	get_tree().paused = true
	
	intro_sound.play()
	await intro_sound.finished
	
	for actor in actors.get_children():
		if "is_active" in actor:
			actor.is_active = true
	
	get_tree().paused = false
	intro_finished.emit()


func _on_player_death():
	ghost_retreat_sound.stop()
	
	var ghosts = get_tree().get_nodes_in_group("ghost") as Array[Ghost]
	for ghost in ghosts:
		ghost.is_active = false
	
	await GameEvents.player_death_finished
	await get_tree().create_timer(1.0).timeout
	stopped.emit()


func _on_pill_collected():
	pills_eaten += 1
	
	if pills_eaten == total_pills:
		for actor in actors.get_children():
			if "is_active" in actor:
				actor.is_active = false
		
		GameEvents.level_completed.emit()


func _on_ghost_eaten(ghost: Ghost):
	Utils.freeze_frame(0.5)
	if !ghost_retreat_sound.playing:
		ghost_retreat_sound.play()


func _on_ghost_reformed():
	var ghosts = get_tree().get_nodes_in_group("ghost") as Array[Ghost]
	for ghost in ghosts:
		if ghost.current_state == Ghost.State.DEAD:
			return
	
	ghost_retreat_sound.stop()
