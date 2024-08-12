extends Node2D


func _ready():
	GameEvents.player_died.connect(_on_player_died)
	GameEvents.level_completed.connect(
		func():
			await get_tree().create_timer(0.5).timeout
			get_tree().reload_current_scene()
	)
	
	begin()


func begin():
	var player = get_tree().get_first_node_in_group("player") as Node2D
	var ghosts = get_tree().get_nodes_in_group("ghost") as Array[Ghost]
	
	player.is_active = false
	for ghost in ghosts:
		ghost.is_active = false
	
	await get_tree().create_timer(3.0).timeout
	
	player.is_active = true
	for ghost in ghosts:
		ghost.is_active = true


func _on_player_died():
	var ghosts = get_tree().get_nodes_in_group("ghost") as Array[Ghost]
	for ghost in ghosts:
		ghost.is_active = false
	
	await get_tree().create_timer(1.5).timeout
	get_tree().reload_current_scene()
