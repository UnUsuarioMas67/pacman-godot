extends Area2D


func _ready():
	area_entered.connect(_on_area_entered)
	#print('pill entered')


func _on_area_entered(area: Area2D):
	if !area.owner.is_in_group("player"):
		return
	
	queue_free()
	await tree_exited
	GameEvents.pill_collected.emit()
