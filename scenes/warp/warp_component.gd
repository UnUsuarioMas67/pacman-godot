extends Node

var target: Node2D
var warp_left: Node2D
var warp_right: Node2D


func _ready():
	target = owner as Node2D


func _physics_process(delta):
	if !target:
		return
	if !warp_left or !warp_right:
		get_warp_points()
	
	if target.global_position.x < warp_left.global_position.x:
		target.global_position.x = warp_right.global_position.x - 1
	elif target.global_position.x > warp_right.global_position.x:
		target.global_position.x = warp_left.global_position.x + 1


func get_warp_points():
	warp_left = get_tree().get_first_node_in_group("warp_left")
	warp_right = get_tree().get_first_node_in_group("warp_right")
