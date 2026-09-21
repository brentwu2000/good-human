class_name HumanFollower3D
extends CharacterBody3D
## 3D owner on a leash. FOLLOW: walks after the dog. COMBAT: fights where the
## fight started; the engagement drives its position while the dog stays free.
## DOWN: knocked out. Mirrors HumanFollower (2D).

enum State { FOLLOW, COMBAT, DOWN }

@export var dog: DogController3D
@export var fighter: FighterData
@export var slack_length: float = 1.4
@export var max_length: float = 2.6
@export var walk_speed: float = 3.3
@export var drag_speed: float = 6.4
## Snap behind the dog only when this far (stuck behind a wall).
@export var catch_up_distance: float = 14.0
## How far to the dog's right the owner is pulled. Walking directly behind the
## dog puts the owner on the chase camera's own axis, where the leash points at
## the viewer and so has no length on screen to read. Trailing off to one side
## keeps the lead a visible diagonal, and keeps the owner out of the shot.
@export var follow_side_offset: float = 0.7

var state: State = State.FOLLOW
## Growth hooks (same as the 2D owner): follow speed multiplier, standing still time.
var speed_multiplier: float = 1.0
var hold_time: float = 0.0
var faded: bool = false

var puppet: FighterPuppet3D
var _bubble: Label3D
var _bubble_left: float = 0.0
var _leash_mesh: ImmediateMesh
var _leash_material: StandardMaterial3D

const LEASH_TEAL := Color(0.12, 0.55, 0.48)
const LEASH_TENSION := Color(0.95, 0.66, 0.28)
## Width as a fraction of the distance to the camera, so the lead keeps the
## same thickness on screen wherever it is.
const LEASH_SCREEN_WIDTH: float = 0.018
## Points along the lead. One more than the old eight, so the camera-facing
## widening has a smooth tangent to work from.
const SEGMENTS: int = 10


func _ready() -> void:
	collision_layer = Greybox.ACTOR_LAYER
	collision_mask = Greybox.WORLD_LAYER
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.25
	capsule.height = 1.75
	shape.shape = capsule
	shape.position.y = 0.88
	add_child(shape)
	puppet = FighterPuppet3D.new()
	add_child(puppet)
	if fighter != null:
		puppet.apply(fighter)
	puppet.show_hp(false)
	_bubble = Greybox.label("", 2.0, 36)
	add_child(_bubble)
	_leash_mesh = ImmediateMesh.new()
	var leash := MeshInstance3D.new()
	leash.mesh = _leash_mesh
	_leash_material = Greybox.material(Color.WHITE)
	_leash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# Colour and the trailing fade both ride on the vertex colours.
	_leash_material.vertex_color_use_as_albedo = true
	_leash_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	leash.material_override = _leash_material
	leash.top_level = true
	add_child(leash)


func _physics_process(delta: float) -> void:
	if dog == null:
		return
	_bubble_left -= delta
	if _bubble_left <= 0.0:
		_bubble.text = ""
	if state == State.FOLLOW:
		_follow(delta)
	_draw_leash()


func _follow(delta: float) -> void:
	var to_dog := dog.global_position - global_position
	to_dog.y = 0.0
	var distance := to_dog.length()
	var target := Vector3.ZERO
	if hold_time > 0.0:
		hold_time -= delta
	elif distance > slack_length:
		var pull := clampf(inverse_lerp(slack_length, max_length, distance), 0.0, 1.0)
		# The lead's tension is still measured to the dog; only the direction
		# the owner walks is aimed beside it.
		var toward := _follow_anchor() - global_position
		toward.y = 0.0
		if toward.length_squared() < 0.0001:
			toward = to_dog
		target = toward.normalized() * lerpf(walk_speed * 0.5, drag_speed, pull) * speed_multiplier
	var planar := Vector3(velocity.x, 0.0, velocity.z).move_toward(target, 20.0 * delta)
	velocity = Vector3(planar.x, velocity.y - 9.8 * delta, planar.z)
	move_and_slide()
	if is_on_floor():
		velocity.y = 0.0
	if distance > catch_up_distance:
		global_position = _follow_anchor() - to_dog.normalized() * max_length
	if planar.length() > 0.2:
		puppet.rotation.y = lerp_angle(puppet.rotation.y, atan2(-planar.x, -planar.z), minf(delta * 8.0, 1.0))


## Where the owner aims: beside the dog rather than in its tracks.
func _follow_anchor() -> Vector3:
	var forward := Vector3(dog.facing.x, 0.0, dog.facing.z)
	if forward.length_squared() < 0.0001:
		return dog.global_position
	var right := forward.normalized().cross(Vector3.UP)
	return dog.global_position + right * follow_side_offset


