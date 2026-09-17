extends "res://tests/test_case.gd"
## Sprint 02 v0.2 seamless real-time combat through the real scenes:
## provoke in world, dog stays free, spatial disengagement, three fights,
## Old Master defeat, hospital result and loss rules (P1-009..P1-018).

const TEST_SAVE: String = "user://tests/combat_world_save.json"
const OLD_MASTER: FighterData = preload("res://data/combat/fighters/oppx01_old_master.tres")
const SEED: int = 4242

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
	_tree.current_scene.get_node("%WalkButton").pressed.emit()
	await _wait_for_scene(Game.RUN_MAP_SCENE)
	await _physics(3)

	var map := _tree.current_scene
	var run := map.get_node("RunManager") as RunManager
	var coordinator := map.get_node("CombatCoordinator") as CombatCoordinator
	var dog := run.dog
	var human := map.get_node("Actors/Human") as HumanFollower
	var normal_fighter := human.fighter
	coordinator.time_scale = 25.0
	run.start_run(SEED)
	await _physics(2)

	# --- Pairs: 3 ordinary shuffled + Old Master under the big tree ------------
	var pairs: Array[OpponentPair] = []
	pairs.assign(coordinator.get_pairs().filter(func(p: OpponentPair) -> bool: return p.is_present()))
	check(not Game.goal_progress.has_flag(&"rival_revealed"), "fresh save: rival not discovered yet")
	check_eq(pairs.size(), 4, "four pairs in the Run World")
	var ordinary: Array[OpponentPair] = []
	var master: OpponentPair = null
	var ids: Dictionary[StringName, bool] = {}
	for pair in pairs:
		check(pair.encounter != null and pair.state == OpponentPair.State.IDLE, "%s idle with a pair" % pair.spot_id)
		ids[pair.encounter.id] = true
		if pair.encounter.tier == EncounterData.Tier.OVERPOWERED:
			master = pair
		else:
			ordinary.append(pair)
		var label := (pair.get_node("%NameLabel") as Label).text
		check(not label.is_empty() and not _has_digit(label), "pair label has no power number (%s)" % label)
	check_eq(ids.size(), 4, "each pair appears once")
	check(master != null and master.spot_id == &"pair_big_tree", "Old Master under the big tree")
	check(master.encounter.human.display_name == "老爺爺" and master.encounter.dog_scale < 1.0, "Old Master looks harmless")

	run.debug_give_item(&"tennis_ball", 2)
	run.dog_safe_inventory.add_item(DataRegistry.get_item(&"mysterious_item"))

	# --- Walking past is avoidance; provoking is an in-world interaction -------
	var first := ordinary[0]
	await _approach(dog, human, first)
	check(dog.focused == first, "dog can focus a pair")
	check_eq(first.get_prompt(run), "😤 挑釁", "provoke prompt")
	await _physics(10)
	check(human.is_following() and coordinator.engagements.is_empty(), "being near a pair does not start a fight")

	var scene_before := _tree.current_scene
	var human_before := human.global_position
	var time_before := run.elapsed_time
	await _press(&"interact")
	check_eq(coordinator.engagements.size(), 1, "provoke starts an engagement")
	check_eq(human.state, HumanFollower.State.COMBAT, "owner is fighting")
	check_eq(first.state, OpponentPair.State.COMBAT, "pair is fighting")
	check(human.global_position.distance_to(human_before) < 40.0, "owner fights where it stood (no teleport)")
	check(_tree.current_scene == scene_before, "no scene change")
	check(not ordinary[1].can_interact(run), "cannot provoke a second pair mid-fight")

	# Dog stays free and the world keeps running.
	var dog_y := dog.global_position.y
	Input.action_press(&"move_down")
	await _physics(8)
	Input.action_release(&"move_down")
	await _physics(2)
	check(dog.global_position.y > dog_y + 10.0, "dog moves freely during combat")
	check_eq(coordinator.engagements.size(), 1, "fight continues while the dog moves nearby")
	check(run.elapsed_time > time_before, "walk timer keeps running during combat")

	# --- Spatial disengagement ------------------------------------------------
	dog.global_position = human.global_position + Vector2(0, DataRegistry.balance.disengage_distance + 150.0)
	await _physics(3)
	check_eq(coordinator.last_result, CombatSimulation.Result.DISENGAGED, "running away disengages")
	check(coordinator.engagements.is_empty(), "engagement closed")
	check(human.is_following(), "owner follows the dog again")
	check_eq(run.human_run_inventory.count_item(&"tennis_ball"), 2, "disengaging costs no loot")
	check(run.is_running(), "walk continues")
	await _wait_until(func() -> bool: return first.state == OpponentPair.State.IDLE, 600)
	check(first.state == OpponentPair.State.IDLE, "pair walks back and can be provoked again")

	# --- Three ordinary fights, natural and autonomous ------------------------
	# A test-only strong human guarantees natural victories without debug forcing.
	human.fighter = OLD_MASTER
	var gained: Array[int] = [0]
	run.loot_gained.connect(func(_item: ItemData, quantity: int) -> void: gained[0] += quantity)
	for pair in ordinary:
		await _approach(dog, human, pair)
		var gained_before := gained[0]
		await _press(&"interact")
		check_eq(coordinator.engagements.size(), 1, "%s provoked" % pair.spot_id)
		var sim := coordinator.engagements[0].simulation
		await _wait_until(func() -> bool: return coordinator.engagements.is_empty(), 900)
		check_eq(coordinator.last_result, CombatSimulation.Result.VICTORY, "%s beaten" % pair.spot_id)
		check(not sim.fighters[0].uses.is_empty() and not sim.fighters[1].uses.is_empty(), "both humans chose skills themselves")
		check(pair.is_beaten() and not pair.can_interact(run), "beaten pair cannot be provoked again")
		check(gained[0] > gained_before, "victory reward added to the bag")
		check(human.is_following(), "victory returns straight to exploration")
		check(_tree.current_scene == scene_before and run.is_running(), "same walk continues")

	# --- Old Master: natural defeat ---------------------------------------------
	human.fighter = normal_fighter
	(map.get_node("RunHUD").get_node("%DebugPanel").get_node("%NextEncounterButton") as Button).pressed.emit()
	await _physics(4)
	check(dog.focused == master, "debug: next pair puts the dog at the Old Master")
	await _press(&"interact")
	await _wait_until(func() -> bool: return coordinator.last_result == CombatSimulation.Result.DEFEAT, 900)
	check_eq(coordinator.last_result, CombatSimulation.Result.DEFEAT, "the frail old man wins")
	check_eq(human.state, HumanFollower.State.DOWN, "owner is down")
	check(not master.is_beaten(), "Old Master is not beaten")
	check(not master.can_interact(run), "no provoking while the owner is down")
	await _wait_for_scene(Game.RUN_RESULT_SCENE)
	_check_defeat_result()

	# No permanent Game Over: home and a new walk still work.
	_tree.current_scene.get_node("%HomeButton").pressed.emit()
	await _wait_for_scene(Game.HOME_SCENE)
	_tree.current_scene.get_node("%WalkButton").pressed.emit()
	await _wait_for_scene(Game.RUN_MAP_SCENE)
	await _physics(3)
	var next := _tree.current_scene.get_node("CombatCoordinator") as CombatCoordinator
	check(next.get_pairs().all(func(p: OpponentPair) -> bool: return p.state == OpponentPair.State.IDLE), "new walk resets every pair")
	check(next.human.is_following(), "owner recovered on the new walk")

	await _test_debug_force_defeat(_tree.current_scene)

	DirAccess.remove_absolute(TEST_SAVE)
	finish()


