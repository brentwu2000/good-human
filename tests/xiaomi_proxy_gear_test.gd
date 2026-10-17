extends "res://tests/test_case.gd"
## Xiaomi toy proxy Phase 2 (docs/04_systems/XIAOMI_INTEGRATION_AUDIT.md):
## toy parts in the existing slots — the spring glove is a weapon her robot
## fights with, a toy battery charges it — found only when her robot fights,
## without touching any other owner's loot; lost and kept by the usual rules;
## her pair and what came home survive a save and reload.

const TEST_SAVE: String = "user://tests/xiaomi_proxy_gear_save.json"

var _tree: SceneTree


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_tree = get_tree()
	_test_loot_tables()
	_test_glove_data()
	await _test_walk_and_save()
	finish()


## Other owners roll exactly what they rolled before; only her rolls can turn
## up toy parts.
func _test_loot_tables() -> void:
	for path in ["res://data/loot_tables/park_search.tres", "res://data/loot_tables/residential_trash.tres"]:
		var table := load(path) as LootTableData
		check(not table.proxy_entries.is_empty(), "%s has toy parts for her" % table.id)
		var plain := _sequence(table, 777, false)
		var reference := _reference_sequence(table, 777)
		check_eq(plain, reference, "%s: another owner's rolls are unchanged by the toy parts" % table.id)
		var theirs := _sequence(table, 4242, false, 3000)
		check(not theirs.has("spring_glove") and not theirs.has("toy_battery"), "%s: another owner never finds a toy part" % table.id)
		var hers := _sequence(table, 4242, true, 3000)
		check(hers.has("spring_glove") and hers.has("toy_battery"), "%s: she finds both toy parts" % table.id)


func _test_glove_data() -> void:
	var glove := DataRegistry.weapon_for_item(&"spring_glove")
	check(glove != null and glove.archetype == WeaponData.Archetype.TOY, "the spring glove is a toy weapon")
	check(not glove.is_unarmed() and glove.moveset != null, "with its own moves")
	var robot := load("res://data/combat/fighters/bunny_robot.tres") as FighterData
	var armed := robot.armed(glove)
	check(armed.skills.has(load("res://data/combat/skills/skill_glove_spring_punch.tres")), "the robot fights with the glove's moves")
	check(WeaponProp3D.build(glove) != null, "and is seen wearing it")
	var battery := DataRegistry.get_item(&"toy_battery")
	check(battery != null and battery.proxy_only and battery.owner_recovery > 0.0, "a toy battery charges the robot")


