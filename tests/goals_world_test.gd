extends "res://tests/test_case.gd"
## Sprint 03.5 through the real scenes: a desire at walk start, world cues,
## the Strange Scent chain (clue item -> rival revealed -> meet -> duel)
## across walks, squirrel emergent desire, bring-it-home via extraction,
## discoveries, save/load and Home text (P2G-004, 009..019).

const TEST_SAVE: String = "user://tests/goals_world_save.json"
const OLD_MASTER: FighterData = preload("res://data/combat/fighters/oppx01_old_master.tres")
const SEED: int = 99

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
	check((_tree.current_scene.get_node("%GoalsLabel") as Label).text.contains("發現"), "Home shows discoveries")
	_tree.current_scene.get_node("%WalkButton").pressed.emit()
	await _wait_for_scene(Game.RUN_MAP_SCENE)
	await _physics(3)

	var p := _parts()
	var run: RunManager = p.run
	var director: GoalDirector = p.director
	var dog := run.dog
	(p.coordinator as CombatCoordinator).time_scale = 25.0

	# --- Walk 1: a reason to walk, pointing somewhere in the world ------------------
	check(director.active_desires().size() == 1 and director.active_desires()[0].id == &"desire_strange_scent", "walk starts with the strange scent desire")
	var card := (p.hud as DesireHUD).get_node("%DesireCard") as DesireCard
	await _physics(2)
	check(card.visible and (card.get_node("%DesireText") as Label).text.contains("味道"), "HUD card shows what the dog wants")
	var scent_park := _cue(&"scent_park")
	var scent_alley := _cue(&"scent_alley")
	check(scent_park.visible and scent_park.active, "world cue: park scent appears")
	check(not scent_alley.visible, "unrelated scent stays hidden")
	var rival := _pair(p, &"pair_rival")
	check(not rival.is_present() and not rival.visible, "rival unknown at first")
	check((p.hud as DesireHUD).get_node("%HintArrow").visible, "nose arrow points to the far-away scent")

	var started: Array[StringName] = []
	director.desire_started.connect(func(d: DesireData, reason: StringName) -> void: started.append(StringName("%s:%s" % [d.id, reason])))
	await _interact_at(dog, scent_park)
	check(Game.goal_progress.state_of(&"desire_strange_scent") == GoalProgress.State.COMPLETED, "sniffed the strange scent")
	check_eq(run.human_run_inventory.count_item(&"half_tennis_ball"), 1, "clue item found")
	check(started.has(&"desire_whose_ball:follow_up"), "follow-up: whose ball?")
	check(started.has(&"desire_bring_clue_home:emergent"), "emergent: bring the clue home")
	check(scent_alley.visible and not scent_park.visible, "cue moves to the alley trail")

	# Squirrel in the park: emergent chase.
	var squirrel := _tree.current_scene.get_node("Actors/Squirrel") as Squirrel
	check(squirrel.visible and squirrel.state == Squirrel.State.IDLE, "squirrel waiting in the park")
	dog.global_position = squirrel.global_position + Vector2(0, 150)
	await _physics(3)
	check(started.has(&"desire_chase_squirrel:emergent"), "emergent: chase the squirrel")
	for i in int(squirrel.chase_seconds * 60) + 30:
		dog.global_position = squirrel.global_position + Vector2(0, 120)
		await _tree.physics_frame
	check_eq(squirrel.state, Squirrel.State.TREED, "chasing the squirrel trees it")
	check_eq(Game.goal_progress.state_of(&"desire_chase_squirrel"), GoalProgress.State.COMPLETED, "squirrel desire fulfilled")

	# Keep the clue safe and go home.
	var clue := run.human_run_inventory.take_stack(_find_slot(run.human_run_inventory, &"half_tennis_ball"))
	run.dog_safe_inventory.add_item(clue.item, clue.quantity)
	run.debug_unlock_all_extractions()
	run.extract(&"bus_stop")
	await _wait_for_scene(Game.RUN_RESULT_SCENE)
	var progress := Game.goal_progress
	check_eq(progress.state_of(&"desire_bring_clue_home"), GoalProgress.State.COMPLETED, "clue brought home")
	check_eq(progress.state_of(&"desire_whose_ball"), GoalProgress.State.DORMANT, "unresolved thread kept for next walk")
	check(progress.is_discovered(&"items", &"half_tennis_ball") and progress.is_discovered(&"places", &"park"), "discoveries recorded")

	# Persistence.
	Game.goal_progress.clear()
	SaveManager.load_game()
	Game.load_profile()
	progress = Game.goal_progress
	check_eq(progress.state_of(&"desire_whose_ball"), GoalProgress.State.DORMANT, "thread survives save/load")
	_tree.current_scene.get_node("%HomeButton").pressed.emit()
	await _wait_for_scene(Game.HOME_SCENE)
	var home_text := (_tree.current_scene.get_node("%GoalsLabel") as Label).text
	check(home_text.contains("掛念") and home_text.contains("半顆網球"), "Home: the dog still wonders about the ball")

	# --- Walk 2: the thread resumes and reveals the rival ------------------------------
	_tree.current_scene.get_node("%WalkButton").pressed.emit()
	await _wait_for_scene(Game.RUN_MAP_SCENE)
	await _physics(3)
	p = _parts()
	run = p.run
	director = p.director
	dog = run.dog
	(p.coordinator as CombatCoordinator).time_scale = 25.0
	check(director.active_desires().any(func(d: DesireData) -> bool: return d.id == &"desire_whose_ball"), "walk 2 continues the thread")
	scent_alley = _cue(&"scent_alley")
	await _interact_at(dog, scent_alley)
	rival = _pair(p, &"pair_rival")
	check(rival.is_present() and rival.visible, "rival appears once revealed")
	check(director.active_desires().any(func(d: DesireData) -> bool: return d.id == &"desire_find_rival"), "now: find the rival")
	dog.global_position = rival.human_global_position() + Vector2(-150, 60)
	(p.human as HumanFollower).global_position = dog.global_position + Vector2(-60, 40)
	await _physics(4)
	check(director.active_desires().any(func(d: DesireData) -> bool: return d.id == &"desire_rival_duel"), "meeting the rival: duel desire")
	check(Game.goal_progress.is_discovered(&"dogs", &"enc_rival"), "rival discovered")
	check((rival.get_node("%NameLabel") as Label).text.begins_with("❗"), "world cue: rival marked")

	(p.human as HumanFollower).fighter = OLD_MASTER
	dog.global_position = rival.global_position + Vector2(-60, 20)
	(p.human as HumanFollower).global_position = rival.global_position + Vector2(-140, 40)
	await _physics(4)
	(p.coordinator as CombatCoordinator).start_engagement(rival)
	await _wait_until(func() -> bool: return (p.coordinator as CombatCoordinator).engagements.is_empty(), 900)
	check(Game.goal_progress.has_flag(&"rival_beaten"), "beating the rival resolves the thread")

	# --- Debug tools ------------------------------------------------------------------
	var debug := _tree.current_scene.get_node("RunHUD").get_node("%DebugPanel") as DebugPanel
	debug.get_node("%ResetGoalsButton").pressed.emit()
	check(Game.goal_progress.flags.is_empty() and Game.goal_progress.walks == 0, "debug: goals reset")

	DirAccess.remove_absolute(TEST_SAVE)
	finish()


