class_name TouchActionButton
extends Button
## Holds an Input Map action while touched or clicked. Handles screen touches
## directly so it works while another finger is on the joystick.

@export var action: StringName = &"interact"

var _touch_index: int = -1
var _mouse_held: bool = false
var _action_pressed: bool = false


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE


func _input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch == null:
		return
	if touch.pressed:
		if _touch_index != -1 or disabled or not is_visible_in_tree():
			return
		var local := get_global_transform_with_canvas().affine_inverse() * touch.position
		if not Rect2(Vector2.ZERO, size).has_point(local):
			return
		_touch_index = touch.index
		_update_action()
		get_viewport().set_input_as_handled()
	elif touch.index == _touch_index:
		_touch_index = -1
		_update_action()
		get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	# Mouse events emulated from touch are already handled in _input.
	if mouse == null or mouse.button_index != MOUSE_BUTTON_LEFT or mouse.device == InputEvent.DEVICE_ID_EMULATION:
		return
	_mouse_held = mouse.pressed and not disabled
	_update_action()


func _update_action() -> void:
	var held := _touch_index != -1 or _mouse_held
	if held == _action_pressed:
		return
	_action_pressed = held
	# Only release what this button pressed, so a held keyboard key survives.
	if held:
		Input.action_press(action)
	else:
		Input.action_release(action)
	modulate = Color(0.75, 0.75, 0.75) if held else Color.WHITE


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED or what == NOTIFICATION_EXIT_TREE:
		if _touch_index != -1 or _mouse_held:
			_touch_index = -1
			_mouse_held = false
			_update_action()
