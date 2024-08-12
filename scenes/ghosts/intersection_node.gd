extends Area2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _process(delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if !Globals.debug_mode:
		return
	
	draw_circle(Vector2.ZERO, collision_shape.shape.radius, collision_shape.debug_color)
