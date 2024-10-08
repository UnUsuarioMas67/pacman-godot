extends CharacterBody2D
class_name Ghost

enum State {
	CHASE = 0,
	SCATTER = 1,
	SCARED = 2,
	HOME = 3,
	DEAD = 4,
}

const NORMAL_MOVE_SPEED := 50.0
const SCARED_MOVE_SPEED := 30.0
const DEAD_MOVE_SPEED := 120.0

@export var initial_state: State
@export var scatter_node: Node2D
@export var pills_required := 0
@export_range(0.0, 5.0, 0.1, "suffix:s") var home_exit_delay: float = 0.0
@export_enum("home_left", "home_center", "home_right") var home_position_group := "home_center" 
@export_enum("red", "pink", "cyan", "orange") var debug_color := "red"

var current_state: State : set = _set_state
var is_active := true : set = _set_is_active

var _queue_state: State
var _current_move_speed := NORMAL_MOVE_SPEED
var _current_direction := Vector2.ZERO
var _next_direction := Vector2.ZERO
var _target_position: Vector2
var _shape_query := PhysicsShapeQueryParameters2D.new()
var _can_move := true
var _home_node: Node2D
var _home_tween: Tween
var _blink_tween: Tween
var _already_left_home: bool = false
var _draw_params: Dictionary = {
	"pivot": null,
	"chosen_dir": Vector2.ZERO,
	"available_dir": [],
}

@onready var hurtbox_collision = $Hurtbox/CollisionShape2D
@onready var animated_sprite = $AnimatedSprite2D
@onready var intersection_collider: Area2D = $IntersectionCollider
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var eaten_sound: AudioStreamPlayer = $EatenSound
@onready var home_exit_timer: Timer = $HomeExitTimer


func _ready():
	GameEvents.pill_collected.connect(_on_pill_collected)
	GameEvents.global_ghost_state_updated.connect(_on_global_ghost_state_updated)
	intersection_collider.area_entered.connect(_on_intersection_collider_area_entered)
	
	if home_exit_delay > 0.0:
		home_exit_timer.wait_time = home_exit_delay
	
	_shape_query.shape = collision_shape.shape
	_shape_query.collision_mask = 0b10001
	_home_node = get_tree().get_first_node_in_group(home_position_group)
	
	current_state = initial_state
	
	# PRINT SCATTER NODE WARNING
	assert(!!scatter_node, "[{0}] does not have a Scatter Node assigned".format([name]))


func _physics_process(delta):
	if !is_active:
		return
	
	if current_state != State.HOME and _current_direction == Vector2.ZERO:
		_choose_next_direction(self)
	
	if Utils.is_direction_free(self, _current_move_speed, _shape_query, _next_direction, delta):
		_current_direction = _next_direction
	
	if _can_move:
		velocity = _current_move_speed * _current_direction
		move_and_slide()
	_handle_animation()
	queue_redraw()


func _draw() -> void:
	if !_draw_params["pivot"] or !Globals.debug_mode:
		return
	
	for dir in _draw_params["available_dir"]:
		var from: Vector2 = to_local(_draw_params["pivot"].global_position)
		var to: Vector2 = from + (16 * dir)
		var color: Color = Color.GREEN if dir == _draw_params["chosen_dir"] else Color.RED
		
		draw_line(from, to, color)
		draw_circle(to, 2, color)


#region Public Methods
func die():
	current_state = State.DEAD
	GameEvents.ghost_eaten.emit(self)


func reset():
	if _home_tween:
		_home_tween.kill()
	
	_already_left_home = false
	_can_move = true
	animated_sprite.play("move_down")
	_force_direction(Vector2.ZERO)
	current_state = initial_state
	if current_state != State.HOME:
		var entrance: Node2D = get_tree().get_first_node_in_group("entrance") as Node2D
		global_position = entrance.global_position
#endregion

#region Private Methods
func _set_is_active(value: bool):
	if value:
		animated_sprite.play()
	else:
		animated_sprite.pause()
	
	is_active = value
	
	if !_home_tween or !_home_tween.is_valid():
		return
	
	if value and !_home_tween.is_running() and !_home_tween.is_valid():
		_home_tween.play()
	elif !value and _home_tween.is_running():
		_home_tween.pause()