func _test_walk_and_save() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_SAVE.get_base_dir())
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(TEST_SAVE)
	SaveManager.save_path = TEST_SAVE
	var placeholder := Node.new()
	_tree.root.add_child(placeholder)
	_tree.current_scene = placeholder
	_tree.change_scene_to_file(Game.BOOT_SCENE)
	await _wait_for_scene(Game.HOME_SCENE)

	# Another owner first: nothing changes for them.
	check(not Game.owner_has_proxy(), "the classic owner fights themselves")

	var xiaomi := HumanCandidate.new()
	xiaomi.id = &"human_xiaomi"
	xiaomi.background_id = &"granddaughter"
	xiaomi.reaction_set = &"granddaughter"
	for stat in HumanCandidate.STAT_NAMES:
		xiaomi.stats[stat] = 5
	Game.pair_state = PairState.adopted(PairState.classic().dog, xiaomi, "小米", "")
	Game.save_pair()

	_tree.current_scene.get_node("%Walk3DButton").pressed.emit()
	await _wait_for_scene(Game.RUN_MAP_3D_SCENE)
	await _frames(5)
	var map := _tree.current_scene as RunMap3D
	var run := map.run_manager
	var coordinator := map.coordinator
	var human := map.human

	# The glove: in her backpack on the walk, on the robot in a fight.
	var glove := ItemStack.new(DataRegistry.get_item(&"spring_glove"), 1)
	run.take_weapon(glove)
	await _frames(2)
	check(human.puppet.held == null, "she carries the glove in her backpack")
	var pair := _present(coordinator)[0]
	map.dog.global_position = pair.global_position + Vector3(0.7, 0.2, 0.9)
	human.global_position = pair.global_position + Vector3(1.6, 0.2, 2.0)
	coordinator.time_scale = 0.0
	coordinator.start_engagement(pair)
	await _frames(2)
	check(coordinator.proxy != null and coordinator.proxy.puppet.held == DataRegistry.weapon_for_item(&"spring_glove"), "the robot wears the glove in the fight")
	check(coordinator.proxy != null and coordinator.proxy.puppet._prop != null, "and it is drawn on its arm")
	var skills := coordinator.engagement.simulation.fighters[CombatSimulation.PLAYER].data.skills
	check(skills.has(load("res://data/combat/skills/skill_glove_spring_punch.tres")), "and fights with its moves")
	coordinator.debug_force_result(CombatSimulation.Result.DISENGAGED)
	await _frames(3)

	# The battery: charges the robot (the walk's condition).
	run.set_owner_condition(0.4)
	run.debug_give_item(&"toy_battery", 2)
	var at := _index_of(run.human_run_inventory, &"toy_battery")
	check(at >= 0, "a found battery goes in her backpack")
	check(run.use_on_owner(run.human_run_inventory, at), "it can be used between fights")
	check(is_equal_approx(run.owner_condition, 0.7), "and charges the robot by 30 %% (now %.2f)" % run.owner_condition)

	# One battery in the dog's backpack (safe); then the robot loses.
	at = _index_of(run.human_run_inventory, &"toy_battery")
	run.human_run_inventory.move_item(at, run.dog_safe_inventory, 0)
	var next := _present(coordinator)[0]
	map.dog.global_position = next.global_position + Vector3(0.7, 0.2, 0.9)
	human.global_position = next.global_position + Vector3(1.6, 0.2, 2.0)
	coordinator.start_engagement(next)
	await _frames(2)
	coordinator.debug_force_result(CombatSimulation.Result.DEFEAT)
	coordinator.time_scale = 50.0
	await _wait_for_scene(Game.RUN_RESULT_SCENE)
	var result := Game.last_run_result
	var lost := result.lost.map(func(s: ItemStack) -> String: return String(s.item_id))
	var home := result.to_stash.map(func(s: ItemStack) -> String: return String(s.item_id))
	check(lost.has("spring_glove"), "the glove she carried is lost like any weapon")
	check(home.has("toy_battery"), "the battery in the dog's backpack comes home")

	# Save and reload: she is still the owner, the battery is still home.
	SaveManager.reset_to_default()
	SaveManager.load_game()
	var reloaded := PairState.deserialize(SaveManager.data.get("pair"))
	check(reloaded != null and reloaded.has_proxy(), "after a reload her robot still fights for her")
	check(reloaded != null and reloaded.human.background_id == &"granddaughter", "and she is still Xiaomi")
	var stash: Array = SaveManager.data["stash"]
	check(stash.any(func(e: Dictionary) -> bool: return str(e.get("item_id", "")) == "toy_battery"), "the battery is in the saved stash")


func _sequence(table: LootTableData, seed: int, with_proxy: bool, count: int = 40) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var out: Array = []
	for i in count:
		var stack := table.roll(rng, with_proxy)
		out.append(String(stack.item_id) if stack != null else "")
	return out


## The roll as it was before toy parts existed (entries only).
func _reference_sequence(table: LootTableData, seed: int) -> Array:
	var copy := table.duplicate() as LootTableData
	copy.proxy_entries = []
	return _sequence(copy, seed, true)


func _index_of(inventory: Inventory, item_id: StringName) -> int:
	for i in inventory.slots.size():
		var s: ItemStack = inventory.slots[i]
		if s != null and s.item_id == item_id:
			return i
	return -1


func _present(coordinator: CombatCoordinator3D) -> Array[OpponentPair3D]:
	var out: Array[OpponentPair3D] = []
	for p in coordinator.get_pairs():
		if p.is_present() and p.is_idle():
			out.append(p)
	return out


func _frames(count: int) -> void:
	for i in count:
		await _tree.process_frame


func _wait_for_scene(path: String) -> void:
	for i in 600:
		if _tree.current_scene != null and _tree.current_scene.scene_file_path == path:
			return
		await _tree.process_frame
	check(false, "scene %s never loaded" % path)
