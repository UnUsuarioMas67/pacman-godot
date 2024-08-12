extends Node

const MAZE_RECT := Rect2i(Vector2i(26, 5), Vector2i(54, 36) - Vector2i(26, 5))
const GHOST_HOME_RECT := Rect2i(Vector2i(36, 17), Vector2i(44, 22) - Vector2i(36, 17))


func get_player_node() -> Node2D:
	var player = get_tree().get_first_node_in_group("player")
	return player


func get_maze_node() -> TileMap:
	var maze = get_tree().get_first_node_in_group("maze")
	return maze


func get_player_tile_pos() -> Vector2:
	var player = get_tree().get_first_node_in_group("player") as Node2D
	var maze = get_tree().get_first_node_in_group("maze") as TileMap
	
	if !player or !maze:
		return -Vector2.ONE
	
	var global_to_local = maze.to_local(player.global_position)
	var local_to_map = maze.local_to_map(global_to_local)
	var player_tile_pos = maze.to_global(maze.map_to_local(local_to_map))
	
	return player_tile_pos
