class_name DogMotion3D
extends Node
## Procedural locomotion pass for the code-native Shiba prototype.
## Reads movement state and changes visual transforms only.

enum Motion { IDLE, WALK, RUN, SNIFF }

var visual: Node3D
var motion := Motion.IDLE
var _time := 0.0
var _sniff_left := 0.0
var _base_position := Vector3.ZERO
var _base_scale := Vector3.ONE
var _head: Node3D
var _muzzle: Node3D
var _legs: Array[Node3D] = []
var _tails: Array[Node3D] = []
var _base_transforms: Dictionary = {}


func bind(target: Node3D) -> void:
	visual = target
	_base_position = visual.position
	_base_scale = visual.scale
	_head = visual.get_node_or_null("Head") as Node3D
	_muzzle = visual.get_node_or_null("Muzzle") as Node3D
	for child in visual.get_children():
		if child is Node3D and String(child.name).begins_with("Leg_"):
			_legs.append(child)
		if child is Node3D and String(child.name).begins_with("Tail_"):
			_tails.append(child)
	for part in _parts():
		_base_transforms[part] = part.transform


func update_motion(delta: float, speed: float, sprinting: bool) -> void:
	if visual == null:
		return
	_time += delta
	_sniff_left = maxf(_sniff_left - delta, 0.0)
	var next := Motion.SNIFF if _sniff_left > 0.0 else Motion.IDLE
	if next != Motion.SNIFF and speed > 0.25:
		next = Motion.RUN if sprinting or speed > 4.2 else Motion.WALK
	motion = next
	_restore_parts()
	match motion:
		Motion.IDLE:
			_apply_idle()
		Motion.WALK:
			_apply_gait(8.5, 0.045, 0.20, 0.10)
		Motion.RUN:
			_apply_gait(13.0, 0.085, 0.38, 0.20)
		Motion.SNIFF:
			_apply_sniff()


func play_sniff(seconds: float = 0.85) -> void:
	_sniff_left = maxf(_sniff_left, seconds)


func _apply_idle() -> void:
	var breath := sin(_time * 2.6)
	visual.position = _base_position + Vector3(0, breath * 0.008, 0)
	visual.scale = _base_scale * Vector3(1.0 - breath * 0.006, 1.0 + breath * 0.01, 1.0)
	if _head != null:
		_head.rotation.z += sin(_time * 1.3) * 0.025
	for i in _tails.size():
		_tails[i].rotation.y += sin(_time * 3.4 + i * 0.7) * 0.10


func _apply_gait(rate: float, bob: float, stride: float, lean: float) -> void:
	var cycle := _time * rate
	visual.position = _base_position + Vector3(0, absf(sin(cycle)) * bob, 0)
	visual.scale = _base_scale
	visual.rotation.x = -lean + sin(cycle * 0.5) * 0.025
	for i in _legs.size():
		# Diagonal pairs share phase for a readable four-beat dog gait.
		var phase := 0.0 if i in [0, 3] else PI
		_legs[i].rotation.x += sin(cycle + phase) * stride
		_legs[i].position.y += maxf(0.0, sin(cycle + phase)) * bob * 0.9
	if _head != null:
		_head.position.y += sin(cycle + PI * 0.5) * bob * 0.35
	for i in _tails.size():
		_tails[i].rotation.y += sin(cycle * 0.65 + i * 0.4) * (0.12 + stride * 0.25)


func _apply_sniff() -> void:
	var cycle := _time * 8.0
	visual.position = _base_position
	visual.scale = _base_scale
	visual.rotation.x = 0.10
	if _head != null:
		_head.position.y -= 0.15 + sin(cycle) * 0.025
		_head.position.z -= 0.06
		_head.rotation.x += 0.38
	if _muzzle != null:
		_muzzle.position.y -= 0.17 + sin(cycle) * 0.02
		_muzzle.position.z -= 0.08
		_muzzle.rotation.x += 0.30
	for i in _legs.size():
		_legs[i].rotation.x += sin(cycle + i * PI * 0.5) * 0.07
	for i in _tails.size():
		_tails[i].rotation.y += sin(cycle * 0.55 + i) * 0.18


func _restore_parts() -> void:
	visual.position = _base_position
	visual.scale = _base_scale
	visual.rotation.x = 0.0
	for part in _parts():
		part.transform = _base_transforms[part]


func _parts() -> Array[Node3D]:
	var result: Array[Node3D] = []
	if _head != null:
		result.append(_head)
	if _muzzle != null:
		result.append(_muzzle)
	result.append_array(_legs)
	result.append_array(_tails)
	return result
