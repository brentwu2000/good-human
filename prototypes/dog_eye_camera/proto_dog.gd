class_name ProtoDog
extends CharacterBody3D
## P-01 greybox dog. Moves with the Input Map relative to the camera yaw, so
## the same controls work for every camera variant. Prototype only.

@export var walk_speed: float = 3.5
@export var sprint_speed: float = 6.2
@export var acceleration: float = 18.0
## Joystick pushed past this also sprints (mobile has no sprint key).
@export var stick_sprint_threshold: float = 0.95

## Set by the camera rig every frame (radians). 0 = forward is -Z.
var camera_yaw: float = 0.0
var sniffing: bool = false
var facing: Vector3 = Vector3.FORWARD

var _visual: Node3D


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.25
	capsule.height = 0.7
	shape.shape = capsule
	shape.rotation_degrees.x = 90.0
	shape.position.y = 0.3
	add_child(shape)
	_visual = Node3D.new()
	add_child(_visual)
	_visual.add_child(ProtoShapes.box(Vector3(0.36, 0.34, 0.8), Color(0.78, 0.55, 0.32), Vector3(0, 0.42, 0)))
	_visual.add_child(ProtoShapes.box(Vector3(0.3, 0.3, 0.32), Color(0.82, 0.6, 0.36), Vector3(0, 0.66, -0.48)))
	_visual.add_child(ProtoShapes.box(Vector3(0.12, 0.1, 0.14), Color(0.2, 0.14, 0.1), Vector3(0, 0.6, -0.68)))
	_visual.add_child(ProtoShapes.box(Vector3(0.06, 0.26, 0.06), Color(0.7, 0.5, 0.3), Vector3(0, 0.62, 0.42)))
	for x in [-0.12, 0.12]:
		for z in [-0.28, 0.28]:
			_visual.add_child(ProtoShapes.box(Vector3(0.08, 0.26, 0.08), Color(0.7, 0.5, 0.3), Vector3(x, 0.13, z)))


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if sniffing:
		input = Vector2.ZERO
	var direction := Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, camera_yaw)
	var sprinting := Input.is_action_pressed("sprint") or input.length() >= stick_sprint_threshold
	var target_speed := (sprint_speed if sprinting else walk_speed) * minf(input.length(), 1.0)
	var target := direction.normalized() * target_speed if direction.length() > 0.01 else Vector3.ZERO
	var planar := Vector3(velocity.x, 0.0, velocity.z).move_toward(target, acceleration * delta)
	velocity = Vector3(planar.x, velocity.y - 9.8 * delta, planar.z)
	move_and_slide()
	if is_on_floor():
		velocity.y = 0.0
	if planar.length() > 0.2:
		facing = planar.normalized()
		_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(-facing.x, -facing.z), minf(delta * 12.0, 1.0))


func planar_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


func collar_position() -> Vector3:
	return global_position + Vector3(0, 0.5, 0) - facing * 0.25
