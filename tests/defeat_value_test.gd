extends "res://tests/test_case.gd"
## S05-12: one defeat through the real 3D walk, checked against every value
## rule at once. SAFE comes home, UNBANKED is lost, PERMANENT only grows by
## what came home, a mark that did not get home earns nothing and takes
## nothing, and the owner learns half. The result says all of it.

const TEST_SAVE: String = "user://tests/defeat_value_save.json"

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

	# Something already banked from an earlier walk: it must not be touched.
	Game.home_stash.add_item(DataRegistry.get_item(&"umbrella"), 1)
	var stash_before := Game.home_stash.total_value()
	var progress := Game.territory_progress
	progress.advance_to(&"banyan", TerritoryProgress.State.CLAIMING)
	progress.claims[&"banyan"] = 1

	_tree.current_scene.get_node("%Walk3DButton").pressed.emit()
	await _wait_for_scene(Game.RUN_MAP_3D_SCENE)
	await _frames(5)
	var map := _tree.current_scene as RunMap3D
	var run := map.run_manager
	var coordinator := map.coordinator
	coordinator.time_scale = 0.0

	# SAFE: one thing in the dog's bag. UNBANKED: two in the owner's.
	run.debug_give_item(&"tennis_ball", 1)
	run.human_run_inventory.move_item(0, run.dog_safe_inventory, 0)
	run.debug_give_item(&"boxing_gloves", 1)
	run.debug_give_item(&"old_sports_watch", 1)
	var value := run.run_value()
	check(value.safe_value > 0 and value.unbanked_value > 0, "the walk carries both safe and exposed value")
	var safe_value := value.safe_value
	var unbanked_value := value.unbanked_value

	# The dog marks the tree, so this walk could count — if it got home.
	var banyan := map.get_node("BanyanTerritory") as TerritoryPoint3D
	banyan.interact(run)
	check(run.marked_territories.has(&"banyan"), "the walk carries a mark")
	run.record_training(DataRegistry.get_training_event(&"run_dragged"), &"test")

	# A fight lost: the owner goes down and the walk ends at the hospital.
	coordinator.start_engagement(coordinator.get_pairs()[0])
	coordinator.debug_force_result(CombatSimulation.Result.DEFEAT)
	await _frames(2)
	check_eq(run.owner_condition, 0.0, "the owner is down")
	coordinator.time_scale = 50.0
	await _wait_for_scene(Game.RUN_RESULT_SCENE)
	var result := Game.last_run_result
	check(result != null and result.outcome == RunResult.Outcome.DEFEATED, "the walk ends in defeat")

	# SAFE / UNBANKED / PERMANENT.
	check_eq(result.safe_value, safe_value, "the result knows what was safe")
	check_eq(result.lost_value, unbanked_value, "and what was exposed")
	check_eq(_ids(result.to_stash), ["tennis_ball"], "SAFE: the dog's bag comes home")
	check_eq(_ids(result.lost), ["boxing_gloves", "old_sports_watch"], "UNBANKED: the owner's bag is lost")
	check_eq(result.banked_value_delta, safe_value, "PERMANENT grows only by what came home")
	check_eq(Game.home_stash.total_value(), stash_before + safe_value, "and nothing already banked is touched")
	check_eq(Game.home_stash.count_item(&"umbrella"), 1, "the earlier walk's umbrella is still there")

	# Territory: no progress, no loss.
	check_eq(progress.claim_progress(&"banyan"), 1, "a mark that did not get home earns nothing")
	check_eq(progress.state_of(&"banyan"), TerritoryProgress.State.CLAIMING, "and takes nothing away")
	check(result.territory_claims.is_empty(), "the result claims nothing")

	# S06-08: the walk is still time spent together.
	check_eq(result.fights_lost, 1, "the lost fight is counted for the pair")
	check(Bond.value(Game.pair_state, Bond.SHARED) > 0.0 and Bond.value(Game.pair_state, Bond.TRUST) == 0.0, "something gone through together, but no trust earned")

	# Training: the owner remembers half.
	check(result.training != null and result.training.is_partial(), "a defeat converts training partially")

	# The result says all of it in words.
	var screen := _tree.current_scene
	var loot := (screen.get_node("%LootLabel") as Label).text
	check(loot.contains("遺失") and loot.contains("$%d" % unbanked_value), "the result shows what was lost (%s)" % loot.replace("\n", " / "))
	check(loot.contains("+$%d" % safe_value), "and what was banked")
	var places := (screen.get_node("%TerritoryLabel") as Label).text
	check(places == DataRegistry.get_territory(&"banyan").not_home_text, "and that the mark did not count")
	check((screen.get_node("%TitleLabel") as Label).text.contains("醫院"), "and that the owner is at the hospital")

	# The save on disk agrees.
	SaveManager.load_game()
	var saved := TerritoryProgress.new()
	saved.deserialize(SaveManager.data["dog"]["territories"])
	check_eq(saved.claim_progress(&"banyan"), 1, "saved: the place is where it was")
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(TEST_SAVE)
	finish()


func _ids(stacks: Array[ItemStack]) -> Array[String]:
	var ids: Array[String] = []
	for stack in stacks:
		ids.append(String(stack.item_id))
	ids.sort()
	return ids


func _frames(count: int) -> void:
	for i in count:
		await _tree.process_frame


func _wait_for_scene(path: String) -> void:
	for i in 600:
		await _tree.process_frame
		if _tree.current_scene != null and _tree.current_scene.scene_file_path == path:
			await _tree.process_frame
			return
	check(false, "timed out waiting for scene %s" % path)
