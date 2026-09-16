extends "res://tests/test_case.gd"
## P0-007 Interactable focus, P0-011 SearchPoint, P0-013 RunManager,
## P0-014 ExtractionPoint, P0-016 stash apply, P0-017 run reset.

const DOG_SCENE: PackedScene = preload("res://actors/dog/dog.tscn")
const SEARCH_POINT_SCENE: PackedScene = preload("res://world/search_point/search_point.tscn")
const EXTRACTION_SCENE: PackedScene = preload("res://world/extraction/extraction_point.tscn")
const TRASH_TABLE: LootTableData = preload("res://data/loot_tables/residential_trash.tres")
const SEED: int = 777
const TEST_SAVE: String = "user://tests/run_core_save.json"

var run: RunManager
var dog: DogController
var trash_point: SearchPoint
var ball_point: SearchPoint
var ext_a: ExtractionPoint
var ext_b: ExtractionPoint
var ball_table: LootTableData
var ended: Array[RunResult] = []
var unlocked: Array[StringName] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_build_world()
	await _physics(2)

	await _test_focus()
	await _test_search_uses_run_rng()
	await _test_cannot_research()
	await _test_walk_away_cancels()
	await _test_full_bag_keeps_pending_loot()
	_test_extraction_unlock_times()
	await _test_extract_through_interaction()
	_test_fail_run_keeps_safe_slots()
	_test_second_run_resets()
	_test_finish_run_updates_stash_and_save()
	finish()


func _build_world() -> void:
	trash_point = _add_point(&"trash_1", Vector2(0, 0), TRASH_TABLE)
	ball_table = LootTableData.new()
	var entry := LootEntry.new()
	entry.item = DataRegistry.get_item(&"tennis_ball")
	entry.weight = 1
	ball_table.entries = [entry]
	ball_point = _add_point(&"ball_1", Vector2(600, 0), ball_table)

	ext_a = _add_extraction(&"bus_stop", Vector2(0, 600), 300.0)
	ext_b = _add_extraction(&"north_gate", Vector2(600, 600), 480.0)

	dog = DOG_SCENE.instantiate() as DogController
	dog.position = Vector2(0, 1500)
	add_child(dog)

	run = RunManager.new()
	run.dog = dog
	run.auto_start = false
	run.report_to_game = false
	add_child(run)
	run.run_ended.connect(func(r: RunResult) -> void: ended.append(r))
	run.extraction_unlocked.connect(func(p: ExtractionPoint) -> void: unlocked.append(p.extraction_id))
	run.start_run(SEED)


func _test_focus() -> void:
	check(dog.focused == null, "no focus far from points")
	await _move_dog(trash_point.global_position + Vector2(40, 0))
	check(dog.focused == trash_point, "nearby search point focused")
	check_eq(dog.focused.get_prompt(run), "👃 聞聞看", "search prompt")
	await _move_dog(ext_a.global_position)
	check(dog.focused == null, "locked extraction point is not focusable")


func _test_search_uses_run_rng() -> void:
	# Points roll at run start sorted by search_id: ball_1 first, then trash_1.
	var expected_rng := RandomNumberGenerator.new()
	expected_rng.seed = SEED
	ball_table.roll(expected_rng)
	var expected := TRASH_TABLE.roll(expected_rng)
	check_eq(trash_point.get_scent_rarity(), -1 if expected == null else expected.item.rarity, "scent matches pre-rolled loot")

	await _move_dog(trash_point.global_position)
	await _press_interact()
	check(trash_point.is_searching(), "interact starts search")
	check(not run.is_searched(&"trash_1"), "not searched until progress completes")
	await _wait_seconds(trash_point.search_duration + 0.2)
	check(not trash_point.is_searching(), "search completes after duration")
	check(run.is_searched(&"trash_1"), "point marked searched")
	if expected == null:
		check(run.human_run_inventory.is_empty(), "seeded roll gave nothing, bag empty")
	else:
		check_eq(run.human_run_inventory.count_item(expected.item_id), expected.quantity, "loot follows run seed (%s)" % expected.item_id)


