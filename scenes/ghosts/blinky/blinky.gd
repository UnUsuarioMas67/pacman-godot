extends Ghost

var ignore_scatter := false


func _ready():
	super._ready()
	GameEvents.half_pills_collected.connect(_on_half_pills_collected)


func _update_scatter_position():
	if ignore_scatter:
		navigation_agent.target_position = player.global_position
	else:
		navigation_agent.target_position = scatter_node.global_position


func _on_half_pills_collected():
	ignore_scatter = true
	print('Half of the pills have been eaten. Blinky is now angry.')
