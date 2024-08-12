extends CharacterBody2D
class_name Ghost

enum State {
	CHASE = 0,
	SCATTER = 1,
	SCARED = 2,
	IDLE = 3,
	DEAD = 4,
	TEST = 5,
}

const STATE_COLORS := [
	Color.RED, # CHASE
	Color.ORANGE, # SCATTER
	Color.BLUE, # SCARED
	Color.GREEN, # IDLE
	Color.GRAY, # DEAD
	Color.WHEAT # TEST
]
const IDLE_DURATION := 5.0
const NORMAL_MOVE_SPEED := 55.0
const SLOW_MOVE_SPEED := 34.0
const DEAD_MOVE_SPEED := 120.0

@export var initial_state: State
@export var scatter_node: PathFollow2D
@export var respawn_node: Marker2D

var current_state: State : set = _set_state
var queue_state: State
var is_active := true : set = _set_is_active
var move_speed := NORMAL_MOVE_SPEED
var direction := Vector2.ZERO
var player: Node2D

@onready var navigation_agent = $NavigationAgent2D
@onready var nav_update_timer = $NavUpdateTimer
@onready var hurtbox_collision = $Hurtbox/CollisionShape2D
@onready var color_rect = $ColorRect
@onready var animated_sprite = $AnimatedSprite2D


func _ready():
	GameEvents.thirty_pills_collected.connect(_on_thirty_pills_collected)
	nav_update_timer.timeout.connect(_update_nav)
	navigation_agent.target_reached.connect(_on_navigation_target_reached)
	
	current_state = initial_state


func _physics_process(delta):
	if !is_active:
		return
	
	if current_state != State.IDLE:
		var next_position = navigation_agent.get_next_path_position()
		direction = global_position.direction_to(next_position)
	
	velocity = move_speed * direction
	move_and_slide()
	_handle_animation()
	
	if current_state == State.IDLE and is_on_wall():
		direction.y *= -1


func _input(event):
	if current_state != State.TEST:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			navigation_agent.target_position = event.position


func _set_is_active(value: bool):
	if value:
		show()
	else:
		hide()
	
	is_active = value


func die():
	current_state = State.DEAD


func _set_state(new_state: State):
	if new_state == current_state or current_state == State.TEST:
		return
	
	# exit previous state
	match current_state:
		State.CHASE, State.SCATTER:
			nav_update_timer.stop()
		State.DEAD:
			move_speed = NORMAL_MOVE_SPEED
			Callable(func (): hurtbox_collision.disabled = false).call_deferred()
	
	# enter new state
	match new_state:
		State.CHASE, State.SCATTER:
			move_speed = NORMAL_MOVE_SPEED
			nav_update_timer.start()
		State.IDLE:
			direction = Vector2.UP
			move_speed = SLOW_MOVE_SPEED
		State.SCARED:
			if !player:
				player = Globals.get_player_node()
			
			_update_scared_position()
			move_speed = SLOW_MOVE_SPEED
		State.DEAD:
			_update_dead_position()
			
			move_speed = DEAD_MOVE_SPEED
			Callable(func (): hurtbox_collision.disabled = true).call_deferred()
	
	current_state = new_state
	color_rect.color = STATE_COLORS[current_state]


func _handle_animation():
	if current_state == State.SCARED:
		animated_sprite.play("scared")
		return
	
	var anim_prefix = "move" if current_state != State.DEAD else "dead"
	var anim_suffix = "left"
	
	if round(direction.y) == 1:
		anim_suffix = "down"
	elif round(direction.x) == 1:
		anim_suffix = "right"
	elif round(direction.y) == -1:
		anim_suffix = "up"
	
	animated_sprite.play("{0}_{1}".format([anim_prefix, anim_suffix]))


func _update_chase_position():
	navigation_agent.target_position = player.global_position


func _update_scatter_position():
	navigation_agent.target_position = scatter_node.global_position


func _update_scared_position():
	var panic_points = get_tree().get_nodes_in_group("panic_point") as Array[Node2D]
	var filtered_points = panic_points.filter(
		func (point: Node2D):
			# filter out points that are within a certain distance from the player
			var far_from_player := point.global_position.distance_to(player.global_position) > 64
			# also filter out points that are too close to the ghost
			# to prevent picking the same point twice in a row
			var not_too_close_to_ghost := point.global_position.distance_to(global_position) > 24
			
			return far_from_player and not_too_close_to_ghost
	)
	
	navigation_agent.target_position = filtered_points.pick_random().global_position


func _update_dead_position():
	navigation_agent.target_position = respawn_node.global_position


func _update_nav():
	match current_state:
		State.CHASE:
			if !player:
				player = Globals.get_player_node()
			_update_chase_position()
		State.SCATTER:
			if !scatter_node:
				current_state = State.CHASE
			_update_scatter_position()


func _on_navigation_target_reached():
	match current_state:
		State.SCARED:
			_update_scared_position()
		State.DEAD:
			current_state = queue_state


func _on_thirty_pills_collected():
	if current_state == State.IDLE:
		current_state = queue_state
		print('30 pills have been eaten. Leaving IDLE state')
