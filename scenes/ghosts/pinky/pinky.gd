extends Ghost


func _update_chase_position():
	navigation_agent.target_position = player.global_position + 16 * player.current_direction
