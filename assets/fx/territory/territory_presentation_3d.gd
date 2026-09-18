class_name TerritoryPresentation3D
extends Node3D
## Presentation-only hooks for Sprint 05 territory interactions.
## Gameplay owns eligibility, progress, rewards and persistence.

const AMBER := Color("#efb448")
const TEAL := Color("#34988b")
const CREAM := Color("#f0e3c5")

var _recognize := Node3D.new()
var _mark := Node3D.new()
var _reward := Node3D.new()
var _recognize_left := 0.0
var _mark_left := 0.0
var _reward_left := 0.0
var _time := 0.0


func _ready() -> void:
	name = "TerritoryPresentation"
	add_child(_recognize)
	add_child(_mark)
	add_child(_reward)
	_build_recognize()
	_build_mark()
	_build_reward()
	_recognize.hide()
	_mark.hide()
	_reward.hide()


func play_recognize() -> void:
	_recognize_left = 0.85
	_recognize.show()


func play_mark() -> void:
	_mark_left = 1.15
	_mark.show()


func play_reward_reveal() -> void:
	_reward_left = 1.80
	_reward.show()


func _process(delta: float) -> void:
	_time += delta
	_recognize_left = maxf(_recognize_left - delta, 0.0)
	_mark_left = maxf(_mark_left - delta, 0.0)
	_reward_left = maxf(_reward_left - delta, 0.0)
	_update_recognize()
	_update_mark()
	_update_reward()


func _update_recognize() -> void:
	if _recognize_left <= 0.0:
		_recognize.hide()
		return
	var progress := 1.0 - _recognize_left / 0.85
	_recognize.scale = Vector3.ONE * lerpf(0.72, 1.18, progress)
	_recognize.rotation.y = sin(_time * 5.0) * 0.08
	_set_alpha(_recognize, (1.0 - progress) * 0.85)


func _update_mark() -> void:
	if _mark_left <= 0.0:
		_mark.hide()
		return
	var progress := 1.0 - _mark_left / 1.15
	_mark.scale = Vector3.ONE * lerpf(0.40, 1.25, progress)
	_mark.position.y = sin(progress * PI) * 0.10
	_set_alpha(_mark, sin(progress * PI) * 0.95)


func _update_reward() -> void:
	if _reward_left <= 0.0:
		_reward.hide()
		return
	var progress := 1.0 - _reward_left / 1.80
	for i in _reward.get_child_count():
		var leaf := _reward.get_child(i) as Node3D
		leaf.position.y = 0.18 + progress * (0.75 + i * 0.09)
		leaf.rotation.y = _time * (1.4 + i * 0.12)
		leaf.rotation.z = sin(_time * 3.0 + i) * 0.35
	_set_alpha(_reward, sin(progress * PI) * 0.90)


func _build_recognize() -> void:
	_recognize.position = Vector3(0, 0.08, -1.15)
	for angle in [-0.58, -0.28, 0.0, 0.28, 0.58]:
		var ray := Greybox.box(Vector3(0.055, 0.035, 0.36), AMBER, Vector3(sin(angle) * 0.38, 0, cos(angle) * -0.22), Vector3(0, angle, 0))
		_prepare_fx(ray)
		_recognize.add_child(ray)


func _build_mark() -> void:
	_mark.position = Vector3(0, 0.05, -1.05)
	for i in 5:
		var angle := TAU * i / 5.0
		var knot := Greybox.sphere(0.085, TEAL, Vector3(sin(angle) * 0.42, 0, cos(angle) * 0.30))
		_prepare_fx(knot)
		_mark.add_child(knot)
	var stroke := Greybox.capsule(0.030, 0.72, TEAL.lightened(0.12), Vector3.ZERO, Vector3(0, 0, PI * 0.5))
	_prepare_fx(stroke)
	_mark.add_child(stroke)


func _build_reward() -> void:
	_reward.position = Vector3(0, 0.10, -1.05)
	for i in 9:
		var angle := TAU * i / 9.0
		var color := TEAL if i % 2 == 0 else CREAM
		var leaf := Greybox.box(Vector3(0.13, 0.035, 0.25), color, Vector3(sin(angle) * 0.45, 0, cos(angle) * 0.32), Vector3(0, angle, 0.35))
		_prepare_fx(leaf)
		_reward.add_child(leaf)


func _prepare_fx(mesh: MeshInstance3D) -> void:
	var material := mesh.get_surface_override_material(0) as StandardMaterial3D
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED


func _set_alpha(node: Node, alpha: float) -> void:
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var material := (child as MeshInstance3D).get_surface_override_material(0) as StandardMaterial3D
		if material != null:
			material.albedo_color.a = alpha