# --- helpers ---------------------------------------------------------------

func _parts() -> Dictionary:
	var map := _tree.current_scene
	return {
		"run": map.get_node("RunManager"),
		"director": map.get_node("GoalDirector"),
		"coordinator": map.get_node("CombatCoordinator"),
		"hud": map.get_node("DesireHUD"),
		"human": map.get_node("Actors/Human"),
	}


func _cue(id: StringName) -> ScentCue:
	for node in _tree.get_nodes_in_group(ScentCue.GROUP):
		if (node as ScentCue).cue_id == id:
			return node
	return null


func _pair(p: Dictionary, spot: StringName) -> OpponentPair:
	for pair in (p.coordinator as CombatCoordinator).get_pairs():
		if pair.spot_id == spot:
			return pair
	return null


func _interact_at(dog: DogController, target: Node2D) -> void:
	dog.global_position = target.global_position
	dog.velocity = Vector2.ZERO
	await _physics(4)
	check(dog.focused == target, "dog focuses %s" % target.name)
	Input.action_press(&"interact")
	await _tree.physics_frame
	Input.action_release(&"interact")
	await _physics(2)


func _find_slot(inventory: Inventory, item_id: StringName) -> int:
	for i in inventory.capacity:
		var stack := inventory.stack_at(i)
		if stack != null and stack.item_id == item_id:
			return i
	return -1


func _wait_until(done: Callable, max_frames: int) -> void:
	for i in max_frames:
		if done.call():
			return
		await _tree.physics_frame
	check(false, "timed out waiting")


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
