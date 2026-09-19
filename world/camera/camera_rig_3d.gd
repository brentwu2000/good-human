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

## D4/P02-003..007: the emotional curve of a fight, as framing only. Each
## context is a destination the camera eases towards; nothing here ever cuts,
## and nothing here changes a rule. `focus` is how strongly the owner is the
## subject (see `_composed_look`).
## EXPLORE  — walking. The camera looks where it hangs; the dog is the subject.
## TENSION  — provoked, before the first blow. The push-in starts.
## ACTIVE   — blows landing. Tighter and lower; the dog sits in the foreground.
## CRISIS   — the owner is in trouble. Tighter still, and firmly on them.
## AFFECTION— won. Still in the dog's eyes, because being thanked is the point
##             of the whole thing (storyboard 09/10).
## RELEASE  — it is over. Holds the beat, then blends back out to EXPLORE.
enum Context { EXPLORE, TENSION, ACTIVE, CRISIS, AFFECTION, RELEASE }

## `pov` is how far the camera has moved inside the dog's head (ADR-015): 0 is
## the third-person chase shot, 1 is first person at dog eye height. The
## transition is always a blend, never a cut.
const FRAMING: Dictionary = {"pivot": 0.8, "pitch": -9.0, "distance": 2.8, "fov": 70.0, "focus": 0.0, "pov": 0.0}
## A fight must read as a push-IN against the walking shot, so every combat
## context is closer and narrower than EXPLORE, not further away. (The first
## pass measured itself against the old 7.5 m pull-back instead of against
## walking, so it pulled back 1.8 m while narrowing 8° — the two cancelled and
## a fight looked like an ordinary walk.)
const CONTEXT_FRAMING: Dictionary = {
	Context.EXPLORE: FRAMING,
	Context.TENSION: {"pivot": 0.95, "pitch": -11.0, "distance": 2.35, "fov": 62.0, "focus": 0.50, "pov": 0.0},
	Context.ACTIVE: {"pivot": 1.00, "pitch": -12.0, "distance": 2.00, "fov": 66.0, "focus": 1.00, "pov": 1.0},
	Context.CRISIS: {"pivot": 0.95, "pitch": -10.0, "distance": 1.75, "fov": 58.0, "focus": 1.00, "pov": 1.0},
	Context.AFFECTION: {"pivot": 1.00, "pitch": -10.0, "distance": 1.90, "fov": 52.0, "focus": 1.00, "pov": 1.0},
	Context.RELEASE: {"pivot": 1.00, "pitch": -14.0, "distance": 3.10, "fov": 66.0, "focus": 0.60, "pov": 0.0},
}
## A tight shot only works while the dog is near the fight. Past this far from
## the owner (m) the boom gives ground so the fight stays in the picture, at
## `combat_spread` metres per metre — it widens for the player who roams instead
## of framing every fight for the worst case.
@export var combat_spread_from: float = 2.0
@export var combat_spread: float = 0.8
## The owner is in trouble below this share of their health.
const CRISIS_CONDITION: float = 0.34
## The push into a fight is deliberate (0.5-1.0 s), not a cut; everything else
## settles at the usual rate.
@export var snap_smoothing: float = 2.2
## The Combat Snap into first person (D4: 0.35-0.8 s). Blended, never cut.
@export var pov_snap_rate: float = 3.4
## CombatCenter: the point the POV camera watches, between the two humans and
## biased towards the owner (tunable, as the spec asks).
@export_range(0.0, 1.0) var combat_center_owner_bias: float = 0.62
## Radians per second the POV aim may turn. Capped to keep first person
## readable rather than nauseating.
@export var pov_turn_rate: float = 3.0
## The aim ignores movement of the fight inside this angle (radians), so it does
## not make constant micro-corrections.
@export var pov_dead_zone: float = 0.05

