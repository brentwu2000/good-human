class_name ExtractionPoint3D
extends Interactable3D
## 3D timed exit. RunManager decides availability from elapsed time.

@export var extraction_id: StringName
@export var display_label: String = "撤離點"
@export var unlock_time: float = 60.0
@export var unlock_message: String = "現在可以撤離"

var available: bool = false

var _marker: MeshInstance3D
var _name_label: Label3D


func _enter_tree() -> void:
	add_to_group(ExtractionPoint.GROUP)


func _ready() -> void:
	prompt = "🚪 撤離"
	add_child(Greybox.box(Vector3(1.6, 0.05, 1.6), Color(0.3, 0.6, 0.9), Vector3(0, 0.03, 0)))
	_marker = Greybox.cylinder(0.12, 2.4, Color(0.55, 0.55, 0.55), Vector3(0, 1.2, 0))
	add_child(_marker)
	_name_label = Greybox.label("", 2.8, 34)
	add_child(_name_label)
	add_interaction_area(1.1)
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
	if _marker == null:
		return
	var mat := _marker.get_surface_override_material(0) as StandardMaterial3D
	mat.albedo_color = Color(0.4, 1.0, 0.5) if available else Color(0.55, 0.55, 0.55)
	if available:
		_name_label.text = "%s（可撤離）" % display_label
	else:
		_name_label.text = "%s（%02d:%02d 開放）" % [display_label, int(unlock_time) / 60, int(unlock_time) % 60]