func _check_defeat_result() -> void:
	var result := Game.last_run_result
	check_eq(result.outcome, RunResult.Outcome.DEFEATED, "run ended by defeat")
	check_eq(result.defeated_by, "老爺爺", "result names the opponent")
	check_eq(_count(result.lost, &"tennis_ball"), 2, "normal run inventory lost")
	check_eq(_count(result.lost, &"mysterious_item"), 0, "safe item not lost")
	check_eq(_count(result.to_stash, &"mysterious_item"), 1, "dog safe slot survives")
	check_eq(result.to_stash.size(), 1, "only safe items go home")
	check((_tree.current_scene.get_node("%TitleLabel") as Label).text.contains("醫院"), "hospital result shown")
	check_eq(Game.home_stash.count_item(&"mysterious_item"), 1, "safe item in home stash")
	check_eq(Game.home_stash.count_item(&"tennis_ball"), 0, "lost loot not in stash")


func _test_debug_force_defeat(map: Node) -> void:
	var run := map.get_node("RunManager") as RunManager
	var coordinator := map.get_node("CombatCoordinator") as CombatCoordinator
	var debug := map.get_node("RunHUD").get_node("%DebugPanel") as DebugPanel
	coordinator.time_scale = 25.0
	debug.get_node("%NextEncounterButton").pressed.emit()
	await _physics(4)
	await _press(&"interact")
	check_eq(coordinator.engagements.size(), 1, "debug: fight started at next pair")
	debug.get_node("%LoseFightButton").pressed.emit()
	await _physics(2)
	check_eq(coordinator.last_result, CombatSimulation.Result.DEFEAT, "debug: forced defeat")
	check(run.is_running(), "the owner lies down briefly before the walk ends")
	await _wait_for_scene(Game.RUN_RESULT_SCENE)


# --- helpers ---------------------------------------------------------------

func _approach(dog: DogController, human: HumanFollower, pair: OpponentPair) -> void:
	dog.global_position = pair.global_position + Vector2(-60.0, 20.0)
	dog.velocity = Vector2.ZERO
	human.global_position = pair.global_position + Vector2(-140.0, 40.0)
	await _physics(4)


func _press(action: StringName) -> void:
	Input.action_press(action)
	await _physics(1)
	Input.action_release(action)
	await _physics(1)


func _wait_until(done: Callable, max_frames: int) -> void:
	for i in max_frames:
		if done.call():
			return
		await _tree.physics_frame
	check(false, "timed out waiting")


func _wait_for_scene(path: String) -> void:
	for i in 300:
		await _tree.process_frame
		if _tree.current_scene != null and _tree.current_scene.scene_file_path == path:
			await _tree.process_frame
			return
	check(false, "timed out waiting for scene %s" % path)


func _physics(frames: int) -> void:
	for i in frames:
		await _tree.physics_frame


func _count(stacks: Array[ItemStack], id: StringName) -> int:
	var total := 0
	for stack in stacks:
		if stack.item_id == id:
			total += stack.quantity
	return total


func _has_digit(text: String) -> bool:
	for c in text:
		if c >= "0" and c <= "9":
			return true
	return false