## ADR-014 / D4/P02-001: during a fight the two jobs of the camera come apart.
## The dog stays the FollowAnchor — the camera still hangs behind the dog and
## the player still steers relative to the view — while the owner becomes the
## FocusAnchor, the thing the camera is actually looking at. The dog drifts to
## the lower foreground instead of owning the centre of the screen.
##
## D4/P02-002: the aim is soft. The owner only pulls the look point by the part
## of their offset that lies outside a dead-zone, so small shuffling during a
## fight does not drag the camera around. It is composition, never a lock-on.
## Meters of owner movement the aim simply ignores. Small: this is here to
## swallow shuffling, not to suppress the focus shift itself.
@export var focus_dead_zone: float = 0.35
## How much of the owner's offset beyond that the aim takes up at full focus
## (0..1). High enough that the owner really is the subject, short of 1.0 so
## the framing never snaps rigidly onto them. Scaled by the context's `focus`.
@export var focus_weight: float = 0.9
## The aim eases towards its target at this rate, so a snap is interpolation.
@export var focus_rate: float = 3.2
## Share of the half-FOV the dog is allowed to sit from the centre of the
## screen. The owner is the subject, but never at the cost of losing the dog off
## the edge — the player is still steering it. Deliberately generous: the
## composition wants the dog at the edge of frame, not near the middle, and a
## tight shot plus a centred dog leaves no room for the owner to be the subject.
@export_range(0.1, 0.95) var dog_frame_margin: float = 0.88

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
## Impact shake (Core Experience Gate 02). Trauma decays every second; the
## offset is trauma squared, so small hits barely register and a heavy one is
## unmistakable. It moves the view only — never the dog, the fight or the rules.
@export var shake_decay: float = 2.4
@export var shake_angle: float = 0.035
@export var shake_offset: float = 0.10

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
var _trauma: float = 0.0
var _shake_time: float = 0.0
## The composition: how far the aim currently sits from the dog. Kept as an
## offset from the anchor rather than a world point, because a world point the
## camera then flies past sends the aim wild.
var _look_offset: Vector3 = Vector3.ZERO
var _has_look: bool = false
var context: Context = Context.EXPLORE
## 0..1 blend into the dog's eyes, eased separately from the rest of the framing.
var pov: float = 0.0
var _pov_aim: Vector3 = Vector3.ZERO
var _first_person_view: DogFirstPersonView3D
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
	# The dog's own muzzle and ears, in the lower frame while in first person.
	var view := DogFirstPersonView3D.new()
	camera.add_child(view)
	view.visible = false
	if dog != null:
		dog.first_person_view = view
	_first_person_view = view


## A hit landed: 0..1 for how hard. Never accumulates past a full shake.
func add_trauma(weight: float) -> void:
	_trauma = clampf(_trauma + clampf(weight, 0.0, 1.0) * 0.6, 0.0, 1.0)


## Places the camera straight behind the dog's current heading.
func snap_behind_dog() -> void:
	yaw = dog.heading()
	_control_yaw = yaw
	_has_look = false
	_pov_aim = Vector3.ZERO
	snap()


func snap() -> void:
	current.clear()
	_update(1.0, true)


func is_combat_framing() -> bool:
	return context != Context.EXPLORE


## The direction the player is actually looking along. Out of first person that
## is the boom; inside it the boom is behind their eyes and means nothing, so it
## is where the camera is pointed. Movement is read against this, otherwise
## pushing forward walks somewhere other than into the screen and the player
## backs away from the fight without meaning to.
func view_yaw() -> float:
	if pov <= 0.5:
		return yaw
	var forward := -global_basis.z
	forward.y = 0.0
	return yaw if forward.length() < 0.01 else atan2(-forward.x, -forward.z)


## Which beat of the fight the framing should be playing. Read from what the
## coordinator reports; the camera never decides anything about the fight.
func _desired_context() -> Context:
	if coordinator == null:
		return Context.EXPLORE
	if coordinator.is_fighting():
		if coordinator.owner_condition() >= 0.0 and coordinator.owner_condition() <= CRISIS_CONDITION:
			return Context.CRISIS
		return Context.ACTIVE if coordinator.blows_landed > 0 else Context.TENSION
	# Won: stay in the dog's eyes while the owner turns round to it.
	if coordinator.is_acknowledging():
		return Context.AFFECTION
	# The owner is down but the dog can still move around them: stay with them.
	if coordinator.is_owner_down():
		return Context.CRISIS
	return Context.RELEASE if coordinator.release_left > 0.0 else Context.EXPLORE


func _physics_process(delta: float) -> void:
	if dog == null:
		return
	_update(delta, false)


