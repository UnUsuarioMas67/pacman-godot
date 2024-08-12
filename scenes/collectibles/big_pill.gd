extends Area2D


func _ready():
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D):
	if !area.owner.is_in_group("player"):
		return
	
	GameEvents.big_pill_collected.emit()
	GameEvents.pill_collected.emit()
	queue_free()
