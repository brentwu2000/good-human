extends "res://tests/test_case.gd"
## P0-002: Boot → Home.


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	# Hand "current scene" to a placeholder so the scene change frees it, not this test.
	var placeholder := Node.new()
	get_tree().root.add_child(placeholder)
	get_tree().current_scene = placeholder

	get_tree().change_scene_to_file(Game.BOOT_SCENE)
	for i in 10:
		await get_tree().process_frame

	var current := get_tree().current_scene
	check(current != null, "a current scene exists")
	if current != null:
		check_eq(current.scene_file_path, Game.HOME_SCENE, "Boot leads to Home")
		var walk_button := current.get_node_or_null("%WalkButton") as Button
		check(walk_button != null, "Home has WalkButton")
	finish()
