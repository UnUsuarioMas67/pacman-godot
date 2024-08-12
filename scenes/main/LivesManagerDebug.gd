extends Label

var lives_manager: LivesManager


func _ready() -> void:
	lives_manager = get_parent() as LivesManager
	lives_manager.lives_updated.connect(_on_lives_updated)


func _on_lives_updated(new_lives: int) -> void:
	text = "Lives: " + str(new_lives)