func _test_cannot_research() -> void:
	check(not trash_point.can_interact(run), "searched point cannot be searched again this run")
	await _physics(2)
	check(dog.focused != trash_point, "searched point loses focus")
	await _press_interact()
	check(not trash_point.is_searching(), "interact on searched point does nothing")


func _test_walk_away_cancels() -> void:
	await _move_dog(ball_point.global_position)
	await _press_interact()
	check(ball_point.is_searching(), "ball search started")
	dog.global_position = ball_point.global_position + Vector2(0, 500)
	await _physics(3)
	await _wait_seconds(0.1)
	check(not ball_point.is_searching(), "walking away cancels search")
	check(not run.is_searched(&"ball_1"), "cancelled search not marked")


func _test_full_bag_keeps_pending_loot() -> void:
	run.human_run_inventory.clear()
	run.debug_give_item(&"boxing_gloves", 8)
	var blocked: Array[int] = [0]
	var on_blocked := func(_item: ItemData, quantity: int) -> void: blocked[0] += quantity
	run.loot_blocked.connect(on_blocked)

	await _move_dog(ball_point.global_position)
	await _press_interact()
	await _wait_seconds(ball_point.search_duration + 0.2)
	check(blocked[0] >= 1, "full bag reports blocked loot")
	check(not run.is_searched(&"ball_1"), "blocked point stays searchable")

	run.human_run_inventory.take_stack(0)
	var rng_state := run.run_rng.state
	await _press_interact()
	await _wait_seconds(ball_point.search_duration + 0.2)
	check(run.is_searched(&"ball_1"), "point completes once there is room")
	check_eq(run.human_run_inventory.count_item(&"tennis_ball"), blocked[0], "pending loot delivered")
	check_eq(run.run_rng.state, rng_state, "pending loot is not re-rolled")
	run.loot_blocked.disconnect(on_blocked)


func _test_extraction_unlock_times() -> void:
	check(not run.is_extraction_available(&"bus_stop"), "bus stop locked at start")
	run.debug_set_time(299.0)
	check(not run.is_extraction_available(&"bus_stop"), "bus stop locked at 4:59")
	run.debug_set_time(300.0)
	check(run.is_extraction_available(&"bus_stop"), "bus stop open at 5:00")
	check(not run.is_extraction_available(&"north_gate"), "north gate locked at 5:00")
	check_eq(unlocked, [&"bus_stop"] as Array[StringName], "unlock signal once for bus stop")
	run.debug_set_time(480.0)
	check(run.is_extraction_available(&"north_gate"), "north gate open at 8:00")
	check_eq(unlocked.size(), 2, "unlock signal for north gate")


func _test_extract_through_interaction() -> void:
	run.dog_safe_inventory.add_item(DataRegistry.get_item(&"mysterious_item"))
	await _move_dog(ext_a.global_position)
	check(dog.focused == ext_a, "open extraction point focusable")
	await _press_interact()
	check_eq(ended.size(), 1, "run ended once")
	check_eq(run.run_status, RunManager.RunStatus.EXTRACTED, "status extracted")
	var result := ended[0]
	check(result.is_success(), "result success")
	check_eq(result.extraction_id, &"bus_stop", "result extraction id")
	check_eq(result.run_seed, SEED, "result seed")
	check_eq(_count(result.to_stash, &"mysterious_item"), 1, "dog safe item brought home")
	check_eq(_count(result.to_stash, &"boxing_gloves"), 7, "human bag items brought home")
	check(result.lost.is_empty(), "nothing lost on extraction")
	run.extract(&"bus_stop")
	check_eq(ended.size(), 1, "extract after end is ignored")


