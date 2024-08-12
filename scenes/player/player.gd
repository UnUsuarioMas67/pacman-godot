extends CharacterBody2D

const MOVE_SPEED := 76.0

@export var is_invincible := false

var current_direction := Vector2.ZERO
var next_direction := Vector2.ZERO
var shape_query := PhysicsShapeQueryParameters2D.new()
var is_dead := false
var is_active := true : set = _set_is_active
var _eat_sound1_played := false

@onready var collision_shape = $CollisionShape2D
@onready var animated_sprite = $AnimatedSprite2D
@onready var hurtbox = $Hurtbox
@onready var hurtbox_shape = $Hurtbox/CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# SFX
@onready var eat_sound1: AudioStreamPlayer = $Sounds/EatSound1
@onready var eat_sound2: AudioStreamPlayer = $Sounds/EatSound2


func _ready():
	GameEvents.pill_collected.connect(_on_pill_collected)
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	shape_query.collision_mask = collision_mask
	shape_query.shape = collision_shape.shape
	
	animation_player.play("RESET")


func _physics_process(delta):
	if is_dead or !is_active:
		return
	
	_get_next_direction()
	
	if Utils.is_direction_free(self, MOVE_SPEED, shape_query, next_direction, delta):
		current_direction = next_direction
	
	_handle_animation()
	
	velocity = MOVE_SPEED * current_direction
	move_and_slide()


func die():
	is_dead = true
	animation_player.play("death")


func _emit_player_death_started():
	GameEvents.player_death_started.emit()


func _emit_player_death_finished():
	GameEvents.player_death_finished.emit()


func _set_is_active(value: bool):
	if !value:
		animated_sprite.pause()
	
	is_active = value


func _handle_animation():
	var ray_query := PhysicsRayQueryParameters2D.create(
			global_position,
			global_position + ((collision_shape.shape.size.x) * current_direction),
			collision_mask
	)
	var result := get_world_2d().direct_space_state.intersect_ray(ray_query)
	
	if result.size() > 0 or current_direction == Vector2.ZERO:
		animation_player.pause()
	else:
		animation_player.play("move")
	
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


func _on_pill_collected():
	if not _eat_sound1_played:
		eat_sound1.play()
		_eat_sound1_played = true
		return
	else:
		eat_sound2.play()
		_eat_sound1_played = false
