extends CharacterBody2D
class_name Ghost

enum State {
	CHASE = 0,
	SCATTER = 1,
	SCARED = 2,
	HOME = 3,
	DEAD = 4,
}

const NORMAL_MOVE_SPEED := 55.0
const SCARED_MOVE_SPEED := 34.0
const DEAD_MOVE_SPEED := 120.0

@export var initial_state: State
@export var scatter_node: Node2D
@export var home_node: Node2D
@export_enum("red", "pink", "cyan", "orange") var debug_color := "red"

var is_active := true : set = _set_is_active
var current_state: State : set = _set_state
var queue_state: State
var current_move_speed := NORMAL_MOVE_SPEED
var current_direction := Vector2.ZERO
var next_direction := Vector2.ZERO
var target_position: Vector2
var shape_query := PhysicsShapeQueryParameters2D.new()

@onready var hurtbox_collision = $Hurtbox/CollisionShape2D
@onready var animated_sprite = $AnimatedSprite2D
@onready var intersection_collider: Area2D = $IntersectionCollider
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready():
	GameEvents.thirty_pills_collected.connect(_on_thirty_pills_collected)
	intersection_collider.area_entered.connect(_on_intersection_collider_area_entered)
	
	shape_query.shape = collision_shape.shape
	
	current_state = initial_state


func _physics_process(delta):
	if !is_active:
		return
	
	if Utils.is_direction_free(self, current_move_speed, shape_query, next_direction, delta):
		current_direction = next_direction
	
	velocity = current_move_speed * current_direction
	move_and_slide()
	_handle_animation()


func _set_is_active(value: bool):
	if value:
		show()
	else:
		hide()
	
	is_active = value


func die():
	current_state = State.DEAD


func set_hurtbox_disabled(is_disabled: bool) -> void:
	Callable(func (): hurtbox_collision.disabled = is_disabled).call_deferred()


func _set_state(new_state: State):
	if new_state == current_state:
		return
	
	## exit previous state
	#match current_state:
		#State.DEAD:
			#set_hurtbox_disabled(false)
	
	# enter new state
	match new_state:
		State.CHASE, State.SCATTER:
			current_move_speed = NORMAL_MOVE_SPEED
		State.HOME:
			current_direction = Vector2.UP
		State.SCARED:
			current_move_speed = SCARED_MOVE_SPEED
		State.DEAD:
			current_move_speed = DEAD_MOVE_SPEED
			#set_hurtbox_disabled(true)
	
	current_state = new_state
	_turn_around()


func _turn_around():
	next_direction = current_direction * -1
	current_direction = next_direction
	# TODO - explain these lines
	var intersections = intersection_collider.get_overlapping_areas()
	if intersections.size() > 0:
		_on_intersection_collider_area_entered(intersections[0])


func _handle_animation():
	if current_state == State.SCARED:
		animated_sprite.play("scared")
		return
	
	var anim_prefix = "move" if current_state != State.DEAD else "dead"
	var anim_suffix = "left"
	
	if round(current_direction.y) == 1:
		anim_suffix = "down"
	elif round(current_direction.x) == 1:
		anim_suffix = "right"
	elif round(current_direction.y) == -1:
		anim_suffix = "up"
	
	animated_sprite.play("{0}_{1}".format([anim_prefix, anim_suffix]))


func _get_available_directions(node) -> Array[Vector2]:
	var directions: Array[Vector2] = [Vector2.UP, Vector2.LEFT, Vector2.DOWN, Vector2.RIGHT]
	var result = directions.filter(func(dir):
		# this line makes sure the query detects the ghost home gate only when checking the down direction and is not death
		# so the ghost can move out of their home but not back in
		# TODO - modify this behavior when handling the DEAD state
		shape_query.collision_mask = (
				0b10001 if dir == Vector2.DOWN and current_state != State.DEAD 
				else 0b1
		)
		return Utils.is_direction_free(
				node, 
				current_move_speed, 
				shape_query, 
				dir, 
				get_physics_process_delta_time()
		)
	)
	
	return result if result.size() > 0 else [Vector2.ZERO]


func _get_target_position() -> Vector2:
	match current_state:
		State.CHASE:
			return _get_chase_target()
		State.SCATTER:
			return _get_scatter_target()
		State.DEAD:
			return home_node.global_position
		_:
			return Vector2.ZERO


func _get_chase_target() -> Vector2:
	var player: Node2D = get_tree().get_first_node_in_group("player")
	return player.global_position


func _get_scatter_target() -> Vector2:
	return scatter_node.global_position


func _get_best_direction(direction_list: Array[Vector2]) -> Vector2:
	if direction_list.size() == 0:
		return Vector2.ZERO
	
	var chosen_direction: Vector2 = direction_list[0]
	for dir in direction_list:
		var distance_from_current = (global_position + dir).distance_squared_to(target_position)
		var distance_from_chosen = (global_position + chosen_direction).distance_squared_to(target_position)
		
		if distance_from_current < distance_from_chosen or chosen_direction == Vector2.ZERO:
			chosen_direction = dir
	
	return chosen_direction


func _on_intersection_collider_area_entered(area: Area2D):
	if current_state == State.HOME:
		return
	if current_state == State.DEAD and area == home_node:
		current_state = queue_state
		global_position = area.global_position
		return
	
	target_position = _get_target_position()
	
	var available_directions = _get_available_directions(area).filter(func(dir):
		# exclude the direction opposite to the current one
		return dir != current_direction * -1
	)
	
	next_direction = (
			_get_best_direction(available_directions) if current_state != State.SCARED
			else available_directions.pick_random()
	)
	
	# DEBUG INFORMATION
	var directions_to_text = available_directions.map(func(dir):
		if dir == Vector2.UP:
			return "UP"
		if dir == Vector2.LEFT:
			return "LEFT"
		if dir == Vector2.DOWN:
			return "DOWN"
		if dir == Vector2.RIGHT:
			return "RIGHT"
		
		return "WHAT"
	)
	
	print_rich(
		"[color={0}][{1}][/color] ".format([debug_color, name])
		+ "Available directions: [color=white]" 
		+ str(directions_to_text) + "[/color]"
	)
	print_rich(
		"[color={0}][{1}][/color] ".format([debug_color, name])
		+ "Next direction: [color=white]" 
		+ (
				directions_to_text[available_directions.find(next_direction)]
				if available_directions.has(next_direction)
				else "NONE"
		)
		+ "[/color]"
	)


func _on_thirty_pills_collected():
	if current_state == State.HOME:
		current_state = queue_state
		print('30 pills have been eaten. Leaving HOME')
