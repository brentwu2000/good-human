class_name DogController3D
extends CharacterBody3D
## 3D player dog: movement relative to the camera (so the top-down and the
## dog-height views share one rule: "up = where the camera looks"), facing,
## choosing the nearest Interactable3D and emitting the interact intent.
## Must NOT own run timer, loot, save, stash or extraction state.

signal focus_changed(target: Node)
signal interact_requested(target: Node)

@export var walk_speed: float = 3.5
@export var sprint_speed: float = 6.2
@export var acceleration: float = 18.0
## A fully pushed joystick also sprints (mobile has no sprint key).
@export var stick_sprint_threshold: float = 0.95
@export var detect_radius: float = 1.3

## Shared with the first-person view so the muzzle in frame is this dog's.
const FUR_COLOR: Color = Color(0.78, 0.55, 0.32)
## The generated shiba, rigged and animated in the character pipeline.
const MODEL_SCENE: PackedScene = preload("res://assets/characters/dog/models/shiba_01/shiba_01.glb")
## The export faces +Z; every actor in this game faces -Z.
const MODEL_YAW: float = PI

## Camera yaw in radians, set by CameraRig3D. 0 = forward is -Z.
var camera_yaw: float = 0.0
var facing: Vector3 = Vector3.FORWARD
## Passed to Interactable3D.can_interact(); set by RunManager.
var interaction_context: Object
var focused: Interactable3D

## Muzzle and ears in frame while the camera is inside this dog's head. Built
## and parented by CameraRig3D, which owns the camera it hangs from.
var first_person_view: DogFirstPersonView3D

var _visual: Node3D
var _motion: DogModelMotion3D
var _detector: Area3D
var _bark_label: Label3D
var _bark_left: float = 0.0


func _ready() -> void:
	collision_layer = Greybox.ACTOR_LAYER
	collision_mask = Greybox.WORLD_LAYER
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.25
	capsule.height = 0.7
	shape.shape = capsule
	shape.rotation_degrees.x = 90.0
	shape.position.y = 0.3
	add_child(shape)
	# _visual is a bare pivot the facing code yaws; the model hangs off it with
	# its own fixed correction, so turning the dog stays one rotation.
	_visual = Node3D.new()
	var model := MODEL_SCENE.instantiate() as Node3D
	model.rotation.y = MODEL_YAW
	# This body's origin is not at its feet. The capsule lies on its side, so
	# what rests on the floor is `position.y - radius` above the origin, and a
	# model whose own origin is at its paws would stand that far underground.
	model.position.y = shape.position.y - capsule.radius
	_visual.add_child(model)
	add_child(_visual)
	_motion = DogModelMotion3D.new()
	add_child(_motion)
	_motion.bind(model)
	_detector = Area3D.new()
	_detector.collision_layer = 0
	_detector.collision_mask = Greybox.INTERACTABLE_LAYER
	_detector.monitorable = false
	var detect_shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = detect_radius
	detect_shape.shape = sphere
	_detector.add_child(detect_shape)
	add_child(_detector)
	_bark_label = Greybox.label("", 1.1, 44, Color(1.0, 0.95, 0.6))
	add_child(_bark_label)


func _physics_process(delta: float) -> void:
	_bark_left -= delta
	if _bark_left <= 0.0:
		_bark_label.text = ""
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, camera_yaw)
	var sprinting := Input.is_action_pressed("sprint") or input.length() >= stick_sprint_threshold
	var speed := (sprint_speed if sprinting else walk_speed) * minf(input.length(), 1.0)
	var target := direction.normalized() * speed if direction.length() > 0.01 else Vector3.ZERO
	var planar := Vector3(velocity.x, 0.0, velocity.z).move_toward(target, acceleration * delta)
	velocity = Vector3(planar.x, velocity.y - 9.8 * delta, planar.z)
	move_and_slide()
	if is_on_floor():
		velocity.y = 0.0
	if planar.length() > 0.2:
		facing = planar.normalized()
		_visual.rotation.y = lerp_angle(_visual.rotation.y, heading(), minf(delta * 12.0, 1.0))
	_motion.update_motion(delta, planar.length(), sprinting)
	_update_focus()
	if focused != null and Input.is_action_just_pressed("interact"):
		_motion.play_sniff()
		interact_requested.emit(focused)


## P03-E04: while the camera is inside the dog's head, its own body would fill
## the lens. The collision shape and every rule are untouched — this hides a
## mesh, nothing else.
func set_first_person(value: bool) -> void:
	if _visual != null:
		_visual.visible = not value
	if first_person_view != null:
		first_person_view.visible = value


## A hand has landed on this dog's head.
func play_petted() -> void:
	if first_person_view != null:
		first_person_view.play_petted()


## Where the camera sits when it is looking through this dog's eyes: eye height,
## a little forward of centre.
func eye_position() -> Vector3:
	return global_position + Vector3(0, 0.42, 0) + facing * 0.18


## Bark body language (DogAgency decides what it does).
func play_bark() -> void:
	_bark_label.text = "汪！"
	_bark_left = 0.7
	var tween := create_tween()
	tween.tween_property(_visual, "position:y", 0.12, 0.06)
	tween.tween_property(_visual, "position:y", 0.0, 0.12)


## Yaw the dog is facing (0 = -Z).
func heading() -> float:
	return atan2(-facing.x, -facing.z)


func planar_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


func collar_position() -> Vector3:
	return global_position + Vector3(0, 0.5, 0) - facing * 0.25


func _update_focus() -> void:
	var best: Interactable3D = null
	var best_distance := INF
	for area in _detector.get_overlapping_areas():
		var interaction_area := area as InteractionArea3D
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
