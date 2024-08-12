extends Ghost

var ignore_scatter := false


func _ready():
	super._ready()
	GameEvents.half_pills_collected.connect(_on_half_pills_collected)


func _get_scatter_target() -> Vector2:
	if ignore_scatter:
		var player := get_tree().get_first_node_in_group("player") as Node2D
		return player.global_position
	else:
		return scatter_node.global_position


func _on_half_pills_collected():
	ignore_scatter = true
	print_rich(
		"[color={0}][{1}][/color] ".format([debug_color, name])
		+ "Half of the pills have been eaten. {0} is now [color=magenta]ANGRY[/color]!".format([name])
	)
