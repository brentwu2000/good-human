class_name WeaponTrail3D
extends MeshInstance3D
## A held weapon's swing trail (owner, 2026-10-09, after comparing with other
## games: a blow is drawn with a smear behind the weapon while it moves fast,
## gone as it slows into the follow-through). A ribbon between the tip and a
## point further down the shaft, kept for a moment and fading out.

const LIFE: float = 0.14
const ALONG: float = 0.4

var active: bool = false
var _prop: Node3D
var _tip: float = 0.6
var _samples: Array = []
var _mesh := ImmediateMesh.new()


func _init() -> void:
	top_level = true
	mesh = _mesh
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = material


## Follow `prop`, whose striking end is `tip` along its +Y.
func follow(prop: Node3D, tip: float) -> void:
	_prop = prop
	_tip = tip


func _process(delta: float) -> void:
	global_transform = Transform3D.IDENTITY
	for sample: Array in _samples:
		sample[2] += delta
	while not _samples.is_empty() and _samples[0][2] > LIFE:
		_samples.pop_front()
	if active and is_instance_valid(_prop) and _prop.is_visible_in_tree():
		var at := _prop.global_transform
		_samples.append([at * Vector3(0, _tip, 0), at * Vector3(0, _tip - ALONG, 0), 0.0])
	_mesh.clear_surfaces()
	if _samples.size() < 2:
		return
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for sample: Array in _samples:
		var fade: float = 1.0 - sample[2] / LIFE
		_mesh.surface_set_color(Color(1, 1, 1, 0.55 * fade))
		_mesh.surface_add_vertex(sample[0])
		_mesh.surface_set_color(Color(1, 1, 1, 0.0))
		_mesh.surface_add_vertex(sample[1])
	_mesh.surface_end()


## How many points the ribbon has now (tests).
func sample_count() -> int:
	return _samples.size()
