extends Node2D
class_name FloatingNumber

const FLOATING_NUMBER = preload("res://scenes/ui/floating_number.tscn")

var _value: int = 0

@onready var label: Label = $Label


static func create(parent: Node2D, value: int):
	var floating_number: FloatingNumber = FLOATING_NUMBER.instantiate()
	floating_number._value = value
	floating_number.global_position = parent.global_position + Vector2(0, -4)
	parent.add_child(floating_number)


func _ready() -> void:
	top_level = true
	label.text = str(_value)
	
	var tween: Tween = create_tween()
	tween.tween_interval(0.3)
	tween.tween_callback(queue_free)
	
