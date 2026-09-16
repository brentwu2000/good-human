extends "res://tests/test_case.gd"
## P0-004: DogController moves through the Input Map, faces movement, collides with world.

const DOG_SCENE: PackedScene = preload("res://actors/dog/dog.tscn")
const ACTIONS: Array[StringName] = [
	&"move_left", &"move_right", &"move_up", &"move_down", &"interact", &"inventory", &"debug_panel",
]


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	for action in ACTIONS:
		check(InputMap.has_action(action), "Input Map has %s" % action)

	await _test_moves_and_stops()
	await _test_diagonal_not_faster()
	await _test_blocked_by_world()
	finish()


func _test_moves_and_stops() -> void:
	var dog := _spawn_dog(Vector2.ZERO)
	Input.action_press(&"move_right")
	await _physics_frames(30)
	check(dog.position.x > 50.0, "dog moves right (x=%.1f)" % dog.position.x)
	check(dog.velocity.length() <= dog.move_speed + 0.01, "speed capped at move_speed")
	check_eq(dog.facing, Vector2.RIGHT, "facing right")

	Input.action_release(&"move_right")
	Input.action_press(&"move_left")
	await _physics_frames(30)
	check(dog.get_node("Visual").scale.x < 0.0, "visual flips when moving left")
	Input.action_release(&"move_left")

	await _physics_frames(30)
	check(dog.velocity.is_zero_approx(), "dog stops after release")
	dog.queue_free()


func _test_diagonal_not_faster() -> void:
	var dog := _spawn_dog(Vector2.ZERO)
	Input.action_press(&"move_right")
	Input.action_press(&"move_down")
	await _physics_frames(30)
	check(dog.velocity.length() <= dog.move_speed + 0.01, "diagonal speed capped (%.1f)" % dog.velocity.length())
	check(dog.facing.is_normalized(), "facing normalized")
	Input.action_release(&"move_right")
	Input.action_release(&"move_down")
	dog.queue_free()


func _test_blocked_by_world() -> void:
	var wall := StaticBody2D.new()
	wall.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 400)
	shape.shape = rect
	wall.add_child(shape)
	wall.position = Vector2(1100, 0)
	add_child(wall)

	var dog := _spawn_dog(Vector2(1000, 0))
	Input.action_press(&"move_right")
	await _physics_frames(60)
	Input.action_release(&"move_right")
	check(dog.position.x < 1090.0 - 19.0, "wall blocks dog (x=%.1f)" % dog.position.x)
	dog.queue_free()
	wall.queue_free()


func _spawn_dog(at: Vector2) -> DogController:
	var dog := DOG_SCENE.instantiate() as DogController
	dog.position = at
	add_child(dog)
	return dog


func _physics_frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
