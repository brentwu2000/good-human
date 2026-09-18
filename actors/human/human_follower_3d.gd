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
const LEASH_WIDTH: float = 0.042


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
	_leash_material = Greybox.material(LEASH_TEAL)
	_leash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
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
		target = to_dog.normalized() * lerpf(walk_speed * 0.5, drag_speed, pull) * speed_multiplier
	var planar := Vector3(velocity.x, 0.0, velocity.z).move_toward(target, 20.0 * delta)
	velocity = Vector3(planar.x, velocity.y - 9.8 * delta, planar.z)
	move_and_slide()
	if is_on_floor():
		velocity.y = 0.0
	if distance > catch_up_distance:
		global_position = dog.global_position - to_dog.normalized() * max_length
	if planar.length() > 0.2:
		puppet.rotation.y = lerp_angle(puppet.rotation.y, atan2(-planar.x, -planar.z), minf(delta * 8.0, 1.0))


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
	if value == State.FOLLOW:
		puppet.revive()
		puppet.show_hp(false)


func set_faded(value: bool) -> void:
	if faded == value:
		return
	faded = value
	puppet.set_faded(value)


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
	_leash_material.albedo_color = LEASH_TEAL.lerp(LEASH_TENSION, smoothstep(0.72, 1.0, tension))
	var direction := collar - hand
	direction.y = 0.0
	var side := direction.normalized().cross(Vector3.UP) * (LEASH_WIDTH * 0.5)
	if side.length_squared() < 0.0001:
		side = Vector3.RIGHT * (LEASH_WIDTH * 0.5)
	_leash_mesh.clear_surfaces()
	_leash_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in 9:
		var t := i / 8.0
		var p := hand.lerp(collar, t)
		p.y -= sin(t * PI) * sag
		_leash_mesh.surface_add_vertex(p - side)
		_leash_mesh.surface_add_vertex(p + side)
	_leash_mesh.surface_end()
