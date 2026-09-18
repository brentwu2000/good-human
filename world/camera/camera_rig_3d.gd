class_name CameraRig3D
extends Node3D
## Production camera (ADR-010): a low chase camera behind the dog (the P-01
## "B" framing). Pivot + boom with smoothing. Walls pull the camera in, and
## anything too close, the owner or foliage that hides the dog fades out.
## Fights pull the camera back to frame both humans. Framing never changes
## gameplay.
## Turning: while the dog runs, the camera eases round behind it in whatever
## direction it goes (push right → dog turns right → view turns right).
## The stick answers the view it was pushed against, then its frame follows the
## turning view at its own slower rate, so holding a direction keeps curving
## that way instead of locking into a straight line, while the two rates
## together settle into a steady turn rather than a spin.
## Players can also turn the camera by dragging on the right side of the
## screen, right mouse drag, or the arrow keys.

const FRAMING: Dictionary = {"pivot": 0.8, "pitch": -9.0, "distance": 2.8, "fov": 70.0}
## Pulled back to keep the dog and both humans in view during a fight.
const COMBAT_FRAMING: Dictionary = {"pivot": 1.4, "pitch": -28.0, "distance": 7.5, "fov": 64.0}

@export var smoothing: float = 6.0
## Auto-follow rate at full speed (per second, exponential).
@export var follow_rate: float = 2.4
## Share of the follow rate kept when the dog runs back towards the camera.
@export var backward_follow_share: float = 0.35
## Arrow keys (rad/s).
@export var manual_turn_speed: float = 2.4
## Screen drag (rad per pixel).
@export var drag_turn_sensitivity: float = 0.006
## Auto-follow waits this long after a manual turn.
@export var manual_hold_seconds: float = 1.5
## How fast the stick's control frame follows the turning view (per second,
## exponential). Together with `follow_rate` this sets how tightly a held
## direction curves: lower is straighter, higher turns harder.
@export var control_follow_rate: float = 1.2
@export var collision_margin: float = 0.25
## A wall may pull the camera in down to this distance; anything closer fades
## instead, so the camera stays low behind the dog.
@export var collision_min_distance: float = 1.2

var dog: DogController3D
var owner_actor: HumanFollower3D
var coordinator: CombatCoordinator3D
var yaw: float = 0.0
var current: Dictionary = {}
var collided: bool = false

var camera: Camera3D
var _focus: Vector3
var _faded: Dictionary[Node, bool] = {}
var _manual_hold: float = 0.0
## Control frame for the stick (see header).
var _control_yaw: float = 0.0
var _stick_held: bool = false
var _stick_angle: float = 0.0
## Steering the stick further than this (deg) re-aims it at the current view.
@export var relatch_angle: float = 45.0


func _ready() -> void:
	top_level = true
	camera = Camera3D.new()
	camera.current = true
	add_child(camera)


## Places the camera straight behind the dog's current heading.
func snap_behind_dog() -> void:
	yaw = dog.heading()
	_control_yaw = yaw
	snap()


func snap() -> void:
	current.clear()
	_update(1.0, true)


func is_combat_framing() -> bool:
	return coordinator != null and coordinator.is_fighting()


func _physics_process(delta: float) -> void:
	if dog == null:
		return
	_update(delta, false)


func _update(delta: float, instant: bool) -> void:
	var target: Dictionary = COMBAT_FRAMING if is_combat_framing() else FRAMING
	var t := 1.0 if instant or current.is_empty() else 1.0 - exp(-smoothing * delta)
	if current.is_empty():
		current = target.duplicate()
	for key: String in ["pivot", "pitch", "distance", "fov"]:
		current[key] = lerpf(current[key], target[key], t)

	if not instant:
		_update_yaw(delta)
	_update_control_frame(delta, instant)

	var focus := dog.global_position + Vector3(0, current["pivot"], 0)
	if is_combat_framing():
		var fight := (owner_actor.global_position + coordinator.pair.human_global_position()) / 2.0
		focus = focus.lerp(fight + Vector3(0, current["pivot"], 0), 0.5)
	_focus = focus if instant or _focus == Vector3.ZERO else _focus.lerp(focus, t)

	var pitch := deg_to_rad(current["pitch"])
	var boom: Vector3 = Vector3(0, -sin(pitch), cos(pitch)).rotated(Vector3.UP, yaw) * float(current["distance"])
	var desired: Vector3 = _focus + boom
	global_position = _place_camera(_focus, desired)
	if global_position.distance_to(_focus) > 0.01:
		look_at(_focus, Vector3.UP)
	camera.fov = current["fov"]
	_update_owner_fade()