## Movement speed on the ground plane (shared with HumanFollower).
func planar_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


## Growth-shaped reaction (OwnerBehavior): greybox body language until 3D art.
## `effect`: leash (stumble), recovery (catching breath), threat (hesitation).
func play_growth_behavior(effect: StringName, improved: bool, seconds: float) -> void:
	if state != State.FOLLOW or puppet == null:
		return
	var tween := create_tween()
	match effect:
		&"leash":
			tween.tween_property(puppet, "rotation:x", -0.35 if not improved else -0.12, 0.08)
			tween.tween_property(puppet, "rotation:x", 0.0, maxf(seconds, 0.15))
		&"recovery":
			tween.tween_property(puppet, "rotation:x", -0.45 if not improved else -0.2, 0.2)
			tween.tween_interval(maxf(seconds - 0.4, 0.05))
			tween.tween_property(puppet, "rotation:x", 0.0, 0.2)
		_:
			tween.tween_property(puppet, "position:z", 0.25 if not improved else 0.0, 0.1)
			tween.tween_interval(maxf(seconds - 0.2, 0.05))
			tween.tween_property(puppet, "position:z", 0.0, 0.1)


func is_following() -> bool:
	return state == State.FOLLOW


func set_state(value: State) -> void:
	state = value
	velocity = Vector3.ZERO
	hold_time = 0.0
	if faded:
		# A fight can start while the owner is out of frame behind the dog.
		faded = false
		puppet.visible = true
	if value == State.FOLLOW:
		puppet.revive()
		puppet.show_hp(false)


## The owner walks behind the dog, which is exactly where the chase camera is.
## When it crosses that line it leaves the frame completely: a see-through
## person filling the middle of the screen reads worse than no person at all.
## The leash keeps running off past the dog, and that is what tells the player
## the owner is back there.
func set_faded(value: bool) -> void:
	# Never hide a fighter. In combat the owner is the thing being watched.
	var hidden := value and state == State.FOLLOW
	if faded == hidden:
		return
	faded = hidden
	puppet.visible = not hidden


func say(text: String, color: Color = Color.WHITE, seconds: float = 1.6) -> void:
	_bubble.text = text
	_bubble.modulate = color
	_bubble_left = seconds


func _draw_leash() -> void:
	var hand := global_position + Vector3(0, 1.0, 0)
	var collar := dog.collar_position()
	var distance := hand.distance_to(collar)
	var sag := 0.4 if state != State.FOLLOW else clampf(1.0 - distance / max_length, 0.0, 1.0) * 0.5
	var tension := clampf(inverse_lerp(slack_length, max_length, distance), 0.0, 1.0)
	var colour := LEASH_TEAL.lerp(LEASH_TENSION, smoothstep(0.72, 1.0, tension))

	var points: Array[Vector3] = []
	for i in SEGMENTS + 1:
		var t := float(i) / SEGMENTS
		var p := hand.lerp(collar, t)
		p.y -= sin(t * PI) * sag
		points.append(p)

	var camera := get_viewport().get_camera_3d()
	var eye := camera.global_position if camera != null else hand + Vector3(0, 0, 1)
	var fallback := (collar - hand).cross(Vector3.UP)
	fallback = fallback.normalized() if fallback.length_squared() > 0.0001 else Vector3.RIGHT

	_leash_mesh.clear_surfaces()
	_leash_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in points.size():
		var p: Vector3 = points[i]
		var tangent: Vector3 = points[mini(i + 1, points.size() - 1)] - points[maxi(i - 1, 0)]
		var to_eye := p - eye
		# Two things keep this reading as a lead rather than a shape. The strip
		# widens across the view, not along a fixed sideways axis, so it holds
		# up when the camera looks down its length — which is where the chase
		# camera lives. And the width grows with distance, so it covers the same
		# few pixels at both ends instead of flaring into a slab up close.
		var half := LEASH_SCREEN_WIDTH * maxf(to_eye.length(), 0.2) * 0.5
		var side := tangent.cross(to_eye)
		side = side.normalized() * half if side.length_squared() > 1e-8 else fallback * half
		# With the owner out of frame the lead would otherwise begin at a hard
		# edge in mid-air. Fading its far end lets it trail off behind instead.
		var shade := colour
		if faded:
			shade.a = smoothstep(0.0, 0.18, float(i) / SEGMENTS)
		_leash_mesh.surface_set_color(shade)
		_leash_mesh.surface_add_vertex(p - side)
		_leash_mesh.surface_set_color(shade)
		_leash_mesh.surface_add_vertex(p + side)
	_leash_mesh.surface_end()
