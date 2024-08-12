extends Node

func is_direction_free(
		body: Node2D, 
		move_speed:float, 
		shape_query_params: PhysicsShapeQueryParameters2D, 
		direction: Vector2, 
		delta: float
) -> bool:
	#shape_query_params.transform = body.global_transform.translated(move_speed * direction * delta * 5)
	shape_query_params.transform = body.global_transform.translated(shape_query_params.shape.get_rect().size * direction)
	var result = body.get_world_2d().direct_space_state.intersect_shape(shape_query_params)
	return result.size() == 0
