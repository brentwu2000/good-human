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
## Style Bible v1 proportions (tools/art/stylize_rigged.py): used when the style is on.
const STYLIZED_SCENE := "res://assets/characters/dog/models/shiba_01/shiba_01_stylized.glb"
## The export faces +Z; every actor in this game faces -Z.
const MODEL_YAW: float = PI
## How fast the dog steps out of a body it has been left inside (m/s).
const STEP_OUT_SPEED: float = 3.0
## Closer than this, centre to centre on the ground, physics has nothing to
## push by; anything further out it resolves itself (and a dog merely leaning
## on someone must not be shoved away).
const DEEP_OVERLAP: float = 0.15

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
var _contact_cooldown: float = 0.0
var _instinct_tween: Tween
var _body_shape: CollisionShape3D


func _ready() -> void:
	collision_layer = Greybox.ACTOR_LAYER
	# ADR-016: the dog is blocked by people and other dogs as well as the
	# world, and slides round them the way it slides along a wall.
	collision_mask = Greybox.WORLD_LAYER | Greybox.ACTOR_LAYER
	# Only the world is ground. Standing on a person or a dog made that body a
	# moving platform, and when it was placed somewhere new (fighters and
	# opponent dogs are positioned directly) its jump was handed on as
	# velocity and flung this body across the map (P04-09).
	platform_floor_layers = Greybox.WORLD_LAYER
	platform_wall_layers = 0
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.25
	capsule.height = 0.7
	shape.shape = capsule
	shape.rotation_degrees.x = 90.0
	shape.position.y = 0.3
	add_child(shape)
	_body_shape = shape
	# _visual is a bare pivot the facing code yaws; the model hangs off it with
	# its own fixed correction, so turning the dog stays one rotation.
	_visual = Node3D.new()
	# Sprint 06: the save's own dog, as the breed it was at the shelter.
	var model := DogVisual3D.model_for(Game.pair_state.dog if Game.has_pair() else null)
	model.rotation.y = MODEL_YAW
	# S06-07: an energetic dog sprints harder.
	sprint_speed *= Game.dog_talent(&"energy")
	# This body's origin is not at its feet. The capsule lies on its side, so
	# what rests on the floor is `position.y - radius` above the origin, and a
	# model whose own origin is at its paws would stand that far underground.
	model.position.y = shape.position.y - capsule.radius
	_visual.add_child(model)
	add_child(_visual)
	SoftToon.register(_visual)
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
	_step_out_of_bodies(delta)
	_report_contacts(planar, delta)
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


## The nose down at something (S05-05: reading a place's scents).
func play_sniff() -> void:
	_motion.play_sniff()


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


## D4/P02-009: the dog's own read of danger to its owner, shown in its body.
## THREAT (a heavy blow winding up at the owner): head down and forward, a
## growl. WORRY (the owner in a bad way): head low, a whine. The captions stand
## in for sound, like the bark's, while the project has no audio. In first
## person the ears and muzzle in frame carry it instead.
func set_instinct(instinct: int) -> void:
	if _instinct_tween != null:
		_instinct_tween.kill()
	_instinct_tween = create_tween()
	var tilt := 0.0
	match instinct:
		DogInstinct.Instinct.THREAT:
			tilt = -0.12
			_show_caption("grr", 0.7)
		DogInstinct.Instinct.WORRY:
			tilt = -0.07
			_show_caption("嗚…", 0.9)
	_instinct_tween.tween_property(_visual, "rotation:x", tilt, 0.15).set_trans(Tween.TRANS_SINE)
	if first_person_view != null:
		first_person_view.set_instinct(instinct)


func _show_caption(text: String, seconds: float) -> void:
	_bark_label.text = text
	_bark_left = seconds


## Yaw the dog is facing (0 = -Z).
func heading() -> float:
	return atan2(-facing.x, -facing.z)


func planar_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


func collar_position() -> Vector3:
	return global_position + Vector3(0, 0.5, 0) - facing * 0.25


## P04-08: physics pushes the dog out of a body it partly overlaps, but not
## out of one it sits dead centre in (there is no direction to push). A
## fighter can be placed right on top of the dog, so the dog steps out itself,
## away from the body's centre, or backwards when it has none to go by.
func _step_out_of_bodies(delta: float) -> void:
	var space := get_world_3d().direct_space_state
	if space == null or _body_shape == null:
		return
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _body_shape.shape
	query.transform = global_transform * _body_shape.transform
	query.collision_mask = Greybox.ACTOR_LAYER
	query.exclude = [get_rid()]
	for hit in space.intersect_shape(query, 4):
		var body := hit.collider as Node3D
		if body == null:
			continue
		var away := global_position - body.global_position
		away.y = 0.0
		if away.length() >= DEEP_OVERLAP:
			continue
		if away.length_squared() < 0.0004:
			away = -facing
		global_position += away.normalized() * STEP_OUT_SPEED * delta


## ADR-016: running into someone is felt. The body answers with a small
## balance or look reaction (it decides which); a slow brush is just blocked.
## `approach` is the velocity the dog was trying to move at this frame.
func _report_contacts(approach: Vector3, delta: float) -> void:
	_contact_cooldown -= delta
	var presence := DataRegistry.presence
	if _contact_cooldown > 0.0 or presence == null:
		return
	for i in get_slide_collision_count():
		var hit := get_slide_collision(i)
		var body := hit.get_collider()
		if body == null or not body.has_method(&"receive_dog_contact"):
			continue
		var into := -hit.get_normal()
		into.y = 0.0
		if into.length_squared() < 0.0001:
			continue
		var speed := approach.dot(into.normalized())
		if speed >= presence.fast_dog_contact_speed:
			body.call(&"receive_dog_contact", global_position, speed)
			_contact_cooldown = presence.contact_cooldown
			return


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