func _set_state(new_state: State):
	# prevents same state transitions
	# unless transitioning to HOME state because otherwise the Ghost will 
	# become unable to move if reset while on it's exit animation
	if new_state == current_state and current_state != State.HOME:
		return
	
	# enter new state
	match new_state:
		State.HOME:
			if _home_node:
				global_position = _home_node.global_position
			_force_direction(Vector2.DOWN)
			_can_move = false
			Callable(_try_leaving_home).call_deferred()
		State.SCARED:
			_current_move_speed = SCARED_MOVE_SPEED
		State.DEAD:
			_current_move_speed = DEAD_MOVE_SPEED
			_play_death_sound()
	
	if new_state != State.SCARED and new_state != State.DEAD:
		_current_move_speed = NORMAL_MOVE_SPEED
	
	var prev_state = current_state
	current_state = new_state
	
	_print_state_debug_info(new_state)
	
	# prevents the ghost from turning around
	if prev_state == State.HOME or new_state == State.HOME:
		return
	_turn_around()


func _try_leaving_home() -> void:
	if current_state != State.HOME:
		return
	
	if Globals.current_level.pills_eaten >= pills_required:
		if !_already_left_home and home_exit_delay > 0.0:
			home_exit_timer.start()
			_already_left_home = true
			await home_exit_timer.timeout
		
		await _exit_home().finished
		current_state = _queue_state


func _play_death_sound() -> void:
	eaten_sound.play()


func _turn_around():
	_force_direction(_current_direction * -1)
	# TODO - explain these lines
	var intersections = intersection_collider.get_overlapping_areas()
	if intersections.size() > 0:
		_on_intersection_collider_area_entered(intersections[0])


func _force_direction(direction: Vector2):
	_next_direction = direction
	_current_direction = direction


func _handle_animation():
	if current_state == State.SCARED:
		animated_sprite.play("scared")
		
		var scare_timer: Timer = Globals.ghost_manager.scare_timer
		if !scare_timer.is_stopped() and scare_timer.time_left <= 3.0:
			_start_blink()
		else: 
			_stop_blink()
		
		return
	
	_stop_blink()
	
	var anim_prefix = "move" if current_state != State.DEAD else "dead"
	var anim_suffix = "down"
	
	if _current_direction.x == -1:
		anim_suffix = "left"
	elif _current_direction.x == 1:
		anim_suffix = "right"
	elif _current_direction.y == -1:
		anim_suffix = "up"
	
	animated_sprite.play("{0}_{1}".format([anim_prefix, anim_suffix]))
#endregion

#region Pathfinding Methods
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


