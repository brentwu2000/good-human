class_name ProtoCameraRig
extends Node3D
## P-01 camera rig: pivot + boom + Camera3D with smoothing and collision.
## A = current 3/4 top-down, B = low dog-height chase, C = hybrid that adapts
## framing to context (EXPLORE / SPRINT / SNIFF / COMBAT_READABILITY).
## Contexts only change framing; they are never gameplay modes.

enum Variant { A_TOP_DOWN, B_DOG_CHASE, C_HYBRID }

const VARIANT_NAMES: Array[String] = ["A 3/4 俯視", "B 狗高度追隨", "C 情境混合"]
## pivot = look height above the dog, pitch = boom angle (deg, down negative),
## distance = boom length (m), fov = vertical FOV, follow = yaw follows dog.
const PROFILES: Dictionary = {
	&"A": {"pivot": 0.5, "pitch": -58.0, "distance": 17.0, "fov": 42.0, "follow": false},
	&"B": {"pivot": 0.8, "pitch": -9.0, "distance": 2.8, "fov": 70.0, "follow": true},
	&"C_EXPLORE": {"pivot": 0.9, "pitch": -13.0, "distance": 3.4, "fov": 68.0, "follow": true},
	&"C_SPRINT": {"pivot": 1.2, "pitch": -18.0, "distance": 5.0, "fov": 76.0, "follow": true},
	&"C_SNIFF": {"pivot": 0.45, "pitch": -24.0, "distance": 2.0, "fov": 60.0, "follow": true},
	&"C_COMBAT_READABILITY": {"pivot": 1.4, "pitch": -30.0, "distance": 8.0, "fov": 62.0, "follow": true},
}
const SPRINT_SPEED_RATIO: float = 1.25

@export var variant: Variant = Variant.C_HYBRID
## Higher = snappier (per second).
@export var smoothing: float = 6.0
@export var yaw_follow_speed: float = 2.2
@export var collision_margin: float = 0.25
## When a wall pulls the camera closer than this, it rises to keep the dog in view.
@export var collision_min_distance: float = 1.8
## Fade the owner when it blocks the view of the dog (standard chase-cam fix).
@export var fade_occluding_owner: bool = true

var dog: ProtoDog
var owner_actor: ProtoOwner
var opponent: ProtoOpponent
## Runtime tuning added on top of the active profile.
var tuning: Dictionary = {"pivot": 0.0, "pitch": 0.0, "distance": 0.0, "fov": 0.0}
var context: StringName = &"EXPLORE"
var yaw: float = 0.0
## Smoothed live values.
var current: Dictionary = {}
var collided: bool = false

var camera: Camera3D
var _focus: Vector3


func _ready() -> void:
	camera = Camera3D.new()
	camera.current = true
	add_child(camera)
	top_level = true


func set_variant(value: Variant) -> void:
	variant = value
	current.clear()


func profile_key() -> StringName:
	match variant:
		Variant.A_TOP_DOWN:
			return &"A"
		Variant.B_DOG_CHASE:
			return &"B"
	return StringName("C_" + String(context))


func target_values() -> Dictionary:
	var base: Dictionary = PROFILES[profile_key()]
	var values := base.duplicate()
	for key: String in tuning:
		values[key] = float(values[key]) + float(tuning[key])
	values["distance"] = maxf(values["distance"], 0.6)
	values["fov"] = clampf(values["fov"], 25.0, 110.0)
	values["pitch"] = clampf(values["pitch"], -89.0, 20.0)
	return values


func snap() -> void:
	current.clear()
	_update(1.0, true)


func _physics_process(delta: float) -> void:
	if dog == null:
		return
	_update(delta, false)


func _update(delta: float, instant: bool) -> void:
	context = _detect_context()
	var target := target_values()
	var t := 1.0 if instant or current.is_empty() else 1.0 - exp(-smoothing * delta)
	if current.is_empty():
		current = target.duplicate()
	for key: String in ["pivot", "pitch", "distance", "fov"]:
		current[key] = lerpf(current[key], target[key], t)

	# Yaw: fixed north for A, otherwise ease behind the dog's heading.
	if not target["follow"]:
		yaw = lerp_angle(yaw, 0.0, t)
	elif dog.planar_speed() > 0.5:
		var heading := atan2(-dog.facing.x, -dog.facing.z)
		yaw = lerp_angle(yaw, heading, 1.0 if instant else minf(yaw_follow_speed * delta, 1.0))
	dog.camera_yaw = yaw

	var focus := dog.global_position + Vector3(0, current["pivot"], 0)
	if context == &"COMBAT_READABILITY" and opponent != null:
		# Keep the dog and the fight in frame.
		var fight := (owner_actor.global_position + opponent.human_position()) / 2.0
		focus = focus.lerp(fight + Vector3(0, current["pivot"], 0), 0.5)
	_focus = focus if instant or _focus == Vector3.ZERO else _focus.lerp(focus, t)

	var pitch := deg_to_rad(current["pitch"])
	var boom: Vector3 = Vector3(0, -sin(pitch), cos(pitch)).rotated(Vector3.UP, yaw) * float(current["distance"])
	var desired: Vector3 = _focus + boom
	global_position = _resolve_collision(_focus, desired)
	if global_position.distance_to(_focus) > 0.01:
		look_at(_focus, Vector3.UP)
	camera.fov = current["fov"]
	_update_owner_fade()


func _update_owner_fade() -> void:
	if owner_actor == null:
		return
	var from := camera.global_position
	var to := dog.global_position + Vector3(0, 0.4, 0)
	var body := owner_actor.global_position + Vector3(0, 0.9, 0)
	var segment := to - from
	var t := clampf((body - from).dot(segment) / maxf(segment.length_squared(), 0.001), 0.0, 1.0)
	var closest := from + segment * t
	var blocking := t > 0.05 and t < 0.95 and Vector2(body.x - closest.x, body.z - closest.z).length() < 0.6 and absf(body.y - closest.y) < 1.0
	owner_actor.set_faded(fade_occluding_owner and blocking)


func _detect_context() -> StringName:
	if variant != Variant.C_HYBRID:
		return &"FIXED"
	if opponent != null and opponent.state == ProtoOpponent.State.COMBAT:
		return &"COMBAT_READABILITY"
	if dog.sniffing:
		return &"SNIFF"
	if dog.planar_speed() > dog.walk_speed * SPRINT_SPEED_RATIO:
		return &"SPRINT"
	return &"EXPLORE"


## Pull the camera in front of walls between the focus and the camera.
func _resolve_collision(from: Vector3, to: Vector3) -> Vector3:
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	var hit := space.intersect_ray(query)
	collided = not hit.is_empty()
	if not collided:
		return to
	var point: Vector3 = hit["position"]
	var pulled := point + (from - point).normalized() * collision_margin
	var shortfall := collision_min_distance - pulled.distance_to(from)
	if shortfall > 0.0:
		# Climb up the wall instead of ending up inside the dog.
		pulled.y += shortfall * 1.5
	return pulled


func is_dog_visible() -> bool:
	return camera.is_position_in_frustum(dog.global_position + Vector3(0, 0.4, 0))


func is_owner_visible() -> bool:
	return owner_actor != null and camera.is_position_in_frustum(owner_actor.global_position + Vector3(0, 1.0, 0))
