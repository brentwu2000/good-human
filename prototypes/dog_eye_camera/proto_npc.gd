class_name ProtoNpc
extends Node3D
## P-01 background life: a person, optionally walking a dog, who strolls a
## route, stands chatting, or sits. Their dog notices the player's dog.
## Greybox only; no collision so it never blocks the camera test.

enum Activity { WALK, STAND, SIT }

const NOTICE_DISTANCE: float = 3.5

@export var activity: Activity = Activity.WALK
## Walk route (world positions), looped back and forth.
@export var route: Array[Vector3] = []
@export var walk_speed: float = 1.3
@export var pause_seconds: float = 1.5
@export var height: float = 1.0
@export var shirt: Color = Color(0.4, 0.5, 0.7)
@export var pants: Color = Color(0.25, 0.25, 0.3)
@export var hair: Color = Color(0.2, 0.15, 0.1)
@export var has_dog: bool = false
@export var dog_color: Color = Color(0.8, 0.8, 0.8)
@export var dog_size: float = 1.0
## > 0: the dog is off leash and runs around the person within this radius.
@export var dog_roam: float = 0.0
## Line shown when the player's dog comes close.
@export var remark: String = ""

var player_dog: Node3D

var _body: Node3D
var _dog: Node3D
var _leash_mesh: ImmediateMesh
var _label: Label3D
var _dog_label: Label3D
var _target_index: int = 1
var _direction: int = 1
var _pause_left: float = 0.0
var _time: float = 0.0
var _noticed: bool = false
var _label_left: float = 0.0


func _ready() -> void:
	if not route.is_empty():
		global_position = route[0]
	_time = randf() * 10.0
	_body = ProtoShapes.human(shirt, pants, hair, height)
	add_child(_body)
	if activity == Activity.SIT:
		_body.scale.y = height * 0.72
		_body.position.y = 0.25
	_label = ProtoShapes.label("", 2.2 * height, 34)
	add_child(_label)
	if has_dog:
		_dog = ProtoShapes.dog(dog_color, dog_size)
		_dog.position = Vector3(0.8, 0, 0.4)
		add_child(_dog)
		_dog.top_level = true
		_dog.global_position = global_position + Vector3(0.8, 0, 0.4)
		_dog_label = ProtoShapes.label("", 0.9 * dog_size + 0.4, 36, Color(1, 0.9, 0.5))
		_dog.add_child(_dog_label)
		if dog_roam <= 0.0:
			_leash_mesh = ImmediateMesh.new()
			var leash := MeshInstance3D.new()
			leash.mesh = _leash_mesh
			leash.material_override = ProtoShapes.material(Color(0.2, 0.3, 0.7))
			leash.top_level = true
			add_child(leash)


func _process(delta: float) -> void:
	_time += delta
	if activity == Activity.WALK and route.size() >= 2:
		_walk(delta)
	elif activity == Activity.STAND:
		_body.rotation.y += sin(_time * 0.7) * 0.2 * delta
	_update_dog(delta)
	_notice_player(delta)


func _walk(delta: float) -> void:
	if _pause_left > 0.0:
		_pause_left -= delta
		return
	var target := route[_target_index]
	var to := target - global_position
	to.y = 0.0
	if to.length() < 0.1:
		_pause_left = pause_seconds
		if _target_index + _direction >= route.size() or _target_index + _direction < 0:
			_direction = -_direction
		_target_index += _direction
		return
	var speed := walk_speed * (0.4 if _noticed else 1.0)
	global_position += to.normalized() * minf(speed * delta, to.length())
	_body.rotation.y = lerp_angle(_body.rotation.y, atan2(-to.x, -to.z), minf(delta * 6.0, 1.0))
	_body.position.y = absf(sin(_time * 7.0)) * 0.04


func _update_dog(delta: float) -> void:
	if _dog == null:
		return
	var anchor := global_position + _body.basis * Vector3(0.7, 0, 0.5)
	var goal := anchor
	if _noticed and player_dog != null:
		# Leans toward the player's dog to the end of its leash.
		var towards := player_dog.global_position - global_position
		towards.y = 0.0
		goal = global_position + towards.normalized() * minf(towards.length() - 0.8, 1.8)
	elif dog_roam > 0.0:
		# Off leash: runs loops around its person.
		goal = global_position + Vector3(sin(_time * 1.3), 0, cos(_time * 1.3) * 0.7) * dog_roam
	else:
		goal += Vector3(sin(_time * 0.9) * 0.4, 0, cos(_time * 0.7) * 0.3)
	var to := goal - _dog.global_position
	to.y = 0.0
	_dog.global_position += to * minf(delta * (5.0 if dog_roam > 0.0 else 3.0), 1.0)
	_dog.global_position.y = absf(sin(_time * (14.0 if _noticed else 6.0))) * (0.06 if _noticed else 0.02)
	var look := player_dog.global_position - _dog.global_position if _noticed and player_dog != null else to
	if look.length() > 0.05:
		_dog.rotation.y = lerp_angle(_dog.rotation.y, atan2(-look.x, -look.z), minf(delta * 8.0, 1.0))
	if _leash_mesh == null:
		return
	var hand := global_position + Vector3(0, 0.95 * height, 0)
	var collar := _dog.global_position + Vector3(0, 0.45 * dog_size, 0)
	_leash_mesh.clear_surfaces()
	_leash_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in 6:
		var t := i / 5.0
		var p := hand.lerp(collar, t)
		p.y -= sin(t * PI) * 0.25
		_leash_mesh.surface_add_vertex(p)
	_leash_mesh.surface_end()


func _notice_player(delta: float) -> void:
	_label_left -= delta
	if _label_left <= 0.0:
		_label.text = ""
		if _dog_label != null:
			_dog_label.text = ""
	if player_dog == null:
		return
	var close := player_dog.global_position.distance_to(global_position) <= NOTICE_DISTANCE
	if close and not _noticed:
		_noticed = true
		_label_left = 2.0
		_label.text = remark
		if _dog_label != null:
			_dog_label.text = "汪！"
	elif not close and player_dog.global_position.distance_to(global_position) > NOTICE_DISTANCE * 1.6:
		_noticed = false


func is_noticing() -> bool:
	return _noticed
