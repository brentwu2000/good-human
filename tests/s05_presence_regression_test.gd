extends "res://tests/test_case.gd"
## S05-13: P-04 regression for what Sprint 05 added to the walk. Every new
## reaction that moves a body (the resident going for a marking dog, a rival
## recognising the dog, the old bark answer) has to stop short of the
## player's dog, and nothing Sprint 05 put in the world (rest spots, the
## Banyan's scent call) may block or shove anyone. P-04 itself is covered by
## physical_presence_test, combat_contact_test, combat_spacing_test,
## combat_motion_3d_test and dog_pov_presence_test (tests/run_p04_regression.sh).

const TEST_SAVE: String = "user://tests/s05_presence_save.json"
## Same threshold as physical_presence_test: closer than this, centre to
## centre on the ground, one dog is inside the other.
const PENETRATION: float = 0.4

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
	Game.goal_progress.set_flag(&"rival_beaten")
	Game.territory_progress.advance_to(&"banyan", TerritoryProgress.State.CONTESTED)
	_tree.current_scene.get_node("%Walk3DButton").pressed.emit()
	await _wait_for_scene(Game.RUN_MAP_3D_SCENE)
	await _physics(5)
	var map := _tree.current_scene as RunMap3D
	var run := map.run_manager
	var dog := map.dog
	var resident: OpponentPair3D = null
	for pair in map.coordinator.get_pairs():
		if pair.spot_id == &"banyan_resident":
			resident = pair
	check(resident != null and resident.is_present(), "the resident is home")
	var their_dog := resident._dog

	# A rival that won last time steps up at a dog standing right in front.
	Game.territory_progress.record_rival_fight(resident.encounter.id, false)
	await _put_dog(dog, their_dog.global_position + Vector3(0.75, 0, 0))
	var closest := await _closest_over(dog, their_dog, 60)
	check(resident.recognised_this_walk, "the rival recognised the dog")
	check(closest >= PENETRATION, "S05-07: stepping up stops short of the dog (%.2f m)" % closest)

	# The resident going for a dog that marks the tree right beside them.
	await _put_dog(dog, their_dog.global_position + Vector3(0.75, 0, 0.2))
	resident.react_to_mark(dog.global_position)
	check(resident.riled_this_walk, "the resident reacts to the mark")
	closest = await _closest_over(dog, their_dog, 60)
	check(closest >= PENETRATION, "S05-06: going for a marking dog stops short of it (%.2f m)" % closest)

	# The bark answer (Sprint 04) from close up.
	await _put_dog(dog, their_dog.global_position + Vector3(0.7, 0, -0.2))
	resident.react_to_bark(dog.global_position)
	closest = await _closest_over(dog, their_dog, 60)
	check(closest >= PENETRATION, "barking back stops short of the dog (%.2f m)" % closest)

	# Nothing Sprint 05 put in the world is solid.
	for node_name: String in ["RestBench", "RestBusStop"]:
		var spot := map.get_node(node_name)
		check(spot.find_children("*", "CollisionObject3D", true, false).is_empty(), "%s is a place to stop, not a body" % node_name)
	var banyan := map.get_node("BanyanTerritory") as TerritoryPoint3D
	banyan.set_calling(true)
	check(banyan.get_node("ScentCall").find_children("*", "CollisionObject3D", true, false).is_empty(), "the Banyan's scent call has no collision")
	banyan.set_calling(false)

	# Resting moves no one: the owner stays where the dog let them stop.
	var bench := map.get_node("RestBench") as RestSpot3D
	run.set_owner_condition(0.2)
	map.human.global_position = bench.global_position + Vector3(0.5, 0.1, 0.5)
	map.human.velocity = Vector3.ZERO
	await _put_dog(dog, map.human.global_position + Vector3(0.6, 0, 0))
	var rest_from := map.human.global_position
	await _physics(30)
	check(bench.is_owner_resting(), "the owner rests")
	check(Vector2(map.human.global_position.x - rest_from.x, map.human.global_position.z - rest_from.z).length() < 0.3, "and is not shoved anywhere by it")
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(TEST_SAVE)
	finish()


func _closest_over(a: Node3D, b: Node3D, frames: int) -> float:
	var closest := INF
	for i in frames:
		await _tree.physics_frame
		var d := a.global_position - b.global_position
		closest = minf(closest, Vector2(d.x, d.z).length())
	return closest


func _put_dog(dog: DogController3D, to: Vector3) -> void:
	dog.global_position = Vector3(to.x, 0.1, to.z)
	dog.velocity = Vector3.ZERO
	await _physics(2)


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
