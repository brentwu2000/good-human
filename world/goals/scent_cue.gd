class_name ScentCue
extends Interactable
## A strange smell in the world. Only noticeable (and sniffable) while a dog
## desire points at it; sniffing it is a semantic event for GoalDirector.

signal sniffed(cue: ScentCue)

const GROUP: StringName = &"scent_cues"

@export var cue_id: StringName

var active: bool = false

var _time: float = 0.0

@onready var _visual: Label = %Visual


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	prompt = "👃 追味道"
	set_active(false)


func set_active(value: bool) -> void:
	active = value
	visible = value


func can_interact(context: Object) -> bool:
	var run := context as RunManager
	return enabled and active and run != null and run.is_running()


func interact(context: Object) -> void:
	if can_interact(context):
		sniffed.emit(self)


func _process(delta: float) -> void:
	if not active:
		return
	_time += delta
	_visual.position.y = -40.0 + sin(_time * 2.5) * 8.0
	_visual.self_modulate.a = 0.6 + sin(_time * 4.0) * 0.4