func _test_fail_run_keeps_safe_slots() -> void:
	run.start_run(SEED + 1)
	run.debug_give_item(&"boxing_gloves", 1)
	run.dog_safe_inventory.add_item(DataRegistry.get_item(&"mysterious_item"))
	run.fail_run()
	var result := ended[-1]
	check(not result.is_success(), "failed result")
	check_eq(_count(result.lost, &"boxing_gloves"), 1, "human bag lost on failure")
	check_eq(_count(result.to_stash, &"mysterious_item"), 1, "safe slot kept on failure")


func _test_second_run_resets() -> void:
	run.start_run(SEED + 2)
	check(run.is_running(), "second run running")
	check(run.searched_points.is_empty(), "searched points reset")
	check(run.human_run_inventory.is_empty() and run.dog_safe_inventory.is_empty(), "run inventories reset")
	check(not run.is_extraction_available(&"bus_stop"), "extractions locked again")
	check(trash_point.can_interact(run), "search point searchable again")
	check_eq(run.elapsed_time, 0.0, "timer reset")
	run.start_run()
	check(run.run_seed != 0, "random seed generated when none given")


func _test_finish_run_updates_stash_and_save() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_SAVE.get_base_dir())
	var original_path := SaveManager.save_path
	var original_data := SaveManager.data.duplicate(true)
	var original_stash := Game.home_stash.serialize()
	SaveManager.save_path = TEST_SAVE
	SaveManager.reset_to_default()
	Game.home_stash.clear()
	Game.home_stash.add_item(DataRegistry.get_item(&"boxing_gloves"), 29)

	var result := RunResult.new()
	result.outcome = RunResult.Outcome.EXTRACTED
	result.to_stash = [
		ItemStack.new(DataRegistry.get_item(&"tennis_ball"), 2),
		ItemStack.new(DataRegistry.get_item(&"umbrella"), 1),
	]
	Game.finish_run(result, false)
	check_eq(Game.home_stash.count_item(&"tennis_ball"), 2, "extracted items in stash")
	check_eq(_count(result.stash_overflow, &"umbrella"), 1, "items beyond 30 slots reported as overflow")
	check_eq(SaveManager.data["statistics"]["runs"], 1, "runs counted")
	check_eq(SaveManager.data["statistics"]["successful_extractions"], 1, "successful extraction counted")

	SaveManager.load_game()
	Game.load_profile()
	check_eq(Game.home_stash.count_item(&"tennis_ball"), 2, "stash survives save/load")
	check(Game.last_run_result == result, "last result stored")

	DirAccess.remove_absolute(TEST_SAVE)
	SaveManager.save_path = original_path
	SaveManager.data = original_data
	Game.home_stash.deserialize(original_stash, DataRegistry.get_item)


# --- helpers ---------------------------------------------------------------

func _add_point(id: StringName, at: Vector2, table: LootTableData) -> SearchPoint:
	var point := SEARCH_POINT_SCENE.instantiate() as SearchPoint
	point.search_id = id
	point.loot_table = table
	point.search_duration = 0.3
	point.position = at
	add_child(point)
	return point


func _add_extraction(id: StringName, at: Vector2, unlock: float) -> ExtractionPoint:
	var point := EXTRACTION_SCENE.instantiate() as ExtractionPoint
	point.extraction_id = id
	point.unlock_time = unlock
	point.position = at
	add_child(point)
	return point


func _move_dog(to: Vector2) -> void:
	dog.global_position = to
	dog.velocity = Vector2.ZERO
	await _physics(3)


func _press_interact() -> void:
	Input.action_press(&"interact")
	await _physics(1)
	Input.action_release(&"interact")
	await _physics(1)


func _wait_seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _physics(frames: int) -> void:
	for i in frames:
		await get_tree().physics_frame


func _count(stacks: Array[ItemStack], id: StringName) -> int:
	var total := 0
	for stack in stacks:
		if stack.item_id == id:
			total += stack.quantity
	return total
