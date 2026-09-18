class_name EncounterPresentation3D
extends Node3D
## World-space encounter framing for the dog-height camera.
## Deliberately restrained: this is an attention cue, not an arena boundary.

enum VisualState { IDLE, HINTED, COMBAT, BEATEN }

const AMBER := Color("#f2b84b")
const CORAL := Color("#e6785f")
const TEAL := Color("#3d9b91")
const MUTED := Color("#7e8681")

var visual_state := VisualState.IDLE
var _brackets := Node3D.new()
var _impact := Node3D.new()
var _time := 0.0
var _impact_left := 0.0


func _ready() -> void:
	name = "EncounterPresentation"
	add_child(_brackets)
	add_child(_impact)
	_build_brackets()
	_build_impact()
	set_visual_state(visual_state)


func _process(delta: float) -> void:
	_time += delta
	var pulse := 1.0
	if visual_state == VisualState.HINTED:
		pulse = 1.0 + sin(_time * 4.0) * 0.08
	elif visual_state == VisualState.COMBAT:
		pulse = 1.0 + sin(_time * 6.0) * 0.035
	_brackets.scale = Vector3.ONE * pulse
	_brackets.rotation.y = sin(_time * 0.8) * 0.025
	if _impact_left > 0.0:
		_impact_left -= delta
		var progress := 1.0 - _impact_left / 0.22
		_impact.scale = Vector3.ONE * lerpf(0.35, 1.15, progress)
		_set_alpha(_impact, (1.0 - progress) * 0.92)
		_impact.visible = true
	else:
		_impact.visible = false


func set_visual_state(value: VisualState) -> void:
	visual_state = value
	if not is_node_ready():
		return
	match visual_state:
		VisualState.IDLE:
			_brackets.visible = true
			_set_color(_brackets, AMBER.darkened(0.12), 0.34)
		VisualState.HINTED:
			_brackets.visible = true
			_set_color(_brackets, AMBER, 0.72)
		VisualState.COMBAT:
			_brackets.visible = true
			_set_color(_brackets, CORAL, 0.70)
		VisualState.BEATEN:
			_brackets.visible = false


func pulse_impact(blocked: bool = false) -> void:
	if visual_state != VisualState.COMBAT:
		return
	_set_color(_impact, TEAL if blocked else CORAL, 0.92)
	_impact_left = 0.22
	_impact.visible = true


func _build_brackets() -> void:
	# Four open corners leave the centre visually clear for feet and leash.
	for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
		var corner := Node3D.new()
		corner.rotation.y = angle
		corner.add_child(_bar(Vector3(0.62, 0.025, 0.075), Vector3(1.55, 0.035, 0.0), AMBER))
		corner.add_child(_bar(Vector3(0.075, 0.025, 0.62), Vector3(1.82, 0.035, 0.27), AMBER))
		_brackets.add_child(corner)
	# A small paw-side notch breaks the symmetry and keeps the visual dog-led.
	_brackets.add_child(_bar(Vector3(0.34, 0.035, 0.10), Vector3(0, 0.045, 1.72), TEAL))


func _build_impact() -> void:
	_impact.position = Vector3(0, 1.35, 0)
	for angle in [-0.70, -0.35, 0.0, 0.35, 0.70]:
		var ray := _bar(Vector3(0.055, 0.055, 0.48), Vector3(sin(angle) * 0.48, cos(angle) * 0.48, -0.10), CORAL)
		ray.rotation.x = PI * 0.5
		ray.rotation.z = -angle
		_impact.add_child(ray)
	_impact.visible = false


func _bar(size: Vector3, position: Vector3, color: Color) -> MeshInstance3D:
	var bar := Greybox.box(size, color, position)
	var material := bar.get_surface_override_material(0) as StandardMaterial3D
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.7
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return bar


func _set_color(node: Node, color: Color, alpha: float) -> void:
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var material := (child as MeshInstance3D).get_surface_override_material(0) as StandardMaterial3D
		if material != null:
			material.albedo_color = Color(color.r, color.g, color.b, alpha)


func _set_alpha(node: Node, alpha: float) -> void:
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var material := (child as MeshInstance3D).get_surface_override_material(0) as StandardMaterial3D
		if material != null:
			material.albedo_color.a = alpha
