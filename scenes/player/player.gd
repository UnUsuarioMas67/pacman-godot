extends CharacterBody2D

const MOVE_SPEED := 76.0

@export var is_invincible := false

var current_direction := Vector2.ZERO
var next_direction := Vector2.ZERO
var shape_query := PhysicsShapeQueryParameters2D.new()
var is_dead := false
var is_active := true : set = _set_is_active

@onready var collision_shape = $CollisionShape2D
@onready var animated_sprite = $AnimatedSprite2D
@onready var hurtbox = $Hurtbox
@onready var hurtbox_shape = $Hurtbox/CollisionShape2D


func _ready():
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	shape_query.collision_mask = collision_mask
	shape_query.shape = collision_shape.shape


func _physics_process(delta):
	if is_dead or !is_active:
		return
	
	_get_next_direction()
	
	if Utils.is_direction_free(self, MOVE_SPEED, shape_query, next_direction, delta):
		current_direction = next_direction
	
	_handle_animation(delta)
	
	velocity = MOVE_SPEED * current_direction
	move_and_slide()


func die():
	is_dead = true
	animated_sprite.play("death")
	animated_sprite.rotation = 0
	Callable(func (): hurtbox_shape.disabled = true).call_deferred()
	
	GameEvents.player_died.emit()


func _set_is_active(value: bool):
	if !value:
		animated_sprite.pause()
	
	is_active = value


func _handle_animation(delta):
	if is_on_wall() or current_direction == Vector2.ZERO:
		animated_sprite.pause()
	else:
		animated_sprite.play("default")
	
	if current_direction != Vector2.ZERO:
		animated_sprite.rotation = current_direction.angle()


func _get_next_direction():
	if Input.is_action_pressed("move_right"):
		next_direction = Vector2.RIGHT
	elif Input.is_action_pressed("move_down"):
		next_direction = Vector2.DOWN
	elif Input.is_action_pressed("move_left"):
		next_direction = Vector2.LEFT
	elif Input.is_action_pressed("move_up"):
		next_direction = Vector2.UP


func _on_hurtbox_area_entered(area: Area2D):
	if !area.owner.is_in_group("ghost"):
		return
	
	if area.owner.current_state == 2:  # SCARED
		area.owner.die()
		return
	elif area.owner.current_state == 4 or is_invincible:  # DEAD
		return
	
	die()
