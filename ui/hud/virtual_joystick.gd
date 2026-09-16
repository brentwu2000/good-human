class_name VirtualJoystick
extends Control
## Floating touch joystick. The stick appears where the finger lands inside this
## control and drives the same Input Map actions as the keyboard, so gameplay
## code never knows which device is used.

@export var radius: float = 110.0
@export var knob_radius: float = 48.0
@export var action_left: StringName = &"move_left"
@export var action_right: StringName = &"move_right"
@export var action_up: StringName = &"move_up"
@export var action_down: StringName = &"move_down"

## Current output, length 0..1.
var output: Vector2 = Vector2.ZERO

var _touch_index: int = -1
var _base_position: Vector2 = Vector2.ZERO
var _knob_position: Vector2 = Vector2.ZERO
var _pressed_actions: Dictionary[StringName, bool] = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reset_stick()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_drag(event as InputEventScreenDrag)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _touch_index != -1 or not is_visible_in_tree():
			return
		var local := _to_local(event.position)
		if not Rect2(Vector2.ZERO, size).has_point(local):
			return
		_touch_index = event.index
		_base_position = local
		_update_stick(local)
		get_viewport().set_input_as_handled()
	elif event.index == _touch_index:
		_touch_index = -1
		_reset_stick()
		get_viewport().set_input_as_handled()


func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index != _touch_index:
		return
	_update_stick(_to_local(event.position))
	get_viewport().set_input_as_handled()


func _update_stick(local: Vector2) -> void:
	var offset := (local - _base_position).limit_length(radius)
	_knob_position = _base_position + offset
	_set_output(offset / radius)


func _reset_stick() -> void:
	_base_position = size * Vector2(0.5, 0.6)
	_knob_position = _base_position
	_set_output(Vector2.ZERO)


func _set_output(value: Vector2) -> void:
	output = value
	_apply_axis(action_left, action_right, value.x)
	_apply_axis(action_up, action_down, value.y)
	queue_redraw()


func _apply_axis(negative: StringName, positive: StringName, value: float) -> void:
	_apply_action(negative, maxf(-value, 0.0))
	_apply_action(positive, maxf(value, 0.0))


func _apply_action(action: StringName, strength: float) -> void:
	if strength > 0.0:
		Input.action_press(action, strength)
		_pressed_actions[action] = true
	elif _pressed_actions.has(action):
		# Only release what the joystick pressed, so held keyboard keys survive.
		Input.action_release(action)
		_pressed_actions.erase(action)


func _to_local(viewport_position: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * viewport_position


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED:
			if _touch_index == -1:
				_reset_stick()
		NOTIFICATION_VISIBILITY_CHANGED, NOTIFICATION_EXIT_TREE:
			if _touch_index != -1:
				_touch_index = -1
				_reset_stick()


func _draw() -> void:
	var active := _touch_index != -1
	draw_circle(_base_position, radius, Color(1, 1, 1, 0.18 if active else 0.08))
	draw_arc(_base_position, radius, 0.0, TAU, 48, Color(1, 1, 1, 0.35), 3.0)
	draw_circle(_knob_position, knob_radius, Color(1, 1, 1, 0.6 if active else 0.3))
