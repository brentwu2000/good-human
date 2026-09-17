extends "res://tests/test_case.gd"
## Sprint 02 Required Flow through the real scenes: encounter trigger,
## Leave, Provoke, autonomous fights, rewards, Old Master defeat, hospital
## result and loss rules (P1-009..P1-018).

const TEST_SAVE: String = "user://tests/encounter_flow_save.json"
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
	await _frames(3)

	var map := _tree.current_scene
	var run := map.get_node("RunManager") as RunManager
	var controller := map.get_node("EncounterController") as EncounterController
	var ui := map.get_node("EncounterUI") as EncounterUI
	var hud := map.get_node("RunHUD")
	var debug := hud.get_node("%DebugPanel") as DebugPanel
	var dog := run.dog
	var human := map.get_node("Actors/Human") as HumanFollower
	var normal_player := controller.player_fighter
	controller.combat_time_scale = 25.0
	run.start_run(SEED)
	await _frames(2)

	# --- Setup: 3 ordinary pairs shuffled over spots + fixed Old Master -------
	var points := controller.get_points()
	check_eq(points.size(), 4, "four encounter spots")
	var ordinary: Array[EncounterPoint] = []
	var master: EncounterPoint = null
	var ids: Dictionary[StringName, bool] = {}
	for point in points:
		check(point.is_available(), "%s has a pair" % point.spot_id)
		ids[point.encounter.id] = true
		if point.encounter.tier == EncounterData.Tier.OVERPOWERED:
			master = point
		else:
			ordinary.append(point)
		var label := (point.get_node("%NameLabel") as Label).text
		check(not label.is_empty() and not _has_digit(label), "pair label has no power number (%s)" % label)
	check_eq(ids.size(), 4, "each pair appears once")
	check(master != null and master.spot_id == &"pair_big_tree", "Old Master waits under the big tree")
	check(master.encounter.human.display_name == "老爺爺" and master.encounter.dog_scale < 1.0, "Old Master looks harmless")

	run.debug_give_item(&"tennis_ball", 2)
	run.dog_safe_inventory.add_item(DataRegistry.get_item(&"mysterious_item"))

	# --- Trigger + Leave -------------------------------------------------------
	var first := ordinary[0]
	await _walk_to(dog, first)
	check(controller.is_active() and controller.current_point == first, "walking up to a pair starts an encounter")
	check(ui.is_deciding(), "Provoke / Leave shown")
	check(run.encounter_active and not dog.input_enabled, "walk paused and dog waits")
	var time_before := run.elapsed_time
	await _frames(10)
	check_eq(run.elapsed_time, time_before, "run timer paused during decision")
	hud.toggle_inventory()
	check(not (hud.get_node("%InventoryPanel") as Control).visible, "bag cannot be opened during an encounter")

	ui.get_node("%LeaveButton").pressed.emit()
	await _frames(2)
	check(not controller.is_active() and controller.arena == null, "leave ends encounter without combat")
	check(first.is_available(), "pair still there after leaving")
	check(dog.input_enabled and not run.encounter_active, "walk resumes after leaving")
	check_eq(run.human_run_inventory.count_item(&"tennis_ball"), 2, "leaving costs nothing")
	await _frames(10)
	check(not controller.is_active(), "standing next to the pair does not re-trigger")
	dog.global_position = first.global_position + Vector2(0, first.rearm_distance + 100)
	await _frames(4)
	await _walk_to(dog, first)
	check(controller.is_active(), "coming back later meets the pair again")

	# --- Three ordinary fights (natural, autonomous) ------------------------------
	# A test-only strong human guarantees natural victories without debug forcing.
	controller.player_fighter = OLD_MASTER
	var gained: Array[int] = [0]
	run.loot_gained.connect(func(_item: ItemData, quantity: int) -> void: gained[0] += quantity)
	for i in ordinary.size():
		var point := ordinary[i]
		if i > 0:
			debug.get_node("%NextEncounterButton").pressed.emit()
			await _frames(4)
		check(controller.current_point != null and ordinary.has(controller.current_point), "encounter %d started" % i)
		point = controller.current_point
		var gained_before := gained[0]
		ui.get_node("%ProvokeButton").pressed.emit()
		await _frames(2)
		check(controller.arena != null, "provoke starts combat")
		check(not human.visible and not point.get_node("%Human").visible, "arena replaces the world humans")
		check(not ui.is_deciding(), "no attack commands during combat")
		check(not dog.input_enabled, "dog only watches")
		check(dog.global_position.distance_to(controller.arena.player_dog_global_position()) < 1.0, "dog stays beside the fight")
		Input.action_press(&"interact")
		await _frames(1)
		Input.action_release(&"interact")
		var sim := controller.arena.simulation
		await _wait_until(func() -> bool: return controller.last_result != CombatSimulation.Result.NONE, 900)
		check_eq(controller.last_result, CombatSimulation.Result.VICTORY, "fight %d won" % i)
		check(not sim.fighters[0].uses.is_empty() and not sim.fighters[1].uses.is_empty(), "both humans chose skills themselves")
		check(point.defeated, "beaten pair marked")
		check(gained[0] > gained_before, "victory reward added to the bag")
		check(not ui.is_deciding(), "result panel, not decision")
		ui.get_node("%ContinueButton").pressed.emit()
		await _frames(2)
		check(not controller.is_active() and human.visible and dog.input_enabled, "run continues after victory")
		check(run.is_running(), "still walking")
		await _frames(6)
		check(not controller.is_active(), "beaten pair does not stop the dog again")

	check(controller.get_points().filter(func(p: EncounterPoint) -> bool: return p.is_available()).size() == 1, "only the Old Master is left")

	# --- Old Master: natural defeat -------------------------------------------
	controller.player_fighter = normal_player
	debug.get_node("%NextEncounterButton").pressed.emit()
	await _frames(4)
	check(controller.current_point == master, "Old Master encounter")
	ui.get_node("%ProvokeButton").pressed.emit()
	await _wait_until(func() -> bool: return controller.last_result != CombatSimulation.Result.NONE, 900)
	check_eq(controller.last_result, CombatSimulation.Result.DEFEAT, "the frail old man wins")
	check(not master.defeated, "Old Master is not beaten")
	check(not run.human_run_inventory.is_empty(), "bag had loot before defeat")
	ui.get_node("%ContinueButton").pressed.emit()
	await _wait_for_scene(Game.RUN_RESULT_SCENE)

	_check_defeat_result()

	# No permanent Game Over: home and a new walk still work.
	_tree.current_scene.get_node("%HomeButton").pressed.emit()
	await _wait_for_scene(Game.HOME_SCENE)
	_tree.current_scene.get_node("%WalkButton").pressed.emit()
	await _wait_for_scene(Game.RUN_MAP_SCENE)
	await _frames(3)
	var next_controller := _tree.current_scene.get_node("EncounterController") as EncounterController
	check(next_controller.get_points().all(func(p: EncounterPoint) -> bool: return p.is_available()), "new walk resets every pair")

	await _test_debug_force_result(_tree.current_scene)

	DirAccess.remove_absolute(TEST_SAVE)
	finish()