func _update(delta: float, instant: bool) -> void:
	var was := context
	context = _desired_context()
	var target: Dictionary = CONTEXT_FRAMING[context]
	# Going into a fight is a push-in the player can feel; coming out and every
	# other change settles at the ordinary rate.
	var entering := was == Context.EXPLORE and context != Context.EXPLORE
	# The push-in is deliberate, but only as camera language. How fast the rig
	# follows the dog is never slowed: lagging behind the thing the player is
	# steering reads as broken, not as tension.
	var rate := snap_smoothing if entering or context == Context.TENSION else smoothing
	var framing_t := 1.0 if instant or current.is_empty() else 1.0 - exp(-rate * delta)
	var t := 1.0 if instant or current.is_empty() else 1.0 - exp(-smoothing * delta)
	if current.is_empty():
		current = target.duplicate()
	for key: String in ["pivot", "pitch", "distance", "fov", "focus"]:
		current[key] = lerpf(current.get(key, target[key]), target[key], framing_t)

	if not instant:
		_update_yaw(delta)

	# FollowAnchor: the boom always hangs behind the dog, in a fight or not.
	var anchor := dog.global_position + Vector3(0, current["pivot"], 0)
	_focus = anchor if instant or _focus == Vector3.ZERO else _focus.lerp(anchor, t)

	# The Combat Snap (ADR-015): the camera moves into the dog's head. Eased on
	# its own rate so it is always a transition, never a cut.
	# Read from the context itself, not the blended framing: `pov` has its own
	# snap rate and must not be smoothed twice.
	var pov_target: float = CONTEXT_FRAMING[context].get("pov", 0.0)
	pov = pov_target if instant else lerpf(pov, pov_target, 1.0 - exp(-pov_snap_rate * delta))
	if dog.first_person_view == null and _first_person_view != null:
		dog.first_person_view = _first_person_view
	dog.set_first_person(pov > 0.85)

	var pitch := deg_to_rad(current["pitch"])
	var boom: Vector3 = Vector3(0, -sin(pitch), cos(pitch)).rotated(Vector3.UP, yaw) * _boom_distance()
	var chase := _place_camera(_focus, _focus + boom)
	global_position = chase.lerp(dog.eye_position(), pov) if pov > 0.001 else chase

	var look_point := _aim_point(delta, instant)
	if global_position.distance_to(look_point) > 0.01:
		look_at(look_point, Vector3.UP)
	_apply_shake(delta)
	camera.fov = current["fov"]
	# Last, so the stick is read against the view the player is actually looking
	# along this frame — in first person that is the aim, not the boom.
	_update_control_frame(delta, instant)
	_update_owner_fade()


## Where the camera is pointed. Out of first person this is the chase
## composition; inside it, the fight itself, tracked softly.
func _aim_point(delta: float, instant: bool) -> Vector3:
	var target_offset := _keep_dog_in_frame(_composed_look(_focus)) - _focus
	if instant or not _has_look:
		_look_offset = target_offset
		_has_look = true
	else:
		_look_offset = _look_offset.lerp(target_offset, 1.0 - exp(-focus_rate * delta))
	var chase_point := _focus + _look_offset
	if pov <= 0.001:
		return chase_point
	return chase_point.lerp(_tracked_combat_center(delta, instant), pov)


## P03-E05: CombatCenter — a point between the two humans, biased towards the
## owner. The aim follows it with a dead zone and a capped turn rate, so first
## person tracks the fight without micro-correcting or whipping around.
func _tracked_combat_center(delta: float, instant: bool) -> Vector3:
	var eye := dog.eye_position()
	var target := combat_center()
	if instant or _pov_aim == Vector3.ZERO:
		_pov_aim = target
		return target
	var to_target := (target - eye).normalized()
	var to_current := (_pov_aim - eye).normalized()
	if to_target.length() < 0.01 or to_current.length() < 0.01:
		return target
	var angle := to_current.angle_to(to_target)
	if angle <= pov_dead_zone:
		return _pov_aim
	# Turn towards it, never faster than the cap.
	var step := minf(angle - pov_dead_zone, pov_turn_rate * delta)
	var axis := to_current.cross(to_target)
	var direction := to_target if axis.length() < 0.0001 else to_current.rotated(axis.normalized(), step)
	_pov_aim = eye + direction * eye.distance_to(target)
	return _pov_aim


