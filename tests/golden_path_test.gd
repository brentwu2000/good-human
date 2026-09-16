extends "res://tests/test_case.gd"
## Automated Sprint 01 QA Golden Path (§20) through the real scenes.
## Manual device checks (touch feel, Android) are still required separately.

const TEST_SAVE: String = "user://tests/golden_path_save.json"

var _tree: SceneTree


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_tree = get_tree()
	DirAccess.make_dir_recursive_absolute(TEST_SAVE.get_base_dir())
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(TEST_SAVE)
	SaveManager.save_path = TEST_SAVE

	# 1–2: Boot → Home with a fresh save.
	var placeholder := Node.new()
	_tree.root.add_child(placeholder)
	_tree.current_scene = placeholder
	_tree.change_scene_to_file(Game.BOOT_SCENE)
	await _wait_for_scene(Game.HOME_SCENE)
	check_eq(Game.home_stash.used_slot_count(), 0, "fresh stash empty")
	check(not (_tree.current_scene.get_node("%ControlsLabel") as Label).text.is_empty(), "home shows controls")

	# 3–4: start walk.
	_press(_tree.current_scene.get_node("%WalkButton"))
	await _wait_for_scene(Game.RUN_MAP_SCENE)
	var first := await _run_parts()
	var seed_1: int = first.run_seed
	check(first.hud.get_node("%HintLabel").visible, "controls hint shown at walk start")
	check(first.search_points.size() >= 10, "map has at least 10 search points")

	# 6–8: search the alley trash can for real (loot follows the seed).
	await _search(first, &"trash_alley")
	check(first.run.is_searched(&"trash_alley"), "trash can searched")

	# 9–11: debug mysterious item, move it into the dog safe slot through the panel.
	var debug := first.hud.get_node("%DebugPanel") as DebugPanel
	check(not debug.get_node("%Body").visible, "debug panel hidden by default")
	var timer_label := first.hud.get_node("%TimeLabel") as Label
	for i in 5:
		var tap := InputEventMouseButton.new()
		tap.button_index = MOUSE_BUTTON_LEFT
		tap.pressed = true
		timer_label.gui_input.emit(tap)
	check(debug.get_node("%Body").visible, "5 taps on timer open debug panel")
	debug.toggle()
	_press(debug.get_node("%ClearBagButton"))
	_press(debug.get_node("%GiveBallButton"))
	_press(debug.get_node("%GiveMysteryButton"))
	var panel := first.hud.get_node("%InventoryPanel") as InventoryPanel
	first.hud.toggle_inventory()
	check(panel.visible, "inventory panel opens")
	var mystery_slot := _find_slot(first.run.human_run_inventory, &"mysterious_item")
	panel.select_slot(first.run.human_run_inventory, mystery_slot)
	panel.select_slot(first.run.dog_safe_inventory, 0)
	check_eq(first.run.dog_safe_inventory.count_item(&"mysterious_item"), 1, "mysterious item in dog safe slot")
	first.hud.toggle_inventory()

	# 12–15: set 04:50, reach 05:00, bus stop unlocks, north gate still locked.
	_press(debug.get_node("%SetTimeButton"))
	check(not first.run.is_extraction_available(&"bus_stop"), "bus stop still locked after skip")
	var bus_stop := first.map.get_node("ExtractionPoints/bus_stop") as ExtractionPoint
	var north_gate := first.map.get_node("ExtractionPoints/north_gate") as ExtractionPoint
	first.run.debug_set_time(bus_stop.unlock_time - 0.5)
	await _tree.create_timer(0.8).timeout  # real time passes 05:00
	check(first.run.is_extraction_available(&"bus_stop"), "bus stop unlocks at its time")
	check(north_gate.unlock_time > bus_stop.unlock_time, "north gate opens later")
	check(not first.run.is_extraction_available(&"north_gate"), "north gate still locked")

	# 16–18: keep going, search in the park, get boxing gloves.
	await _search(first, &"gym_equipment")
	_press(debug.get_node("%GiveGlovesButton"))

	# 19–21: return to bus stop and extract through interaction.
	var first_run := first.run as RunManager
	var expected: Array[ItemStack] = first_run.human_run_inventory.get_stacks()
	expected.append_array(first.run.dog_safe_inventory.get_stacks())
	await _interact_at(first, first.map.get_node("ExtractionPoints/bus_stop"))
	await _wait_for_scene(Game.RUN_RESULT_SCENE)
	var result := Game.last_run_result
	check(result != null and result.is_success(), "extraction succeeded")
	check_eq(result.run_seed, seed_1, "result shows run seed")
	var items_text: String = (_tree.current_scene.get_node("%ItemsLabel") as Label).text
	check(items_text.contains("神秘物品") and items_text.contains("舊拳擊手套") and items_text.contains("舊網球"), "result lists items")
	check(_tree.current_scene.get_node("%SummaryLabel").text.contains(str(seed_1)), "result screen shows seed")

	# 22–23: home, stash has the items.
	_press(_tree.current_scene.get_node("%HomeButton"))
	await _wait_for_scene(Game.HOME_SCENE)
	for stack in expected:
		check(Game.home_stash.count_item(stack.item_id) >= stack.quantity, "stash has %s" % stack.item_id)
	check(_tree.current_scene.get_node("%StashLabel").text.contains("%d/30" % Game.home_stash.used_slot_count()), "home shows stash count")

	# 24–27: second walk resets points and rerolls, extract again.
	_press(_tree.current_scene.get_node("%WalkButton"))
	await _wait_for_scene(Game.RUN_MAP_SCENE)
	var second := await _run_parts()
	check(second.run_seed != seed_1, "second run has a new seed")
	var all_reset := true
	for point: SearchPoint in second.search_points:
		all_reset = all_reset and point.can_interact(second.run)
	check(all_reset, "all search points reset on second run")
	var debug_2 := second.hud.get_node("%DebugPanel") as DebugPanel
	_press(debug_2.get_node("%GiveBallButton"))
	_press(debug_2.get_node("%UnlockButton"))
	await _interact_at(second, second.map.get_node("ExtractionPoints/north_gate"))
	await _wait_for_scene(Game.RUN_RESULT_SCENE)
	check(Game.last_run_result.is_success(), "second extraction succeeded")
	var stash_before_restart := JSON.stringify(Game.home_stash.serialize())

	# 28–30: "restart" — reload save from disk, stash still there.
	Game.home_stash.clear()
	SaveManager.reset_to_default()
	SaveManager.load_game()
	Game.load_profile()
	check_eq(JSON.stringify(Game.home_stash.serialize()), stash_before_restart, "stash persists after reload")
	check_eq(SaveManager.data["statistics"]["runs"], 2, "two runs recorded")
	check_eq(SaveManager.data["statistics"]["successful_extractions"], 2, "two extractions recorded")

	DirAccess.remove_absolute(TEST_SAVE)
	finish()


