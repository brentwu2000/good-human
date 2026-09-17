class_name DesireHUD
extends CanvasLayer
## Lightweight, dog-voiced desire display: what the dog wants now, a short
## popup when a new thought appears / resolves, and a nose arrow towards the
## thing it wants. No quest log, no counters.

const POPUP_SECONDS: float = 2.6
const ARROW_RADIUS: float = 250.0
## Arrow hides when the target is already on screen.
const ARROW_MIN_DISTANCE: float = 380.0
const CATEGORY_ICONS: Dictionary = {
	DesireData.Category.SCENT: "👃",
	DesireData.Category.CHASE: "🐿",
	DesireData.Category.RIVAL: "🐕",
	DesireData.Category.BRING_HOME: "🏠",
	DesireData.Category.DISCOVERY: "✨",
	DesireData.Category.THREAT: "😰",
}

@export var director: GoalDirector
@export var run_manager: RunManager

var _popups: Array[Dictionary] = []
var _popup_left: float = 0.0

@onready var _list: Label = %DesireList
@onready var _popup: Label = %DesirePopup
@onready var _arrow: Label = %HintArrow


func _ready() -> void:
	_popup.hide()
	_arrow.hide()
	director.desire_started.connect(_on_started)
	director.desire_completed.connect(func(d: DesireData) -> void: _queue("✔ " + (d.complete_text if not d.complete_text.is_empty() else d.dog_text), Color(0.6, 1.0, 0.6)))
	director.desire_failed.connect(_on_failed)
	run_manager.run_started.connect(func(_s: int) -> void: _popups.clear())


func _process(delta: float) -> void:
	_update_list()
	_update_popup(delta)
	_update_arrow()


static func line_for(desire: DesireData) -> String:
	var icon: String = CATEGORY_ICONS.get(desire.category, "🐶")
	var text := "%s %s" % [icon, desire.dog_text]
	if not desire.world_hint.is_empty():
		text += "\n    （%s）" % desire.world_hint
	return text


func _on_started(desire: DesireData, reason: StringName) -> void:
	match reason:
		&"emergent":
			_queue("💡 新念頭：" + desire.dog_text, Color(1.0, 0.9, 0.5))
		&"follow_up":
			_queue("➡ " + desire.dog_text, Color(0.8, 0.9, 1.0))
		_:
			_queue("🐶 " + desire.dog_text, Color.WHITE)


func _on_failed(desire: DesireData) -> void:
	if not desire.fail_text.is_empty():
		_queue("✘ " + desire.fail_text, Color(1.0, 0.7, 0.6))


func _update_list() -> void:
	var lines: Array[String] = []
	for desire in director.active_desires():
		lines.append(line_for(desire))
	_list.text = "\n".join(lines)
	_list.visible = not lines.is_empty()


func _queue(text: String, color: Color) -> void:
	_popups.append({"text": text, "color": color})


func _update_popup(delta: float) -> void:
	if _popup_left > 0.0:
		_popup_left -= delta
		if _popup_left <= 0.0:
			_popup.hide()
		return
	if _popups.is_empty():
		return
	var next: Dictionary = _popups.pop_front()
	_popup.text = next["text"]
	_popup.modulate = next["color"]
	_popup.show()
	_popup_left = POPUP_SECONDS


func _update_arrow() -> void:
	var dog := run_manager.dog
	if dog == null or not run_manager.is_running():
		_arrow.hide()
		return
	var target: Variant = director.hint_position(dog.global_position)
	if target == null or dog.global_position.distance_to(target) < ARROW_MIN_DISTANCE:
		_arrow.hide()
		return
	var direction: Vector2 = ((target as Vector2) - dog.global_position).normalized()
	var center := _arrow.get_viewport_rect().size / 2.0
	_arrow.show()
	_arrow.pivot_offset = _arrow.size / 2.0
	_arrow.position = center + direction * ARROW_RADIUS - _arrow.size / 2.0
	_arrow.rotation = direction.angle()
