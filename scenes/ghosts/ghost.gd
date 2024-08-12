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
@export var pills_required := 0
@export_enum("home_left", "home_center", "home_right") var home_position_group := "home_center" 
@export_enum("red", "pink", "cyan", "orange") var debug_color := "red"

var can_move := true
var is_active := true : set = _set_is_active
var current_state: State : set = _set_state
var queue_state: State
var current_move_speed := NORMAL_MOVE_SPEED
var current_direction := Vector2.LEFT
var next_direction := Vector2.ZERO
var target_position: Vector2
var shape_query := PhysicsShapeQueryParameters2D.new()

@onready var hurtbox_collision = $Hurtbox/CollisionShape2D
@onready var animated_sprite = $AnimatedSprite2D
@onready var intersection_collider: Area2D = $IntersectionCollider
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var eaten_sound: AudioStreamPlayer = $Sounds/EatenSound
@onready var retreat_sound: AudioStreamPlayer = $Sounds/RetreatSound


func _ready():
	GameEvents.pill_collected.connect(_on_pill_collected)
	GameEvents.global_ghost_state_updated.connect(_on_global_ghost_state_updated)
	intersection_collider.area_entered.connect(_on_intersection_collider_area_entered)
	
	shape_query.shape = collision_shape.shape
	
	current_state = initial_state
	
	if current_state == State.HOME and pills_required == 0:
		await _exit_home().finished
		current_state = queue_state
	
	# PRINT SCATTER NODE WARNING
	assert(!!scatter_node, "[{0}] does not have a Scatter Node assigned".format([name]))
	

func _physics_process(delta):
	if !is_active:
		return
	
	if Utils.is_direction_free(self, current_move_speed, shape_query, next_direction, delta):
		current_direction = next_direction
	
	if can_move:
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
	
	# enter new state
	match new_state:
		State.CHASE, State.SCATTER:
			current_move_speed = NORMAL_MOVE_SPEED
		State.HOME:
			_force_direction(Vector2.DOWN)
			can_move = false
		State.SCARED:
			current_move_speed = SCARED_MOVE_SPEED
		State.DEAD:
			current_move_speed = DEAD_MOVE_SPEED
			_play_death_sound()
	
	if new_state != State.DEAD:
		retreat_sound.stop()
	
	var prev_state = current_state
	current_state = new_state
	
	_print_state_debug_info(new_state)
	
	# prevents the ghost from turning around
	if prev_state == State.HOME or new_state == State.HOME:
		return
	_turn_around()


func _play_death_sound():
	eaten_sound.play()
	await eaten_sound.finished
	retreat_sound.play()


func _turn_around():
	_force_direction(current_direction * -1)
	# TODO - explain these lines
	var intersections = intersection_collider.get_overlapping_areas()
	if intersections.size() > 0:
		_on_intersection_collider_area_entered(intersections[0])


func _force_direction(direction: Vector2):
	next_direction = direction
	current_direction = direction


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


func _get_target_position() -> Vector2:
	match current_state:
		State.CHASE:
			return _get_chase_target()
		State.SCATTER:
			return _get_scatter_target()
		State.DEAD:
			var entrance = get_tree().get_first_node_in_group("entrance") as Node2D
			return entrance.global_position
		_:
			return Vector2.ZERO


func _get_chase_target() -> Vector2:
	var player: Node2D = get_tree().get_first_node_in_group("player")
	return player.global_position


func _get_scatter_target() -> Vector2:
	return scatter_node.global_position


func _get_available_directions(node) -> Array[Vector2]:
	var directions: Array[Vector2] = [Vector2.UP, Vector2.LEFT, Vector2.DOWN, Vector2.RIGHT]
	var result = directions.filter(func(dir):
		# this line makes sure the query detects the ghost home gate only when checking the down direction and is not death
		# so the ghost can move out of their home but not back in
		# TODO - modify this behavior when handling the DEAD state
		shape_query.collision_mask = 0b10001
		
		return Utils.is_direction_free(
				node, 
				current_move_speed, 
				shape_query, 
				dir, 
				get_physics_process_delta_time()
		)
	)
	
	return result if result.size() > 0 else [Vector2.ZERO]


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


func _choose_next_direction(node: Area2D) -> void:
	target_position = _get_target_position()
	
	var available_directions = _get_available_directions(node).filter(func(dir):
		# exclude the direction opposite to the current one
		return dir != current_direction * -1
	)
	
	next_direction = (
			_get_best_direction(available_directions) if current_state != State.SCARED
			else available_directions.pick_random()
	)
	
	# DEBUG INFORMATION
	_print_pathfinding_debug_info(available_directions, next_direction)


