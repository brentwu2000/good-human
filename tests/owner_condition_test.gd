extends "res://tests/test_case.gd"
## S05-02 (owner decision 2026-10-04): the owner's health carries from fight to
## fight. On their own they get back only a little (up to a cap); rest spots
## and items do the rest. Through the real 3D walk.

const TEST_SAVE: String = "user://tests/owner_condition_save.json"

var _tree: SceneTree


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_tree = get_tree()
	await _test_walk()
	finish()


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
	var coordinator := map.coordinator
	var human := map.human
	var balance := DataRegistry.balance
	var risk_label := map.get_node("RunHUD")._risk_label as Label
	coordinator.time_scale = 0.0
	check_eq(run.owner_condition, 1.0, "a walk starts with the owner fine")
	check_eq(human.condition_speed, 1.0, "and walking normally")

	# --- A fight takes what it takes, and it stays taken ----------------------
	var pairs := coordinator.get_pairs()
	check(pairs.size() >= 2, "the walk has pairs to fight")
	coordinator.start_engagement(pairs[0])
	check(coordinator.is_fighting(), "first fight starts")
	check(run.owner_busy, "the fight owns the owner's health")
	var fighter := coordinator.engagement.simulation.fighters[CombatSimulation.PLAYER]
	check_eq(fighter.hp, fighter.max_hp, "the first fight starts at full health")
	run.debug_give_item(&"bandage", 1)
	var bandage_at := _index_of(run.human_run_inventory, &"bandage")
	fighter.hp = fighter.max_hp * 0.4
	check(not run.can_use_on_owner(run.human_run_inventory, bandage_at), "no bandage in the middle of a fight")
	coordinator.debug_force_result(CombatSimulation.Result.VICTORY)
	await _frames(3)
	check(not coordinator.is_fighting() and not run.owner_busy, "the fight ends")
	check(absf(run.owner_condition - 0.4) < 0.02, "the owner comes out of it hurt (%.2f)" % run.owner_condition)
	check(human.condition_speed < 1.0, "a hurt owner walks heavier (%.2f)" % human.condition_speed)
	check(risk_label.visible and risk_label.text.contains("主人受傷了"), "the walk says the owner is hurt, not a number (%s)" % risk_label.text)

	# --- On their own: a little, and only up to the cap ----------------------
	coordinator.debug_set_owner_condition(0.3)
	check(risk_label.text.contains("主人快撐不住了"), "barely standing reads differently (%s)" % risk_label.text)
	coordinator._walk_owner_condition(10.0)
	check(absf(run.owner_condition - (0.3 + balance.owner_regen_per_second * 10.0)) < 0.01, "walking gives a little back (%.2f)" % run.owner_condition)
	coordinator._walk_owner_condition(1000.0)
	check(absf(run.owner_condition - balance.owner_regen_cap) < 0.001, "but never past the cap on their own (%.2f)" % run.owner_condition)
	coordinator.debug_set_owner_condition(0.8)
	coordinator._walk_owner_condition(100.0)
	check(absf(run.owner_condition - 0.8) < 0.001, "above the cap, walking gives nothing")

	# --- The next fight starts where the walk left them ----------------------
	coordinator.debug_set_owner_condition(0.5)
	coordinator.start_engagement(pairs[1])
	fighter = coordinator.engagement.simulation.fighters[CombatSimulation.PLAYER]
	check(absf(fighter.hp_ratio() - 0.5) < 0.01, "the second fight starts at the walk's condition (%.2f)" % fighter.hp_ratio())
	coordinator.debug_force_result(CombatSimulation.Result.VICTORY)
	await _frames(3)

	# --- Items: a bandage for the owner --------------------------------------
	coordinator.debug_set_owner_condition(0.3)
	bandage_at = _index_of(run.human_run_inventory, &"bandage")
	# A won fight can also drop a bandage, so count rather than expect none.
	var bandages := run.human_run_inventory.count_item(&"bandage")
	check(run.can_use_on_owner(run.human_run_inventory, bandage_at), "between fights a bandage can be used on the owner")
	check(run.use_on_owner(run.human_run_inventory, bandage_at), "and is")
	check(absf(run.owner_condition - 0.65) < 0.01, "a bandage gives back what its data says (%.2f)" % run.owner_condition)
	check_eq(run.human_run_inventory.count_item(&"bandage"), bandages - 1, "and one is used up")
	run.debug_give_item(&"boxing_gloves", 1)
	check(not run.can_use_on_owner(run.human_run_inventory, _index_of(run.human_run_inventory, &"boxing_gloves")), "gloves are not medicine")

	# --- Rest spots: a limited amount per spot per walk ----------------------
	var bench := map.get_node("RestBench") as RestSpot3D
	check(bench != null and map.get_node_or_null("RestBusStop") != null, "the bench and the bus stop are rest spots")
	coordinator.debug_set_owner_condition(0.1)
	human.global_position = bench.global_position + Vector3(0.5, 0.1, 0.5)
	human.velocity = Vector3.ZERO
	map.dog.global_position = human.global_position + Vector3(0.6, 0, 0)
	map.dog.velocity = Vector3.ZERO
	for i in 20:
		human.velocity = Vector3.ZERO
		bench._physics_process(1.0)
	check(bench.is_owner_resting(), "the owner rests where the dog let them stop")
	check(absf(run.owner_condition - (0.1 + balance.rest_recovery_budget)) < 0.02, "resting gives back up to the spot's budget (%.2f)" % run.owner_condition)
	var after_rest := run.owner_condition
	bench._physics_process(5.0)
	check_eq(run.owner_condition, after_rest, "and the same bench gives nothing more this walk")

	# --- A new walk starts fresh ---------------------------------------------
	run.start_run()
	await _frames(2)
	check_eq(run.owner_condition, 1.0, "a new walk starts with the owner fine")
	check(absf(bench.budget_left - balance.rest_recovery_budget) < 0.001, "and the bench rested")
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(TEST_SAVE)


func _index_of(inventory: Inventory, item_id: StringName) -> int:
	for i in inventory.capacity:
		var stack := inventory.stack_at(i)
		if stack != null and stack.item_id == item_id:
			return i
	return -1


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
