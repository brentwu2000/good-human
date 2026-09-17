class_name ScentCue3D
extends Interactable3D
## 3D strange smell (same role as ScentCue): only visible and sniffable while
## a dog desire points at it.

signal sniffed(cue: ScentCue3D)

@export var cue_id: StringName

var active: bool = false

var _swirl: Label3D
var _time: float = 0.0


func _enter_tree() -> void:
	add_to_group(ScentCue.GROUP)


func _ready() -> void:
	prompt = "👃 追味道"
	_swirl = Greybox.label("〰？〰", 0.9, 48, Color(0.85, 0.6, 1.0), 40.0)
	add_child(_swirl)
	add_interaction_area(1.0)
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
	_swirl.position.y = 0.9 + sin(_time * 2.5) * 0.15
	_swirl.modulate.a = 0.6 + sin(_time * 4.0) * 0.4
