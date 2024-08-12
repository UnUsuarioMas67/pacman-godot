extends Node


func _ready():
	GameEvents.big_pill_collected.connect(_on_big_pill_collected)


func _on_big_pill_collected():
	var maze := Globals.get_maze_node()
	var valid_tiles := maze.get_used_cells(0).filter(
		func (tile):
			var is_in_maze := Globals.MAZE_RECT.has_point(tile)
			var not_in_ghost_home := !Globals.GHOST_HOME_RECT.has_point(tile)
			var is_walkable := (maze.get_cell_atlas_coords(0, tile) == Vector2i.ONE
					and maze.get_cell_alternative_tile(0, tile) > 0
			)
			
			return is_in_maze and not_in_ghost_home and is_walkable
	)
	
	for coords in valid_tiles:
		maze.set_cell(0, coords)
	
	print(valid_tiles)
