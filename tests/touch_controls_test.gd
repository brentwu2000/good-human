extends "res://tests/test_case.gd"
## P0-005: Virtual joystick and interact button drive the same Input Map actions.

const TOUCH_CONTROLS_SCENE: PackedScene = preload("res://ui/hud/touch_controls.tscn")
const DOG_SCENE: PackedScene = preload("res://actors/dog/dog.tscn")

var _joystick: VirtualJoystick
var _button: TouchActionButton


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var controls := TOUCH_CONTROLS_SCENE.instantiate()
	layer.add_child(controls)
	_joystick = controls.get_node("%VirtualJoystick")
	_button = controls.get_node("%InteractButton")
	await get_tree().process_frame

	_test_joystick_axes()
	_test_touch_outside_is_ignored()
	_test_second_finger_does_not_steal_stick()
	await _test_joystick_moves_dog()
	_test_interact_button_while_stick_held()
	_test_keyboard_press_survives_joystick_release()
	finish()


func _test_joystick_axes() -> void:
	var start := _joystick_center()
	_touch(0, start, true)
	_drag(0, start + Vector2(_joystick.radius, 0))
	check(is_equal_approx(Input.get_action_strength(&"move_right"), 1.0), "full right drag = strength 1")
	check_eq(Input.get_action_strength(&"move_left"), 0.0, "left not pressed")

	_drag(0, start + Vector2(0, -_joystick.radius * 0.5))
	check(is_equal_approx(Input.get_action_strength(&"move_up"), 0.5), "half up drag = strength 0.5")
	check(not Input.is_action_pressed(&"move_right"), "right released when stick moves away")

	_drag(0, start + Vector2(_joystick.radius * 3.0, 0))
	check(is_equal_approx(_joystick.output.length(), 1.0), "output clamped to radius")

	_touch(0, start, false)
	check(_joystick.output == Vector2.ZERO, "release resets output")
	for action: StringName in [&"move_left", &"move_right", &"move_up", &"move_down"]:
		check(not Input.is_action_pressed(action), "%s released on touch end" % action)


func _test_touch_outside_is_ignored() -> void:
	var rect := _joystick.get_global_rect()
	_touch(0, Vector2(rect.end.x + 20, rect.position.y - 20), true)
	_drag(0, Vector2(rect.end.x + 200, rect.position.y - 20))
	check(_joystick.output == Vector2.ZERO, "touch outside joystick area ignored")
	_touch(0, Vector2(rect.end.x + 20, rect.position.y - 20), false)


func _test_second_finger_does_not_steal_stick() -> void:
	var start := _joystick_center()
	_touch(0, start, true)
	_drag(0, start + Vector2(0, _joystick.radius))
	_touch(1, start + Vector2(-50, 0), true)
	_drag(1, start + Vector2(-_joystick.radius, 0))
	check(Input.is_action_pressed(&"move_down"), "first finger keeps control")
	check(not Input.is_action_pressed(&"move_left"), "second finger ignored")
	_touch(1, start, false)
	check(Input.is_action_pressed(&"move_down"), "second finger release does not reset stick")
	_touch(0, start, false)


func _test_joystick_moves_dog() -> void:
	var dog := DOG_SCENE.instantiate() as DogController
	add_child(dog)
	var start := _joystick_center()
	_touch(0, start, true)
	_drag(0, start + Vector2(0, -_joystick.radius))
	for i in 30:
		await get_tree().physics_frame
	check(dog.position.y < -50.0, "joystick moves dog through DogController (y=%.1f)" % dog.position.y)
	_touch(0, start, false)
	dog.queue_free()


func _test_interact_button_while_stick_held() -> void:
	var start := _joystick_center()
	_touch(0, start, true)
	_drag(0, start + Vector2(_joystick.radius, 0))

	var button_center := _button.get_global_rect().get_center()
	_touch(1, button_center, true)
	check(Input.is_action_pressed(&"interact"), "interact pressed by second finger")
	check(Input.is_action_pressed(&"move_right"), "stick still held while pressing interact")
	_touch(1, button_center, false)
	check(not Input.is_action_pressed(&"interact"), "interact released")
	_touch(0, start, false)


func _test_keyboard_press_survives_joystick_release() -> void:
	Input.action_press(&"move_left")
	var start := _joystick_center()
	_touch(0, start, true)
	_touch(0, start, false)
	check(Input.is_action_pressed(&"move_left"), "joystick does not release keys it did not press")
	Input.action_release(&"move_left")


func _joystick_center() -> Vector2:
	return _joystick.get_global_rect().get_center()


func _touch(index: int, at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = at
	event.pressed = pressed
	get_viewport().push_input(event, true)


func _drag(index: int, at: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = at
	get_viewport().push_input(event, true)
