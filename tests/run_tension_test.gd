extends "res://tests/test_case.gd"
## Sprint 05 S05-03: the Run Tension Director. What is at stake after going
## home became possible turns into mood — the light towards evening, home
## calling more strongly — and never into rules.

const TEST_SAVE: String = "user://tests/run_tension_save.json"

var _tree: SceneTree


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_tree = get_tree()
	_test_compute()
	await _test_walk()
	finish()


func _test_compute() -> void:
	var balance := DataRegistry.balance
	var calm := {"extraction_open": false, "seconds_since_open": 999.0, "unbanked_value": 999, "distance_home": 99.0, "temptation": true}
	check_eq(RunTensionDirector.compute(calm, balance), 0.0, "no tension before going home is possible: staying is not yet a choice")
	var just_open := {"extraction_open": true, "seconds_since_open": 0.0, "unbanked_value": 0, "distance_home": 0.0}
	check_eq(RunTensionDirector.compute(just_open, balance), 0.0, "nothing at stake, nothing waited: calm")
	var carrying := {"extraction_open": true, "seconds_since_open": 0.0, "unbanked_value": balance.risk_heavy_value, "distance_home": 0.0}
	var carrying_far := carrying.duplicate()
	carrying_far["distance_home"] = balance.tension_far_distance
	var near := RunTensionDirector.compute(carrying, balance)
	var far := RunTensionDirector.compute(carrying_far, balance)
	check(near > 0.2, "carrying a lot is tense (%.2f)" % near)
	check(far > near, "and more so far from home (%.2f > %.2f)" % [far, near])
	var empty_far := {"extraction_open": true, "seconds_since_open": 0.0, "unbanked_value": 0, "distance_home": balance.tension_far_distance}
	check_eq(RunTensionDirector.compute(empty_far, balance), 0.0, "far from home with nothing to lose is not tense")
	var stayed := {"extraction_open": true, "seconds_since_open": balance.tension_ramp_seconds, "unbanked_value": 0, "distance_home": 0.0}
	check(RunTensionDirector.compute(stayed, balance) > 0.3, "staying out long after home opened turns the walk")
	var everything := {"extraction_open": true, "seconds_since_open": 9999.0, "unbanked_value": 9999, "distance_home": 999.0, "temptation": true, "territory_marked": true}
	check_eq(RunTensionDirector.compute(everything, balance), 1.0, "capped at 1")


func _test_walk() -> void:
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
	await _frames(5)
	var map := _tree.current_scene as RunMap3D
	var run := map.run_manager
	var tension := map.tension
	check(tension != null, "the walk has a tension director")
	var bus := map.get_node("ExtractionPoints/bus_stop") as ExtractionPoint3D
	var sky_before: Color = map._environment.background_color
	await _frames(30)
	check_eq(tension.level, 0.0, "calm while home is not yet open")

	run.debug_give_item(&"boxing_gloves", 6)
	run.debug_unlock_all_extractions()
	var rng_state := run.run_rng.state
	# Far from home, carrying a lot: the mood eases in over a few seconds.
	map.dog.global_position = bus.global_position + Vector3(-28, 0.3, -10)
	for i in 600:
		await _tree.process_frame
		if tension.level >= tension.target - 0.01 and tension.target > 0.0:
			break
	check(tension.target > 0.25, "carrying a lot far from an open exit is tense (%.2f)" % tension.target)
	check(tension.level > 0.2, "and the walk eases into it (%.2f)" % tension.level)
	check(map._environment.background_color != sky_before, "the sky turns towards evening")
	check(bus.call_strength > 0.2, "home calls more strongly (%.2f)" % bus.call_strength)
	check_eq(run.run_rng.state, rng_state, "presentation only: the run's randomness is untouched")
	check_eq(tension.debug_text().begins_with("Tension:"), true, "debug text")

	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(TEST_SAVE)


func _frames(count: int) -> void:
	for i in count:
		await _tree.process_frame


func _wait_for_scene(path: String) -> void:
	for i in 300:
		await _tree.process_frame
		if _tree.current_scene != null and _tree.current_scene.scene_file_path == path:
			await _tree.process_frame
			return
	check(false, "timed out waiting for scene %s" % path)