func _run_parts() -> Dictionary:
	await _process_frames(3)
	var map := _tree.current_scene
	var run := map.get_node("RunManager") as RunManager
	var search_points: Array = map.get_node("SearchPoints").get_children()
	return {
		"map": map,
		"run": run,
		"dog": run.dog,
		"hud": map.get_node("RunHUD"),
		"run_seed": run.run_seed,
		"search_points": search_points,
	}


func _search(parts: Dictionary, search_id: StringName) -> void:
	var point := parts.map.get_node("SearchPoints/%s" % search_id) as SearchPoint
	await _interact_at(parts, point)
	check(point.is_searching(), "%s search started" % search_id)
	await _tree.create_timer(point.search_duration + 0.3).timeout


func _interact_at(parts: Dictionary, target: Node2D) -> void:
	var dog := parts.dog as DogController
	dog.global_position = target.global_position
	dog.velocity = Vector2.ZERO
	for i in 4:
		await _tree.physics_frame
	check(dog.focused == target, "dog focuses %s" % target.name)
	Input.action_press(&"interact")
	await _tree.physics_frame
	Input.action_release(&"interact")
	await _tree.physics_frame


func _press(button: Button) -> void:
	button.pressed.emit()


func _find_slot(inventory: Inventory, item_id: StringName) -> int:
	for i in inventory.capacity:
		var stack := inventory.stack_at(i)
		if stack != null and stack.item_id == item_id:
			return i
	return -1


func _wait_for_scene(path: String) -> void:
	for i in 120:
		await _tree.process_frame
		if _tree.current_scene != null and _tree.current_scene.scene_file_path == path:
			await _tree.process_frame
			return
	check(false, "timed out waiting for scene %s" % path)


func _process_frames(count: int) -> void:
	for i in count:
		await _tree.process_frame
