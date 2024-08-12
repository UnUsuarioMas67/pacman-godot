extends Ghost

@onready var chase_timer = $ChaseTimer


func _ready():
	super._ready()


func _update_chase_position():
	# if Clyde gets too close to the player he will retreat for 1 second
	# before resuming his chase
	navigation_agent.target_position = scatter_node.global_position
	
	if !chase_timer.is_stopped():
		return
	
	if global_position.distance_to(player.global_position) < 56 and scatter_node:
		chase_timer.start()
	else:
		navigation_agent.target_position = player.global_position
	
