class_name CameraRig3D
extends Node3D
## Production camera (ADR-010): switch any time between A, a 3/4 top-down view
## like the 2D game, and B, a dog-height chase camera. Pivot + boom with
## smoothing. B avoids walls, fades the owner or foliage when they hide the
## dog, and pulls back to frame fights. A fades buildings/foliage in front of
## the dog. Framing changes never change gameplay.

signal view_changed(view: View)

enum View { TOP_DOWN, DOG }

const PROFILES: Dictionary = {
	View.TOP_DOWN: {"pivot": 0.5, "pitch": -72.0, "distance": 18.0, "fov": 42.0},
	View.DOG: {"pivot": 0.85, "pitch": -10.0, "distance": 3.0, "fov": 70.0},
}
## B pulls back to keep both humans in view during a fight.
const DOG_COMBAT: Dictionary = {"pivot": 1.4, "pitch": -28.0, "distance": 7.5, "fov": 64.0}
const VIEW_NAMES: Array[String] = ["俯視", "狗視角"]

@export var view: View = View.TOP_DOWN
@export var smoothing: float = 6.0
@export var yaw_follow_speed: float = 2.2
@export var collision_margin: float = 0.25
## When a wall pulls the camera closer than this, it rises instead.
@export var collision_min_distance: float = 1.8
## Top-down cutaway: buildings whose center is this close to the dog fade.
@export var top_down_cutaway_radius: float = 11.0

var dog: DogController3D
var owner_actor: HumanFollower3D
var coordinator: CombatCoordinator3D
var yaw: float = 0.0
var current: Dictionary = {}
var collided: bool = false

var camera: Camera3D
var _focus: Vector3
var _faded: Dictionary[Node, bool] = {}


func _ready() -> void:
	top_level = true
	camera = Camera3D.new()
	camera.current = true
	add_child(camera)


func toggle() -> void:
	set_view(View.DOG if view == View.TOP_DOWN else View.TOP_DOWN)


## Switching keeps control readable: B starts behind the dog's heading,
## A returns to screen-north. Movement is always relative to the camera.
func set_view(value: View) -> void:
	view = value
	yaw = dog.heading() if view == View.DOG else 0.0
	current.clear()
	snap()
	view_changed.emit(view)


func snap() -> void:
	current.clear()
	_update(1.0, true)


func is_combat_framing() -> bool:
	return view == View.DOG and coordinator != null and coordinator.is_fighting()


func _physics_process(delta: float) -> void:
	if dog == null:
		return
	if Input.is_action_just_pressed("camera_toggle"):
		toggle()
	_update(delta, false)


func _update(delta: float, instant: bool) -> void:
	var target: Dictionary = DOG_COMBAT if is_combat_framing() else PROFILES[view]
	var t := 1.0 if instant or current.is_empty() else 1.0 - exp(-smoothing * delta)
	if current.is_empty():
		current = target.duplicate()
	for key: String in ["pivot", "pitch", "distance", "fov"]:
		current[key] = lerpf(current[key], target[key], t)

	if view == View.TOP_DOWN:
		yaw = 0.0
	elif dog.planar_speed() > 0.5:
		yaw = lerp_angle(yaw, dog.heading(), 1.0 if instant else minf(yaw_follow_speed * delta, 1.0))
	dog.camera_yaw = yaw

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


## Fades occluders between focus and camera; in B, solid walls pull the camera in.
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
		var fades := body.is_in_group(Greybox.FADE_GROUP) or (view == View.TOP_DOWN and body.is_in_group(Greybox.FADE_TOP_DOWN_GROUP))
		if fades or view == View.TOP_DOWN:
			if fades:
				fade_now[body] = true
			exclude.append(hit["rid"])
			continue
		collided = true
		var point: Vector3 = hit["position"]
		result = point + (from - point).normalized() * collision_margin
		var shortfall := collision_min_distance - result.distance_to(from)
		if shortfall > 0.0:
			result.y += shortfall * 1.5
		break
	if view == View.TOP_DOWN:
		for node in get_tree().get_nodes_in_group(Greybox.FADE_TOP_DOWN_GROUP):
			var body3d := node as Node3D
			var offset := body3d.global_position - dog.global_position
			if Vector2(offset.x, offset.z).length() <= top_down_cutaway_radius:
				fade_now[body3d] = true
	for body in _faded.keys():
		if not fade_now.has(body) and is_instance_valid(body):
			Greybox.set_faded(body, false)
	for body in fade_now:
		if not _faded.has(body):
			Greybox.set_faded(body, true)
	_faded = fade_now
	return result


## The leashed owner walks behind the dog, right where a chase camera looks.
func _update_owner_fade() -> void:
	if owner_actor == null:
		return
	var from := camera.global_position
	var to := dog.global_position + Vector3(0, 0.4, 0)
	var body := owner_actor.global_position + Vector3(0, 0.9, 0)
	var segment := to - from
	var t := clampf((body - from).dot(segment) / maxf(segment.length_squared(), 0.001), 0.0, 1.0)
	var closest := from + segment * t
	var blocking := view == View.DOG and t > 0.05 and t < 0.95 and Vector2(body.x - closest.x, body.z - closest.z).length() < 0.6
	owner_actor.set_faded(blocking)


func is_dog_visible() -> bool:
	return camera.is_position_in_frustum(dog.global_position + Vector3(0, 0.4, 0))
