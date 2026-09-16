class_name DebugPanel
extends Control
## All Sprint 01 debug actions in one place. Removed from non-debug builds.
## Hidden by default (blind QA): open with F1, or tap the run timer 5 times quickly.

@export var run_manager: RunManager

@onready var _info_label: Label = %InfoLabel
@onready var _body: Control = %Body


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	_body.hide()
	_bind(%AddMinuteButton, func() -> void: run_manager.debug_add_time(60.0))
	_bind(%SetTimeButton, func() -> void: run_manager.debug_skip_to_next_unlock(10.0))
	_bind(%UnlockButton, func() -> void: run_manager.debug_unlock_all_extractions())
	_bind(%GiveBallButton, func() -> void: run_manager.debug_give_item(&"tennis_ball"))
	_bind(%GiveMysteryButton, func() -> void: run_manager.debug_give_item(&"mysterious_item"))
	_bind(%GiveGlovesButton, func() -> void: run_manager.debug_give_item(&"boxing_gloves"))
	_bind(%ClearBagButton, func() -> void: run_manager.human_run_inventory.clear())
	_bind(%ExtractButton, func() -> void: run_manager.extract(&"debug"))
	_bind(%FailButton, func() -> void: run_manager.fail_run())


func _process(_delta: float) -> void:
	if run_manager == null:
		return
	if Input.is_action_just_pressed("debug_panel"):
		toggle()
	if _body.visible:
		var seconds := int(run_manager.elapsed_time)
		_info_label.text = "Run %02d:%02d   Seed %d" % [seconds / 60, seconds % 60, run_manager.run_seed]


func toggle() -> void:
	_body.visible = not _body.visible


func _bind(button: Button, action: Callable) -> void:
	button.pressed.connect(action)
