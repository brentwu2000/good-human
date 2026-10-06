extends "res://tests/test_case.gd"
## P05-10: a weapon found on the real 3D walk. It is left lying where it was
## found (no magic into the bag); the dog brings its human over and the human
## picks it up and holds it — seen in the hand on the walk and used in the
## fight; holding something already with a full bag, it is a swap and the old
## one is put down.

const TEST_SAVE: String = "user://tests/weapon_world_save.json"

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
	await _frames(5)
	var map := _tree.current_scene as RunMap3D
	var run := map.run_manager
	map.coordinator.time_scale = 0.0

	# The dog sniffs out an umbrella.
	var point := map.get_node("SearchPoints/bench_park") as SearchPoint3D
	var umbrella_item := DataRegistry.get_item(&"umbrella")
	var found := ItemStack.new(umbrella_item, 1)
	found.condition = 25
	check(run.resolve_search(point, found) == null, "P05-10: the search is done")
	await _frames(2)
	check_eq(run.human_run_inventory.count_item(&"umbrella"), 0, "the umbrella does not jump into the bag")
	var lying := _world_weapons()
	check_eq(lying.size(), 1, "it is left lying where it was found")
	var umbrella := lying[0]
	check(umbrella.global_position.distance_to(point.global_position) < 1.5, "by the bench")
	check(umbrella.describe().contains("雨傘") and umbrella.describe().contains("長"), "near it, a few words compare it with bare hands (%s)" % umbrella.describe())
	check(not umbrella.describe().contains("%") and RegEx.create_from_string("[0-9]").search(umbrella.describe()) == null, "never a number")

	# The human must be there to pick it up.
	map.human.global_position = umbrella.global_position + Vector3(8, 0, 0)
	await _frames(2)
	check(not umbrella.can_interact(run), "with the human far away the dog cannot hand it over")
	map.human.global_position = umbrella.global_position + Vector3(1.2, 0, 0)
	map.dog.global_position = umbrella.global_position + Vector3(0.4, 0, 0)
	await _frames(2)
	check(umbrella.can_interact(run), "with them close, it can")
	check(umbrella.get_prompt(run).contains("撿起"), "the prompt is to have them pick it up")
	umbrella.interact(run)
	await _frames(3)
	check(run.equipped_weapon == DataRegistry.get_weapon(&"umbrella"), "the human holds the umbrella")
	check_eq(run.human_run_inventory.count_item(&"umbrella"), 1, "carried, exposed, in their bag")
	check_eq(run.equipped_stack.condition, 25, "the very umbrella that was found")
	check(map.human.puppet._prop != null, "seen in their hand on the walk")
	check(_world_weapons().is_empty(), "and no longer on the ground")

	# Full bag, holding the umbrella: a broom is a swap.
	for i in run.human_run_inventory.capacity:
		run.debug_give_item(&"tennis_ball", 99)
	var trash := map.get_node("SearchPoints/trash_street_east") as SearchPoint3D
	run.resolve_search(trash, ItemStack.new(DataRegistry.get_item(&"broom"), 1))
	await _frames(2)
	var broom := _world_weapons()[0]
	map.human.global_position = broom.global_position + Vector3(1.2, 0, 0)
	map.dog.global_position = broom.global_position + Vector3(0.4, 0, 0)
	await _frames(2)
	check(broom.get_prompt(run).contains("換成"), "holding something, it is a swap")
	check(broom.describe().contains("比雨傘"), "compared with what they hold now (%s)" % broom.describe())
	broom.interact(run)
	await _frames(3)
	check(run.equipped_weapon == DataRegistry.get_weapon(&"broom"), "they hold the broom")
	check_eq(run.human_run_inventory.count_item(&"umbrella"), 0, "the umbrella is out of the full bag")
	var left := _world_weapons()
	check(left.size() == 1 and left[0].weapon == DataRegistry.get_weapon(&"umbrella"), "put down on the ground where the broom was")
	check_eq(left[0].stack.condition, 25, "the same umbrella, as worn as it was")

	# And it is what they fight with.
	map.coordinator.start_engagement(map.coordinator.get_pairs()[0])
	await _frames(2)
	var fighter := map.coordinator.engagement.simulation.fighters[CombatSimulation.PLAYER]
	check(fighter.data.weapon == DataRegistry.get_weapon(&"broom"), "and fights with the broom")
	map.coordinator.debug_force_result(CombatSimulation.Result.VICTORY)
	await _frames(3)

	# P05-11: carried home, it is banked as worn as it was.
	run.equipped_stack.condition = 12
	var stash_before := Game.home_stash.count_item(&"broom")
	map.coordinator.time_scale = 50.0
	run.extract(&"bus_stop")
	await _wait_for_scene(Game.RUN_RESULT_SCENE)
	check_eq(Game.home_stash.count_item(&"broom"), stash_before + 1, "P05-11: taken home, the broom is banked")
	var banked: ItemStack = null
	for stack in Game.home_stash.get_stacks():
		if stack.item_id == &"broom":
			banked = stack
	check(banked != null and banked.condition == 12, "as worn as it was")
	var result_screen: GDScript = load("res://ui/run_result/run_result.gd")
	var lines: Array = result_screen.weapon_lines(Game.last_run_result)
	check(lines.size() == 1 and lines[0].contains("掃把") and lines[0].contains("回到家"), "and the result says so (%s)" % ", ".join(lines))
	check(Game.last_run_result.lost.filter(func(s: ItemStack) -> bool: return s.item_id == &"umbrella").is_empty(), "the umbrella left lying in the street was not carried, so it is neither banked nor counted lost")
	var saved := Inventory.new(Game.home_stash.capacity)
	saved.deserialize(SaveManager.data["stash"], DataRegistry.get_item)
	var reloaded := saved.get_stacks().filter(func(s: ItemStack) -> bool: return s.item_id == &"broom")
	check(not reloaded.is_empty() and reloaded[0].condition == 12, "and saved with its wear")
	finish()


func _world_weapons() -> Array[WorldWeapon3D]:
	var found: Array[WorldWeapon3D] = []
	for node in _tree.get_nodes_in_group(&"world_weapons"):
		if not node.is_queued_for_deletion():
			found.append(node as WorldWeapon3D)
	return found


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
