class_name ExtractionPoint
extends Interactable
## Timed exit. RunManager decides availability from elapsed time.

const GROUP: StringName = &"extraction_points"

@export var extraction_id: StringName
@export var display_label: String = "撤離點"
@export var unlock_time: float = 300.0
## Shown by the HUD when this point unlocks.
@export var unlock_message: String = "現在可以撤離"

var available: bool = false

@onready var _visual: CanvasItem = %Visual
@onready var _name_label: Label = %NameLabel


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	if prompt == "互動":
		prompt = "🚪 撤離"
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
	if not is_node_ready():
		return
	_visual.modulate = Color(0.4, 1.0, 0.5) if available else Color(0.55, 0.55, 0.55)
	if available:
		_name_label.text = "%s（可撤離）" % display_label
	else:
		_name_label.text = "%s（%02d:%02d 開放）" % [display_label, int(unlock_time) / 60, int(unlock_time) % 60]
