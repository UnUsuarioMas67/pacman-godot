extends Node

var total_pills: int = 0
var pills_left: int = 0


func _ready():
	GameEvents.pill_collected.connect(_on_pill_collected)
	Callable(
		func():
			total_pills = get_tree().get_nodes_in_group("pill").size()
	).call_deferred()


func _on_pill_collected():
	pills_left = get_tree().get_nodes_in_group("pill").size()
	
	if pills_left == 0:
		GameEvents.level_completed.emit()
	if pills_left == total_pills - 30:
		GameEvents.thirty_pills_collected.emit()
	if pills_left == total_pills / 2:
		GameEvents.half_pills_collected.emit()
