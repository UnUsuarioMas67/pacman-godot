extends Ghost


func _ready():
	super._ready()

func _get_chase_target() -> Vector2:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	
	if global_position.distance_squared_to(player.global_position) < 64 * 64 and scatter_node:
		return scatter_node.global_position
	
	return player.global_position