func _get_available_directions(node: Node2D) -> Array[Vector2]:
	var directions: Array[Vector2] = [Vector2.UP, Vector2.LEFT, Vector2.DOWN, Vector2.RIGHT]
	var result = directions.filter(func(dir):
		return Utils.is_direction_free(
				node, 
				_current_move_speed, 
				_shape_query, 
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
		var distance_from_current = (global_position + dir).distance_squared_to(_target_position)
		var distance_from_chosen = (global_position + chosen_direction).distance_squared_to(_target_position)
		
		if distance_from_current < distance_from_chosen or chosen_direction == Vector2.ZERO:
			chosen_direction = dir
	
	return chosen_direction


func _choose_next_direction(node: Node2D) -> void:
	_target_position = _get_target_position()
	
	var available_directions = _get_available_directions(node).filter(func(dir):
		# exclude the direction opposite to the current one
		return dir != _current_direction * -1
	)
	
	_next_direction = (
			_get_best_direction(available_directions) if current_state != State.SCARED
			else available_directions.pick_random()
	)
	
	# DEBUG INFORMATION
	_draw_params["pivot"] = node
	_print_pathfinding_debug_info(available_directions, _next_direction)
#endregion

#region Tween Animation Methods
func _exit_home() -> Tween:
	# 0. Get nodes
	var entrance = get_tree().get_first_node_in_group("entrance") as Node2D
	var center = get_tree().get_first_node_in_group("home_center") as Node2D
	
	# 1. Move to center
	_home_tween = create_tween()
	
	if _home_node != center:
		var home_to_center_duration: float = center.global_position.distance_to(_home_node.global_position) / _current_move_speed
		_home_tween.tween_property(self, "global_position", center.global_position, home_to_center_duration)\
				.from(_home_node.global_position)
		var face_dir = Vector2.RIGHT if home_position_group == "home_left" else Vector2.LEFT
		_home_tween.parallel().tween_callback(_force_direction.bind(face_dir))
	
	# 2. Move outside
	var center_to_entrance_duration: float = entrance.global_position.distance_to(center.global_position) / _current_move_speed
	_home_tween.tween_property(self, "global_position", entrance.global_position, center_to_entrance_duration)\
			.from(center.global_position)
	_home_tween.parallel().tween_callback(_force_direction.bind(Vector2.UP))
	
	# 3. Choose move direction
	_home_tween.tween_callback(_choose_next_direction.bind(entrance))
	
	# 4. Re-enable movement
	_home_tween.tween_property(self, "_can_move", true, 0)
	
	return _home_tween


func _enter_home() -> Tween:
	# 0. Disable regular movement
	_can_move = false
	
	# 1. Get the necessary nodes
	var entrance = get_tree().get_first_node_in_group("entrance") as Node2D
	var center = get_tree().get_first_node_in_group("home_center") as Node2D
	
	# 2. Tween ghost position to entrance
	_home_tween = create_tween()
	
	var ghost_to_entrance_duration: float = global_position.distance_to(entrance.global_position) / _current_move_speed
	_home_tween.tween_property(self, "global_position", entrance.global_position, ghost_to_entrance_duration)
	
	# 3. Move from entrance to center of home
	var entrance_to_center_duration: float = entrance.global_position.distance_to(center.global_position) / _current_move_speed
	_home_tween.tween_property(self, "global_position", center.global_position, entrance_to_center_duration)\
			.from(entrance.global_position)
	_home_tween.parallel().tween_callback(_force_direction.bind(Vector2.DOWN))
	
	# 4. Move from center to home position
	if _home_node != center:
		var center_to_home_duration: float = center.global_position.distance_to(_home_node.global_position) / _current_move_speed
		_home_tween.tween_property(self, "global_position", _home_node.global_position, center_to_home_duration)\
				.from(center.global_position)
		var face_dir = Vector2.LEFT if home_position_group == "home_left" else Vector2.RIGHT
		_home_tween.parallel().tween_callback(_force_direction.bind(face_dir))
	
	return _home_tween


func _start_blink() -> void:
	if _blink_tween and _blink_tween.is_running():
		return
	
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_property(animated_sprite, "visible", false, 0.0).from(true).set_delay(0.1)
	_blink_tween.tween_property(animated_sprite, "visible", true, 0.0).set_delay(0.1)


func _stop_blink() -> void:
	if !_blink_tween:
		return
	if !_blink_tween.is_running():
		return
	
	_blink_tween.kill()
	animated_sprite.show()
#endregion

#region Signal Callables
func _on_intersection_collider_area_entered(area: Area2D):
	if current_state == State.HOME:
		return
	
	if area.is_in_group("intersection_node"):
		_choose_next_direction(area)
	elif area.is_in_group("entrance") && current_state == State.DEAD:
		await _enter_home().finished
		current_state = _queue_state
		GameEvents.ghost_reformed.emit()
		await _exit_home().finished


func _on_pill_collected():
	if current_state != State.HOME:
		return
	
	if Globals.current_level.pills_eaten == pills_required:
		await _exit_home().finished
		current_state = _queue_state


func _on_global_ghost_state_updated(global_state: Ghost.State, scared_mode: bool):
	_queue_state = global_state
	if current_state != State.DEAD and current_state != State.HOME:
		current_state = global_state if not scared_mode else State.SCARED
#endregion

#region Debug Methods
func _print_pathfinding_debug_info(available_directions: Array[Vector2], chosen_direction: Vector2):
	if !OS.is_debug_build():
		return
	
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
	
	_draw_params["chosen_dir"] = chosen_direction
	_draw_params["available_dir"] = available_directions
	
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
	if !OS.is_debug_build():
		return
	
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
#endregion
