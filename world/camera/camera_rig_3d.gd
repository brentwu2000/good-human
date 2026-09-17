class_name CameraRig3D
extends Node3D
## Production camera (ADR-010): a low chase camera behind the dog (the P-01
## "B" framing). Pivot + boom with smoothing. Walls pull the camera in, and
## anything too close, the owner or foliage that hides the dog fades out.
## Fights pull the camera back to frame both humans. Framing never changes
## gameplay.

const FRAMING: Dictionary = {"pivot": 0.8, "pitch": -9.0, "distance": 2.8, "fov": 70.0}
## Pulled back to keep the dog and both humans in view during a fight.
const COMBAT_FRAMING: Dictionary = {"pivot": 1.4, "pitch": -28.0, "distance": 7.5, "fov": 64.0}

@export var smoothing: float = 6.0
@export var yaw_follow_speed: float = 2.2
@export var collision_margin: float = 0.25
## A wall may pull the camera in down to this distance; anything closer fades
## instead, so the camera stays low behind the dog.
@export var collision_min_distance: float = 1.2
## The camera swings behind the dog only while the stick points within this
## angle (deg) of forward and the dog already faces roughly away from the
## camera, so sideways input doesn't spin dog and camera in circles.
@export var follow_max_angle: float = 50.0

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


## Places the camera straight behind the dog's current heading.
func snap_behind_dog() -> void:
	yaw = dog.heading()
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

	if not instant and dog.planar_speed() > 0.5 and _stick_points_forward() \
			and absf(angle_difference(yaw, dog.heading())) <= deg_to_rad(follow_max_angle):
		yaw = lerp_angle(yaw, dog.heading(), minf(yaw_follow_speed * delta, 1.0))
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


func _stick_points_forward() -> bool:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input.y >= -0.1:
		return false
	return rad_to_deg(atan2(absf(input.x), -input.y)) <= follow_max_angle


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
