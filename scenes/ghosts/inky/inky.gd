extends Ghost

var _blinky: Ghost


func _update_chase_position():
	if !_blinky:
		_blinky = get_tree().get_first_node_in_group("blinky")
	
	var player_factor: Vector2 = player.global_position + 16 * player.current_direction
	var blinky_vector: Vector2 = _blinky.global_position.distance_to(player_factor) \
			* _blinky.global_position.direction_to(player_factor)
	
	navigation_agent.target_position = _blinky.global_position + (blinky_vector * 2)
