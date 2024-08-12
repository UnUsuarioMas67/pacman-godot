extends Node2D
class_name Level

var total_pills: int = 0
var pills_eaten: int = 0


func _ready():
	GameEvents.pill_collected.connect(_on_pill_collected)
	Callable(func ():
		total_pills = get_tree().get_nodes_in_group("pill").size()
	).call_deferred()


func _on_pill_collected():
	pills_eaten += 1
	
	if pills_eaten == total_pills:
		GameEvents.level_completed.emit()