func _exit_home() -> Tween:
	# 0. Get nodes
	var entrance = get_tree().get_first_node_in_group("entrance") as Node2D
	var center = get_tree().get_first_node_in_group("home_center") as Node2D
	var home_node = (
			center if home_position_group == "home_center"
			else get_tree().get_first_node_in_group(home_position_group) as Node2D
	)
	
	# 1. Move to center
	var tween := create_tween()
	
	if home_node != center:
		var home_to_center_duration: float = center.global_position.distance_to(home_node.global_position) / current_move_speed
		tween.tween_property(self, "global_position", center.global_position, home_to_center_duration)\
				.from(home_node.global_position)
		var face_dir = Vector2.RIGHT if home_position_group == "home_left" else Vector2.LEFT
		tween.parallel().tween_callback(_force_direction.bind(face_dir))
	
	# 2. Move outside
	var center_to_entrance_duration: float = entrance.global_position.distance_to(center.global_position) / current_move_speed
	tween.tween_property(self, "global_position", entrance.global_position, center_to_entrance_duration)\
			.from(center.global_position)
	tween.parallel().tween_callback(_force_direction.bind(Vector2.UP))
	
	# 3. Choose move direction
	tween.tween_callback(_choose_next_direction.bind(entrance))
	
	# 4. Re-enable movement
	tween.tween_property(self, "can_move", true, 0)
	
	return tween


func _enter_home() -> Tween:
	# 0. Disable regular movement
	can_move = false
	
	# 1. Get the necessary nodes
	var entrance = get_tree().get_first_node_in_group("entrance") as Node2D
	var center = get_tree().get_first_node_in_group("home_center") as Node2D
	var home_node = (
			center if home_position_group == "home_center"
			else get_tree().get_first_node_in_group(home_position_group) as Node2D
	)
	
	# 2. Tween ghost position to entrance
	var tween := create_tween()
	
	var ghost_to_entrance_duration: float = global_position.distance_to(entrance.global_position) / current_move_speed
	tween.tween_property(self, "global_position", entrance.global_position, ghost_to_entrance_duration)
	
	# 3. Move from entrance to center of home
	var entrance_to_center_duration: float = entrance.global_position.distance_to(center.global_position) / current_move_speed
	tween.tween_property(self, "global_position", center.global_position, entrance_to_center_duration)\
			.from(entrance.global_position)
	tween.parallel().tween_callback(_force_direction.bind(Vector2.DOWN))
	
	# 4. Move from center to home position
	if home_node != center:
		var center_to_home_duration: float = center.global_position.distance_to(home_node.global_position) / current_move_speed
		tween.tween_property(self, "global_position", home_node.global_position, center_to_home_duration)\
				.from(center.global_position)
		var face_dir = Vector2.LEFT if home_position_group == "home_left" else Vector2.RIGHT
		tween.parallel().tween_callback(_force_direction.bind(face_dir))
	
	return tween


func _on_intersection_collider_area_entered(area: Area2D):
	if current_state == State.HOME:
		return
	
	if area.is_in_group("intersection_node"):
		_choose_next_direction(area)
	elif area.is_in_group("entrance") && current_state == State.DEAD:
		await _enter_home().finished
		current_state = queue_state
		await _exit_home().finished


func _on_pill_collected():
	if current_state != State.HOME:
		return
	
	var level = owner as Level
	
	if level.pills_eaten == pills_required:
		await _exit_home().finished
		current_state = queue_state


func _on_global_ghost_state_updated(global_state: Ghost.State, scared_mode: bool):
	if current_state == State.DEAD or current_state == State.HOME:
		queue_state = global_state
		return
	
	current_state = global_state if not scared_mode else State.SCARED


func _print_pathfinding_debug_info(available_directions: Array[Vector2], chosen_direction: Vector2):
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
		+ str(directions_to_text) if directions_to_text.size() > 0 else "NONE" 
		+ "[/color]"
	)
	print_rich(
		"[color={0}][{1}][/color] ".format([debug_color, name])
		+ "Next direction: [color=white]" 
		+ (
				directions_to_text[available_directions.find(chosen_direction)]
				if available_directions.has(chosen_direction)
				else "NONE"
		)
		+ "[/color]"
	)


func _print_state_debug_info(new_state: State):
	var state_name = ""
	match new_state:
		State.CHASE:
			state_name = "CHASE"
		State.SCATTER:
			state_name = "SCATTER"
		State.HOME:
			state_name = "HOME"
		State.SCARED:
			state_name = "SCARED"
		State.DEAD:
			state_name = "DEAD"
	
	print_rich(
		"[color={0}][{1}][/color] ".format([debug_color, name])
		+ "Entering [color=magenta]{0}[/color] State".format([state_name]) 
	)
