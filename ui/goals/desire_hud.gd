class_name DesireHUD
extends CanvasLayer
## Lightweight, dog-voiced desire display: what the dog wants now, a short
## popup when a new thought appears / resolves, and a nose arrow towards the
## thing it wants. No quest log, no counters.

const POPUP_SECONDS: float = 2.6
const ARROW_RADIUS: float = 250.0
## Arrow hides when the target is already on screen.
## Meters (scaled by the director's units_per_meter).
const ARROW_MIN_DISTANCE: float = 4.75
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
@onready var _card: DesireCard = %DesireCard
@onready var _popup: Label = %DesirePopup
@onready var _arrow: Label = %HintArrow


func _ready() -> void:
	_popup.hide()
	_arrow.hide()
	_card.hide()
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
	# The first active desire is the primary dog thought. Emergent thoughts are
	# announced as popups; keeping one card prevents a quest-log silhouette.
	var primary: DesireData = null
	if not director.active_desires().is_empty():
		primary = director.active_desires()[0]
	if primary == null:
		_card.hide()
	else:
		if primary.layer == DesireData.Layer.THREAD:
			_card.present_thread(primary)
		else:
			_card.present(primary)
	# Keep the old text node updated but hidden for compatibility/debug tooling.
	_list.text = "\n".join(lines)
	_list.visible = false


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
	var dog := run_manager.dog_actor
	if dog == null or not run_manager.is_running():
		_arrow.hide()
		return
	var target: Variant = director.hint_position(dog.global_position)
	if target == null or dog.global_position.distance_to(target) < ARROW_MIN_DISTANCE * director.units_per_meter:
		_arrow.hide()
		return
	var direction := _screen_direction(dog, target)
	if direction == Vector2.ZERO:
		_arrow.hide()
		return
	var center := _arrow.get_viewport_rect().size / 2.0
	_arrow.show()
	_arrow.pivot_offset = _arrow.size / 2.0
	_arrow.position = center + direction * ARROW_RADIUS - _arrow.size / 2.0
	_arrow.rotation = direction.angle()


## On-screen direction from the dog to the target. In 3D the target is
## projected through the camera (flipped when it is behind the camera).
func _screen_direction(dog: Node, target: Variant) -> Vector2:
	if dog is Node2D:
		return ((target as Vector2) - (dog as Node2D).global_position).normalized()
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return Vector2.ZERO
	var from := camera.unproject_position((dog as Node3D).global_position)
	var to := camera.unproject_position(target as Vector3)
	var direction := (to - from).normalized()
	if camera.is_position_behind(target as Vector3):
		direction = -direction
	return direction