func _test_debug_force_result(map: Node) -> void:
	var run := map.get_node("RunManager") as RunManager
	var controller := map.get_node("EncounterController") as EncounterController
	var ui := map.get_node("EncounterUI") as EncounterUI
	var debug := map.get_node("RunHUD").get_node("%DebugPanel") as DebugPanel
	await _frames(2)
	debug.get_node("%NextEncounterButton").pressed.emit()
	await _frames(4)
	check(controller.is_active(), "debug: teleport starts nearest encounter")
	ui.get_node("%ProvokeButton").pressed.emit()
	await _frames(2)
	debug.get_node("%LoseFightButton").pressed.emit()
	await _wait_until(func() -> bool: return controller.last_result != CombatSimulation.Result.NONE, 300)
	check_eq(controller.last_result, CombatSimulation.Result.DEFEAT, "debug: forced defeat")
	check(run.is_running(), "defeat waits for the player before ending the walk")


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


# --- helpers ---------------------------------------------------------------

func _walk_to(dog: DogController, point: EncounterPoint) -> void:
	dog.global_position = point.global_position + Vector2(-point.trigger_radius * 0.6, 0)
	dog.velocity = Vector2.ZERO
	await _frames(4)


func _wait_until(done: Callable, max_frames: int) -> void:
	for i in max_frames:
		if done.call():
			return
		await _tree.process_frame
	check(false, "timed out waiting")


func _wait_for_scene(path: String) -> void:
	for i in 120:
		await _tree.process_frame
		if _tree.current_scene != null and _tree.current_scene.scene_file_path == path:
			await _tree.process_frame
			return
	check(false, "timed out waiting for scene %s" % path)


func _frames(count: int) -> void:
	for i in count:
		await _tree.process_frame


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
