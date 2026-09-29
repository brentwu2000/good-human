class_name ExtractionPoint3D
extends Interactable3D
## 3D timed exit. RunManager decides availability from elapsed time.

@export var extraction_id: StringName
@export var display_label: String = "撤離點"
@export var unlock_time: float = 60.0
@export var unlock_message: String = "現在可以撤離"

var available: bool = false

var _marker: MeshInstance3D
## S05-02: the way home, readable from anywhere on the walk. A soft column of
## light over a usable exit, tall enough to clear the rooftops, so choosing to
## stay out is a choice made with home in sight (world cue before HUD/text).
var _home_light: MeshInstance3D
const HOME_LIGHT_HEIGHT: float = 14.0
var _time: float = 0.0
## 0..1: how strongly home calls (S05-03, from the walk's tension).
var call_strength: float = 0.0
var _name_label: Label3D


func _enter_tree() -> void:
	add_to_group(ExtractionPoint.GROUP)


func _ready() -> void:
	prompt = "🚪 撤離"
	var visual := ExtractionVisual3D.build(extraction_id)
	add_child(visual)
	_marker = visual.get_node("Beacon") as MeshInstance3D
	_name_label = Greybox.label("", 2.8, 34)
	add_child(_name_label)
	add_interaction_area(1.1)
	_home_light = _build_home_light()
	add_child(_home_light)
	set_available(available)


func can_interact(context: Object) -> bool:
	var run := context as RunManager
	return enabled and run != null and run.is_extraction_available(extraction_id)


func interact(context: Object) -> void:
	var run := context as RunManager
	if run != null and can_interact(run):
		run.extract(extraction_id)


func set_available(value: bool) -> void:
	available = value
	if _home_light != null:
		_home_light.visible = available
	if _marker == null:
		return
	var mat := _marker.get_surface_override_material(0) as StandardMaterial3D
	mat.albedo_color = Color(0.4, 1.0, 0.5) if available else Color(0.55, 0.55, 0.55)
	if available:
		_name_label.text = "%s（可撤離）" % display_label
	else:
		_name_label.text = "%s（%02d:%02d 開放）" % [display_label, int(unlock_time) / 60, int(unlock_time) % 60]


## S05-03: the more there is to lose, the brighter the light over home.
func set_call(strength: float) -> void:
	call_strength = clampf(strength, 0.0, 1.0)
	if _home_light != null:
		_home_light.scale = Vector3(1.0 + 0.5 * call_strength, 1.0, 1.0 + 0.5 * call_strength)


## True while the light over this exit is showing the way home.
func is_showing_way_home() -> bool:
	return _home_light != null and _home_light.visible


func _process(delta: float) -> void:
	if _home_light == null or not _home_light.visible:
		return
	_time += delta
	var mat := _home_light.material_override as StandardMaterial3D
	mat.albedo_color.a = 0.22 + 0.2 * call_strength + 0.08 * sin(_time * (1.6 + call_strength))


static func _build_home_light() -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.9
	mesh.bottom_radius = 0.45
	mesh.height = HOME_LIGHT_HEIGHT
	mesh.cap_top = false
	mesh.cap_bottom = false
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(0.55, 1.0, 0.7, 0.25)
	var light := MeshInstance3D.new()
	light.name = "HomeLight"
	light.mesh = mesh
	light.material_override = mat
	light.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	light.position.y = HOME_LIGHT_HEIGHT * 0.5
	light.visible = false
	return light
