class_name DogController
extends CharacterBody2D
## Dog movement, facing, choosing the best nearby Interactable and emitting
## the interact intent. Must NOT own run timer, loot, save, stash or extraction state.

signal focus_changed(target: Interactable)
signal interact_requested(target: Interactable)

@export var move_speed: float = 240.0
@export var acceleration: float = 2000.0
@export var friction: float = 2400.0

## Last non-zero movement direction (normalized).
var facing: Vector2 = Vector2.RIGHT
## Passed to Interactable.can_interact(); set by the run (RunManager).
var interaction_context: Object
var focused: Interactable

@onready var _visual: Node2D = $Visual
@onready var _detector: Area2D = $InteractionDetector


func _physics_process(delta: float) -> void:
	# Keyboard and the mobile joystick both feed the same Input Map actions.
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var rate := acceleration if direction != Vector2.ZERO else friction
	velocity = velocity.move_toward(direction * move_speed, rate * delta)
	move_and_slide()
	_update_facing(direction)
	_update_focus()
	if focused != null and Input.is_action_just_pressed("interact"):
		interact_requested.emit(focused)


func _update_facing(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return
	facing = direction.normalized()
	if not is_zero_approx(direction.x):
		_visual.scale.x = signf(direction.x)


## Nearest Interactable in range that currently accepts interaction.
func _update_focus() -> void:
	var best: Interactable = null
	var best_distance := INF
	for area in _detector.get_overlapping_areas():
		var interaction_area := area as InteractionArea
		if interaction_area == null or interaction_area.interactable == null:
			continue
		var candidate := interaction_area.interactable
		if not candidate.can_interact(interaction_context):
			continue
		var distance := global_position.distance_squared_to(candidate.global_position)
		if distance < best_distance:
			best = candidate
			best_distance = distance
	if best != focused:
		focused = best
		focus_changed.emit(focused)