## The point the fight is happening at: between the two humans, weighted towards
## the owner so the player's human is the one being watched.
func combat_center() -> Vector3:
	var head := Vector3(0, 1.1, 0)
	if owner_actor == null:
		return dog.global_position + head
	var owner_point := owner_actor.global_position + head
	# Being thanked is between the two of them; the beaten pair is not part of it.
	if coordinator == null or coordinator.pair == null or context == Context.AFFECTION:
		return owner_point
	return (coordinator.pair.human_global_position() + head).lerp(owner_point, combat_center_owner_bias)


## The context distance, given ground only when the dog has strayed from its
## human, so the fight does not fall out of the picture.
func _boom_distance() -> float:
	var distance: float = current["distance"]
	if context == Context.EXPLORE or owner_actor == null:
		return distance
	var apart := _flat_distance(dog.global_position, owner_actor.global_position)
	return distance + maxf(apart - combat_spread_from, 0.0) * combat_spread


func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## FocusAnchor (D4/P02-001) with a soft dead-zone (D4/P02-002). Out of combat
## the camera simply looks where it hangs. In a fight it looks at the owner —
## but only by the part of their offset that leaves the dead-zone, and only by
## `focus_weight` of that, so the composition breathes instead of locking on.
## The opponent is a secondary pull, so the fight stays framed as a pair.
func _composed_look(anchor: Vector3) -> Vector3:
	var focus: float = current.get("focus", 0.0) * focus_weight
	if focus <= 0.0 or owner_actor == null:
		return anchor
	var subject := owner_actor.global_position + Vector3(0, current["pivot"], 0)
	if coordinator != null and coordinator.pair != null:
		subject = subject.lerp(coordinator.pair.human_global_position() + Vector3(0, current["pivot"], 0), 0.3)
	var offset := subject - anchor
	var distance := offset.length()
	if distance <= focus_dead_zone:
		return anchor
	return anchor + offset.normalized() * (distance - focus_dead_zone) * focus


## The owner may pull the aim only so far: past `max_focus_angle` the dog would
## slide off the screen, and the player is still steering it. Swings the aim
## back towards the dog rather than clipping it, so the motion stays smooth.
func _keep_dog_in_frame(look_target: Vector3) -> Vector3:
	# Inside the dog's head there is no dog to keep in frame.
	if pov > 0.5:
		return look_target
	# Measured against the dog itself, not the smoothed pivot the boom hangs
	# from: a wall can pull the camera in and the pivot sits above the dog, so
	# the pivot is not a safe stand-in for "where the dog is on screen".
	var to_dog := (dog.global_position + Vector3(0, 0.4, 0)) - global_position
	var to_look := look_target - global_position
	if to_dog.length() < 0.01 or to_look.length() < 0.01:
		return look_target
	# Derived from the framing in use, so tightening the shot tightens this too.
	var limit := deg_to_rad(float(current["fov"]) * 0.5) * dog_frame_margin
	var angle := to_dog.angle_to(to_look)
	if angle <= limit:
		return look_target
	var axis := to_dog.cross(to_look)
	if axis.length() < 0.0001:
		return look_target
	return global_position + to_dog.normalized().rotated(axis.normalized(), limit) * to_look.length()


## Shakes the camera node after it has been placed and aimed, so collision and
## framing are unaffected by it.
func _apply_shake(delta: float) -> void:
	if _trauma <= 0.0:
		return
	_trauma = maxf(_trauma - shake_decay * delta, 0.0)
	_shake_time += delta
	var amount := _trauma * _trauma
	var a := sin(_shake_time * 47.0) * amount
	var b := sin(_shake_time * 61.0 + 1.7) * amount
	global_position += (global_basis.x * a + global_basis.y * b) * shake_offset
	rotate_object_local(Vector3.FORWARD, a * shake_angle)
	rotate_object_local(Vector3.RIGHT, b * shake_angle)


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
	var view := view_yaw()
	if instant or not held or not _stick_held or absf(rad_to_deg(angle_difference(_stick_angle, angle))) > relatch_angle:
		_control_yaw = view
		_stick_angle = angle
	else:
		_control_yaw = lerp_angle(_control_yaw, view, 1.0 - exp(-control_follow_rate * delta))
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
