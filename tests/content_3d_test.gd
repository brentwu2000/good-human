extends "res://tests/test_case.gd"
## P-03 through the real 3D walk: owner behaviour, training events, dog
## desires with world cues, the Strange Scent chain revealing the rival, the
## squirrel, discoveries, conversion/persistence and debug hooks.

const TEST_SAVE: String = "user://tests/content_3d_save.json"
const OLD_MASTER: FighterData = preload("res://data/combat/fighters/oppx01_old_master.tres")

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
	await _physics(5)

	var map := _tree.current_scene as RunMap3D
	var run := map.run_manager
	var dog := map.dog
	var human := map.human
	var coordinator := map.coordinator
	var director := map.get_node("GoalDirector") as GoalDirector
	var behavior := map.get_node("OwnerBehavior") as OwnerBehavior
	var hud := map.get_node("DesireHUD") as DesireHUD
	coordinator.time_scale = 25.0

	# --- Content present ------------------------------------------------------------
	var pairs := coordinator.get_pairs()
	var present := pairs.filter(func(p: OpponentPair3D) -> bool: return p.is_present())
	check_eq(pairs.size(), 5, "five pair spots in 3D")
	check_eq(present.size(), 4, "rival hidden at first")
	var ids: Dictionary = {}
	for p: OpponentPair3D in present:
		ids[p.encounter.id] = true
	check(ids.has(&"enc_old_master") and ids.has(&"enc_jogger") and ids.has(&"enc_delivery") and ids.has(&"enc_gym"), "ordinary pairs shuffled in + Old Master")
	var rival := map.get_node("Encounters/pair_rival") as OpponentPair3D
	check(not rival.visible, "rival not visible yet")

	# --- Desire at walk start + cues -------------------------------------------------
	check(director.active_desires().size() == 1 and director.active_desires()[0].id == &"desire_strange_scent", "3D walk starts with a dog desire")
	await _physics(2)
	var card := hud.get_node("%DesireCard") as DesireCard
	check(card.visible and (card.get_node("%DesireText") as Label).text.contains("味道"), "desire card shown in 3D")
	var scent_park := map.get_node("Goals/scent_park") as ScentCue3D
	var scent_alley := map.get_node("Goals/scent_alley") as ScentCue3D
	check(scent_park.visible and not scent_alley.visible, "park scent cue appears")
	check(hud.get_node("%HintArrow").visible, "nose arrow points to the far scent")
	check(Game.goal_progress.is_discovered(&"places", &"street"), "start place discovered")

	# --- Owner behaviour + training: dragging --------------------------------------------
	var stumbles: Array[int] = [0]
	behavior.stumbled.connect(func() -> void: stumbles[0] += 1)
	await _drag(dog, human, 4.0)
	check(_count(run, &"run_dragged") >= 1, "RUN: dragging the owner in 3D")
	check(stumbles[0] >= 1, "untrained owner stumbles in 3D")

	# --- Strange scent: clue -> follow-up -------------------------------------------------
	var started: Array[StringName] = []
	director.desire_started.connect(func(d: DesireData, reason: StringName) -> void: started.append(d.id))
	await _interact_at(dog, human, scent_park)
	check_eq(Game.goal_progress.state_of(&"desire_strange_scent"), GoalProgress.State.COMPLETED, "sniffed the park scent")
	check_eq(run.human_run_inventory.count_item(&"half_tennis_ball"), 1, "clue item found in 3D")
	check(started.has(&"desire_whose_ball") and scent_alley.visible, "follow-up points to the alley")
	check(Game.goal_progress.is_discovered(&"places", &"park"), "park discovered")

	# --- Squirrel -------------------------------------------------------------------------
	var squirrel := map.get_node("Goals/Squirrel") as Squirrel3D
	check(squirrel.visible and squirrel.state == Squirrel3D.State.IDLE, "squirrel in the 3D park")
	dog.global_position = squirrel.global_position + Vector3(0, 0.1, 2.5)
	await _physics(3)
	check(started.has(&"desire_chase_squirrel"), "spotting the squirrel makes the dog want to chase")
	for i in int(squirrel.chase_seconds * 60) + 30:
		dog.global_position = squirrel.global_position + Vector3(0, 0.1, 1.5)
		await _tree.physics_frame
	check_eq(squirrel.state, Squirrel3D.State.TREED, "chased squirrel goes up a tree")
	check_eq(Game.goal_progress.state_of(&"desire_chase_squirrel"), GoalProgress.State.COMPLETED, "squirrel desire fulfilled")

	# --- Hesitation, provoke, escape --------------------------------------------------------
	var pair := map.get_node("Encounters/pair_park") as OpponentPair3D
	human.hold_time = 0.0
	dog.global_position = pair.global_position + Vector3(0, 0.1, 2.2)
	human.global_position = dog.global_position + Vector3(0.6, 0, 1.2)
	await _physics(3)
	check(human.hold_time > 0.0, "owner hangs back near an unfamiliar pair (3D)")
	await _hold_until_free(human)
	await _interact_at(dog, human, pair)
	check(coordinator.is_fighting(), "provoked the park pair")
	check_eq(_count(run, &"courage_provoke"), 1, "COURAGE: provoking in 3D")
	coordinator.engagement.simulation.fighters[0].hp *= 0.3
	dog.global_position = human.global_position + Vector3(0, 0, CombatCoordinator3D.DISENGAGE_DISTANCE + 2.0)
	await _physics(3)
	check(_count(run, &"run_escape") == 1 and _count(run, &"courage_escape") == 1, "RUN + COURAGE: escaping hurt")
	check(Game.goal_progress.is_discovered(&"dogs", pair.encounter.id), "met pair discovered")

	# --- Alley scent reveals the rival -------------------------------------------------------
	await _hold_until_free(human)
	await _interact_at(dog, human, scent_alley)
	check(rival.is_present() and rival.visible, "rival appears once revealed (3D)")
	dog.global_position = rival.human_global_position() + Vector3(0, 0.1, 2.2)
	human.global_position = dog.global_position + Vector3(0.5, 0, 1.2)
	await _physics(4)
	check(director.active_desires().any(func(d: DesireData) -> bool: return d.id == &"desire_rival_duel"), "meeting 阿黑 wants a duel")
	check(rival.get_child_count() > 0 and (rival._name_label.text as String).begins_with("❗"), "rival marked as wanted")
	check(Game.goal_progress.is_discovered(&"places", &"alley"), "alley discovered")

	# --- Debug panel works in 3D ----------------------------------------------------------------
	var debug := map.get_node("RunHUD").get_node("%DebugPanel") as DebugPanel
	await _hold_until_free(human)
	debug.get_node("%NextEncounterButton").pressed.emit()
	await _physics(4)
	check(dog.focused is OpponentPair3D, "debug: next pair puts the dog at a pair in 3D")

	# --- Extraction converts training and saves goals ---------------------------------------------
	var raw_run := run.training.total(TrainingEventData.Tag.RUN)
	run.debug_unlock_all_extractions()
	run.extract(&"bus_stop")
	await _wait_for_scene(Game.RUN_RESULT_SCENE)
	check(is_equal_approx(Game.human_growth.get_growth(TrainingEventData.Tag.RUN), raw_run), "3D training converted on extraction")
	check_eq(Game.goal_progress.state_of(&"desire_rival_duel"), GoalProgress.State.DORMANT, "rival duel thread kept for the next walk")
	SaveManager.load_game()
	Game.load_profile()
	check(Game.goal_progress.has_flag(&"rival_revealed"), "3D goal progress saved")

	# --- Next 3D walk: rival present from the start, thread resumes ------------------------------------
	_tree.current_scene.get_node("%HomeButton").pressed.emit()
	await _wait_for_scene(Game.HOME_SCENE)
	_tree.current_scene.get_node("%Walk3DButton").pressed.emit()
	await _wait_for_scene(Game.RUN_MAP_3D_SCENE)
	await _physics(5)
	map = _tree.current_scene as RunMap3D
	director = map.get_node("GoalDirector") as GoalDirector
	rival = map.get_node("Encounters/pair_rival") as OpponentPair3D
	check(rival.is_present(), "rival present on the next 3D walk")
	check(director.active_desires().any(func(d: DesireData) -> bool: return d.id == &"desire_rival_duel"), "duel thread resumes")
	map.human.fighter = OLD_MASTER
	map.coordinator.time_scale = 25.0
	await _interact_at(map.dog, map.human, rival)
	await _wait_until(func() -> bool: return not map.coordinator.is_fighting(), 900)
	check(Game.goal_progress.has_flag(&"rival_beaten"), "beating 阿黑 resolves the thread in 3D")

	DirAccess.remove_absolute(TEST_SAVE)
	finish()


