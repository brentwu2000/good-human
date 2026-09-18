class_name ScentCue3D
extends Interactable3D
## 3D strange smell (same role as ScentCue): only visible and sniffable while
## a dog desire points at it.

signal sniffed(cue: ScentCue3D)

@export var cue_id: StringName

var active: bool = false

var _swirl: Node3D
var _time: float = 0.0


func _enter_tree() -> void:
	add_to_group(ScentCue.GROUP)


func _ready() -> void:
	prompt = "👃 追味道"
	_swirl = GoalVisual3D.scent()
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
	_swirl.position.y = 0.08 + sin(_time * 2.5) * 0.06
	_swirl.rotation.y = _time * 0.45
	_swirl.scale = Vector3.ONE * (0.92 + sin(_time * 4.0) * 0.08)
	for i in _swirl.get_child_count() - 1:
		var wisp := _swirl.get_child(i) as Node3D
		if wisp != null:
			wisp.position.z = sin(_time * 2.0 + i * 1.8) * 0.08
