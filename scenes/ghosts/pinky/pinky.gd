extends Ghost


func _get_chase_target() -> Vector2:
	var player = get_tree().get_first_node_in_group("player")
	return player.global_position + 16 * player.current_direction