# --- helpers ---------------------------------------------------------------

## Dog runs ahead so the owner is dragged, back and forth along the street.
func _drag(dog: DogController3D, human: HumanFollower3D, seconds: float) -> void:
	human.global_position = Vector3(-10, 0.1, 0)
	var direction := Vector3.RIGHT
	for i in int(seconds * 60):
		if human.global_position.x > 12.0:
			direction = Vector3.LEFT
		elif human.global_position.x < -12.0:
			direction = Vector3.RIGHT
		dog.global_position = human.global_position + direction * 2.4 + Vector3(0, 0, 0)
		dog.velocity = Vector3.ZERO
		await _tree.physics_frame


func _interact_at(dog: DogController3D, human: HumanFollower3D, target: Node3D) -> void:
	dog.global_position = target.global_position + Vector3(0.6, 0.1, 0.6)
	dog.velocity = Vector3.ZERO
	human.global_position = dog.global_position + Vector3(1.0, 0, 1.0)
	await _physics(4)
	check(dog.focused == target, "dog focuses %s" % target.name)
	Input.action_press(&"interact")
	await _tree.physics_frame
	Input.action_release(&"interact")
	await _physics(2)


func _hold_until_free(human: HumanFollower3D) -> void:
	for i in 400:
		if human.hold_time <= 0.0:
			return
		await _tree.physics_frame


func _count(run: RunManager, event_id: StringName) -> int:
	return run.training.events.filter(func(e: TrainingEvent) -> bool: return e.data.id == event_id).size()


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