func _update_yaw(delta: float) -> void:
	var turn := Input.get_axis("camera_turn_left", "camera_turn_right")
	if turn != 0.0:
		yaw -= turn * manual_turn_speed * delta
		_manual_hold = manual_hold_seconds
	_manual_hold -= delta
	if _manual_hold > 0.0 or dog.planar_speed() < 0.3:
		return
	yaw = lerp_angle(yaw, dog.heading(), 1.0 - exp(-follow_rate * follow_weight() * delta))


## 0..1: how strongly the camera should ease behind the dog right now:
## by speed, a bit gentler when the dog runs back towards the camera.
func follow_weight() -> float:
	var speed := clampf(dog.planar_speed() / dog.walk_speed, 0.0, 1.0)
	var facing_away := (1.0 + cos(angle_difference(yaw, dog.heading()))) * 0.5
	return speed * lerpf(backward_follow_share, 1.0, facing_away)


## Pushing the stick, re-aiming it further than `relatch_angle` or releasing it
## reads it against the view as it is right now, so the dog sets off exactly
## where the player pointed. Held, the frame then follows the turning view at
## `control_follow_rate` — slower than the view follows the dog — so keeping the
## stick up-left keeps curving left instead of straightening out after the first
## turn, and the two rates settle into a steady arc rather than a spin.
func _update_control_frame(delta: float, instant: bool) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var held := input.length() >= 0.1
	var angle := input.angle()
	if instant or not held or not _stick_held or absf(rad_to_deg(angle_difference(_stick_angle, angle))) > relatch_angle:
		_control_yaw = yaw
		_stick_angle = angle
	else:
		_control_yaw = lerp_angle(_control_yaw, yaw, 1.0 - exp(-control_follow_rate * delta))
	_stick_held = held
	dog.camera_yaw = _control_yaw


## Drag on the right side of the screen (the joystick owns the left side).
func _unhandled_input(event: InputEvent) -> void:
	var relative_x := 0.0
	var drag := event as InputEventScreenDrag
	if drag != null and drag.position.x > get_viewport().get_visible_rect().size.x * 0.45:
		relative_x = drag.relative.x
	var motion := event as InputEventMouseMotion
	if motion != null and motion.button_mask & MOUSE_BUTTON_MASK_RIGHT:
		relative_x = motion.relative.x
	if relative_x != 0.0:
		yaw -= relative_x * drag_turn_sensitivity
		_manual_hold = manual_hold_seconds


## Walls pull the camera in; fade-group occluders and too-close walls fade.
func _place_camera(from: Vector3, to: Vector3) -> Vector3:
	var space := get_world_3d().direct_space_state
	var exclude: Array[RID] = []
	var fade_now: Dictionary[Node, bool] = {}
	var result := to
	collided = false
	for i in 6:
		var query := PhysicsRayQueryParameters3D.create(from, to, Greybox.WORLD_LAYER, exclude)
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			break
		var body := hit["collider"] as Node
		var point: Vector3 = hit["position"]
		var pulled := point + (from - point).normalized() * collision_margin
		if body.is_in_group(Greybox.FADE_GROUP) or pulled.distance_to(from) < collision_min_distance:
			fade_now[body] = true
			exclude.append(hit["rid"])
			continue
		collided = true
		result = pulled
		break
	for body in _faded.keys():
		if not fade_now.has(body) and is_instance_valid(body):
			Greybox.set_faded(body, false)
	for body in fade_now:
		if not _faded.has(body):
			Greybox.set_faded(body, true)
	_faded = fade_now
	return result


## The leashed owner walks behind the dog, right where the camera looks.
func _update_owner_fade() -> void:
	if owner_actor == null:
		return
	var from := camera.global_position
	var to := dog.global_position + Vector3(0, 0.4, 0)
	var body := owner_actor.global_position + Vector3(0, 0.9, 0)
	var segment := to - from
	var t := clampf((body - from).dot(segment) / maxf(segment.length_squared(), 0.001), 0.0, 1.0)
	var closest := from + segment * t
	var blocking := t > 0.05 and t < 0.95 and Vector2(body.x - closest.x, body.z - closest.z).length() < 0.6
	owner_actor.set_faded(blocking)


func is_dog_visible() -> bool:
	return camera.is_position_in_frustum(dog.global_position + Vector3(0, 0.4, 0))
