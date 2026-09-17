class_name ProtoOwner
extends CharacterBody3D
## P-01 greybox owner on a leash. FOLLOW the dog; in COMBAT the fight proxy
## drives it; DOWN when beaten. Prototype only.

enum State { FOLLOW, COMBAT, DOWN }

@export var slack_length: float = 1.4
@export var max_length: float = 2.6
@export var walk_speed: float = 3.3
@export var drag_speed: float = 6.4

var dog: ProtoDog
var state: State = State.FOLLOW
## Seconds the owner is being dragged at speed (TRAIN readability).
var dragged_time: float = 0.0
## True while faded because it blocks the camera's view of the dog.
var faded: bool = false

var _visual: Node3D
var _bubble: Label3D
var _bubble_left: float = 0.0
var _leash: MeshInstance3D
var _leash_mesh: ImmediateMesh


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.25
	capsule.height = 1.75
	shape.shape = capsule
	shape.position.y = 0.88
	add_child(shape)
	_visual = ProtoShapes.human(Color(0.85, 0.45, 0.35), Color(0.2, 0.25, 0.4), Color(0.25, 0.18, 0.12))
	add_child(_visual)
	_bubble = ProtoShapes.label("", 2.2, 40)
	add_child(_bubble)
	_leash_mesh = ImmediateMesh.new()
	_leash = MeshInstance3D.new()
	_leash.mesh = _leash_mesh
	_leash.material_override = ProtoShapes.material(Color(0.85, 0.2, 0.2))
	_leash.top_level = true
	add_child(_leash)


func _physics_process(delta: float) -> void:
	if dog == null:
		return
	if state == State.FOLLOW:
		_follow(delta)
	else:
		dragged_time = 0.0
	_bubble_left -= delta
	if _bubble_left <= 0.0:
		_bubble.text = ""
	_draw_leash()


func _follow(delta: float) -> void:
	var to_dog := dog.global_position - global_position
	to_dog.y = 0.0
	var distance := to_dog.length()
	var target := Vector3.ZERO
	if distance > slack_length:
		var pull := clampf(inverse_lerp(slack_length, max_length, distance), 0.0, 1.5)
		target = to_dog.normalized() * lerpf(walk_speed * 0.5, drag_speed, clampf(pull, 0.0, 1.0))
	var planar := Vector3(velocity.x, 0.0, velocity.z).move_toward(target, 20.0 * delta)
	velocity = Vector3(planar.x, velocity.y - 9.8 * delta, planar.z)
	move_and_slide()
	if is_on_floor():
		velocity.y = 0.0
	if distance > max_length * 4.0:
		global_position = dog.global_position - to_dog.normalized() * max_length
	if planar.length() > 0.2:
		_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(-planar.x, -planar.z), minf(delta * 8.0, 1.0))
	if planar.length() > walk_speed * 1.2:
		dragged_time += delta
		if dragged_time > 2.0 and _bubble_left <= 0.0:
			say("慢一點啦！")
	else:
		dragged_time = 0.0


func face_towards(point: Vector3) -> void:
	var d := point - global_position
	_visual.rotation.y = atan2(-d.x, -d.z)


func set_state(value: State) -> void:
	state = value
	velocity = Vector3.ZERO
	_visual.rotation.z = 0.0
	if value == State.DOWN:
		_visual.rotation.z = PI / 2.0


func say(text: String, seconds: float = 1.6) -> void:
	_bubble.text = text
	_bubble_left = seconds


## Semi-transparent while standing between the camera and the dog.
func set_faded(value: bool) -> void:
	if faded == value:
		return
	faded = value
	for child in _visual.find_children("*", "MeshInstance3D", true, false):
		var mesh := (child as MeshInstance3D).mesh as PrimitiveMesh
		var mat := mesh.material as StandardMaterial3D
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if value else BaseMaterial3D.TRANSPARENCY_DISABLED
		mat.albedo_color.a = 0.28 if value else 1.0


func hand_position() -> Vector3:
	return global_position + Vector3(0, 1.0, 0)


func _draw_leash() -> void:
	var a := hand_position()
	var b := dog.collar_position()
	var length := a.distance_to(b)
	var sag := clampf(1.0 - length / max_length, 0.0, 1.0) * 0.5
	if state != State.FOLLOW:
		sag = 0.4
	_leash_mesh.clear_surfaces()
	_leash_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in 9:
		var t := i / 8.0
		var p := a.lerp(b, t)
		p.y -= sin(t * PI) * sag
		_leash_mesh.surface_add_vertex(p)
	_leash_mesh.surface_end()
