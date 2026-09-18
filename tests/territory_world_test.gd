extends "res://tests/test_case.gd"
## Sprint 05 P4-006 through the real 3D walk: the Big Banyan Tree is a place the
## dog finds and then learns belongs to another dog, and the landmark shows it.

const TEST_SAVE: String = "user://tests/territory_world_save.json"

var _tree: SceneTree


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_tree = get_tree()
	DirAccess.make_dir_recursive_absolute(TEST_SAVE.get_base_dir())
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(TEST_SAVE)
	SaveManager.save_path = TEST_SAVE

	var placeholder := Node.new()
	_tree.root.add_child(placeholder)
	_tree.current_scene = placeholder
	_tree.change_scene_to_file(Game.BOOT_SCENE)
	await _wait_for_scene(Game.HOME_SCENE)
	_tree.current_scene.get_node("%Walk3DButton").pressed.emit()
	await _wait_for_scene(Game.RUN_MAP_3D_SCENE)
	await _physics(5)

	var map := _tree.current_scene as RunMap3D
	var run := map.run_manager
	var dog := map.dog
	var banyan := map.get_node("BanyanTerritory") as TerritoryPoint3D
	var progress := Game.territory_progress
	var found: Array[TerritoryData] = []
	var smelled: Array[TerritoryData] = []
	banyan.discovered.connect(func(t: TerritoryData) -> void: found.append(t))
	banyan.rival_scent_found.connect(func(t: TerritoryData) -> void: smelled.append(t))

	check(banyan != null and banyan.data != null, "the banyan is in the park as a place")
	check(banyan.is_in_group(TerritoryPoint3D.GROUP), "and can be found by group")
	check_eq(progress.state_of(&"banyan"), TerritoryProgress.State.UNKNOWN, "a new dog has never been there")
	check(banyan.landmark != null, "the landmark is built from Codex's kit")
	var knots_unknown := _scent_knots(banyan)

	# Walking past at a distance changes nothing.
	await _put_dog(dog, banyan.global_position + Vector3(20, 0, 0))
	check(found.is_empty(), "the far side of the park is not a discovery")

	# Coming up to the tree: this is a place.
	await _put_dog(dog, banyan.global_position + Vector3(5, 0, 0))
	check_eq(found.size(), 1, "coming near the banyan finds it")
	check_eq(progress.state_of(&"banyan"), TerritoryProgress.State.DISCOVERED, "the dog knows the place now")
	var knots_discovered := _scent_knots(banyan)
	check(knots_discovered > knots_unknown, "a found place shows a scent trace (%d -> %d)" % [knots_unknown, knots_discovered])

	# Passing by is not the same as reading it: the dog has to stay a moment.
	check(smelled.is_empty(), "arriving is not yet understanding whose place it is")
	await _put_dog(dog, banyan.global_position + Vector3(1.5, 0, 0))
	await _physics(int(TerritoryPoint3D.SCENT_SECONDS * 70.0))
	check_eq(smelled.size(), 1, "standing at the roots reads the scents")
	check_eq(progress.state_of(&"banyan"), TerritoryProgress.State.CONTESTED, "another dog lives here")
	check(progress.last_event(&"banyan").contains("別的狗"), "and the place remembers that in the dog's words")
	check(_scent_knots(banyan) > knots_discovered, "the roots now show two dogs' traces")

	# It never runs backwards or fires twice, however long the dog hangs around.
	await _physics(int(TerritoryPoint3D.SCENT_SECONDS * 140.0))
	check_eq(found.size(), 1, "the place is only discovered once")
	check_eq(smelled.size(), 1, "and only understood once")
	check_eq(progress.state_of(&"banyan"), TerritoryProgress.State.CONTESTED, "state holds")

	# The landmark shows what the dog remembers, walk after walk.
	run.start_run(1234)
	await _physics(5)
	check_eq(progress.state_of(&"banyan"), TerritoryProgress.State.CONTESTED, "a new walk does not reset the place")
	finish()


## Number of scent traces on the landmark: the state's world read (D5-07).
func _scent_knots(point: TerritoryPoint3D) -> int:
	var count := 0
	for child in point.landmark.get_children():
		var mesh := child as MeshInstance3D
		if mesh != null and mesh.mesh is SphereMesh and (mesh.mesh as SphereMesh).radius < 0.12:
			count += 1
	return count


func _put_dog(dog: Node3D, to: Vector3) -> void:
	dog.global_position = Vector3(to.x, 0.1, to.z)
	dog.velocity = Vector3.ZERO
	await _physics(4)


func _physics(frames: int) -> void:
	for i in frames:
		await _tree.physics_frame


func _wait_for_scene(path: String) -> void:
	for i in 300:
		await _tree.process_frame
		if _tree.current_scene != null and _tree.current_scene.scene_file_path == path:
			await _tree.process_frame
			return
	check(false, "timed out waiting for scene %s" % path)
