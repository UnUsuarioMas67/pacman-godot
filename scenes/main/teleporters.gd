extends Node2D

var excluded_bodies: Array[Node2D] = []

@onready var teleporter_left = $TeleporterLeft
@onready var teleporter_right = $TeleporterRight


func _ready():
	teleporter_left.body_entered.connect(_on_left_teleporter_entered)
	teleporter_left.body_exited.connect(_on_left_teleporter_exited)
	teleporter_right.body_entered.connect(_on_right_teleporter_entered)
	teleporter_right.body_exited.connect(_on_right_teleporter_exited)


func _on_left_teleporter_entered(body: Node2D):
	if excluded_bodies.has(body):
		return
	
	excluded_bodies.append(body)
	body.global_position.x = teleporter_right.global_position.x


func _on_left_teleporter_exited(body: Node2D):
	excluded_bodies.erase(body)


func _on_right_teleporter_entered(body: Node2D):
	if excluded_bodies.has(body):
		return
	
	excluded_bodies.append(body)
	body.global_position.x = teleporter_left.global_position.x


func _on_right_teleporter_exited(body: Node2D):
	excluded_bodies.erase(body)
