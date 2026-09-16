class_name DogController
extends CharacterBody2D
## Dog movement and facing only.
## Must NOT own run timer, loot, save, stash or extraction state.

@export var move_speed: float = 240.0
@export var acceleration: float = 2000.0
@export var friction: float = 2400.0

## Last non-zero movement direction (normalized).
var facing: Vector2 = Vector2.RIGHT

@onready var _visual: Node2D = $Visual


func _physics_process(delta: float) -> void:
	# Keyboard and the mobile joystick both feed the same Input Map actions.
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var rate := acceleration if direction != Vector2.ZERO else friction
	velocity = velocity.move_toward(direction * move_speed, rate * delta)
	move_and_slide()
	_update_facing(direction)


func _update_facing(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return
	facing = direction.normalized()
	if not is_zero_approx(direction.x):
		_visual.scale.x = signf(direction.x)
