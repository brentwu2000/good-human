extends "res://tests/test_case.gd"
## Sprint 03 through the real scenes: dog behaviour creates all five tags
## (P2-003..007), extraction converts them, growth persists, the result and
## Home describe it in words (P2-018), and a trained owner visibly behaves
## differently on the next walk (P2-015..017). Debug tools (P2-019).

const TEST_SAVE: String = "user://tests/training_world_save.json"
const SEED: int = 777

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
	check((_tree.current_scene.get_node("%GrowthLabel") as Label).text.contains("普通"), "Home: untrained owner")
	_tree.current_scene.get_node("%WalkButton").pressed.emit()
	await _wait_for_scene(Game.RUN_MAP_SCENE)
	await _physics(3)

	var parts := _parts()
	var run: RunManager = parts.run
	var human: HumanFollower = parts.human
	var behavior: OwnerBehavior = parts.behavior
	var coordinator: CombatCoordinator = parts.coordinator
	var dog := run.dog
	coordinator.time_scale = 25.0
	run.start_run(SEED)
	await _physics(2)
	var balance := DataRegistry.training
	check_eq(behavior.traits.hesitation_time, balance.hesitation_untrained, "untrained owner hesitates")

	# --- RUN: dragging the owner along (untrained owner stumbles) -------------
	var stumbles: Array[int] = [0]
	behavior.stumbled.connect(func() -> void: stumbles[0] += 1)
	await _drag(dog, human, Vector2.UP, 4.0)
	check(_count(run, &"run_dragged") >= 1, "RUN: being dragged along")
	check(stumbles[0] >= 1, "visible 1: untrained owner stumbles while dragged")

	# --- ENDURE: exhaustion and a long walk -------------------------------------
	var exhausted: Array[int] = [0]
	behavior.exhausted.connect(func() -> void: exhausted[0] += 1)
	behavior.exertion = 0.99
	await _drag(dog, human, Vector2.DOWN, 1.0)
	check(exhausted[0] == 1 and human.hold_time > 1.0, "visible 2: untrained owner stops to catch breath for a while")
	check_eq(_count(run, &"endure_exhausted"), 1, "ENDURE: pushed through exhaustion")
	await _hold_until_free(human)
	parts.observer._walk_distance = TrainingObserver.LONG_WALK_DISTANCE - 5.0
	await _drag(dog, human, Vector2.UP, 0.5)
	check_eq(_count(run, &"endure_long_walk"), 1, "ENDURE: long walk")

	# --- STRAIN: heavy bag slows the owner; dog tugging a stuck owner ----------
	for i in balance.heavy_bag_slots:
		run.debug_give_item(&"boxing_gloves")
	await _physics(2)
	check_eq(human.speed_multiplier, balance.heavy_bag_speed_untrained, "visible 3: heavy bag slows the untrained owner")
	parts.observer._heavy_distance = TrainingObserver.HEAVY_BAG_DISTANCE - 5.0
	await _drag(dog, human, Vector2.DOWN, 0.5)
	check(_count(run, &"strain_heavy_bag") >= 1, "STRAIN: carrying a heavy bag")
	run.human_run_inventory.clear()
	human.hold_time = 1.5
	dog.global_position = human.global_position + Vector2(0, -300)
	await _physics(50)
	check(_count(run, &"strain_tug") >= 1, "STRAIN: dog pulls a stuck owner")
	await _hold_until_free(human)

	# --- SOCIAL + hesitation near a pair --------------------------------------
	var pair: OpponentPair = coordinator.get_pairs().filter(func(p: OpponentPair) -> bool: return p.encounter.tier == EncounterData.Tier.ORDINARY)[0]
	dog.global_position = pair.global_position + Vector2(-120, 60)
	human.global_position = dog.global_position + Vector2(-60, 40)
	await _physics(3)
	check(human.hold_time > 0.5, "visible 4: owner hangs back near an unfamiliar pair")
	await _seconds(TrainingObserver.LINGER_SECONDS + 0.4, dog, pair.global_position + Vector2(-120, 60))
	check_eq(_count(run, &"social_linger"), 1, "SOCIAL: lingering near a pair")
	await _seconds(TrainingObserver.LINGER_SECONDS + 0.4, dog, pair.global_position + Vector2(-120, 60))
	check_eq(_count(run, &"social_linger"), 1, "SOCIAL: once per pair per walk")

	# --- COURAGE: provoke, then run away hurt ---------------------------------
	await _hold_until_free(human)
	dog.global_position = pair.global_position + Vector2(-60, 20)
	human.global_position = pair.global_position + Vector2(-140, 40)
	await _physics(4)
	coordinator.start_engagement(pair)
	check_eq(_count(run, &"courage_provoke"), 1, "COURAGE: provoking a pair")
	coordinator.engagements[0].simulation.fighters[0].hp *= 0.3
	dog.global_position = human.global_position + Vector2(0, DataRegistry.balance.disengage_distance + 150.0)
	await _physics(3)
	check_eq(_count(run, &"run_escape"), 1, "RUN: escaping a fight")
	check_eq(_count(run, &"courage_escape"), 1, "COURAGE: getting out while hurt")

	for tag in TrainingEventData.Tag.values():
		check(run.training.total(tag) > 0.0, "%s gathered this walk" % TrainingEventData.tag_name(tag))
	var raw: Dictionary = run.training.totals.duplicate()

	# --- Extraction converts everything; result describes it in words -----------
	run.debug_unlock_all_extractions()
	run.extract(&"bus_stop")
	await _wait_for_scene(Game.RUN_RESULT_SCENE)
	for tag in TrainingEventData.Tag.values():
		check(is_equal_approx(Game.human_growth.get_growth(tag), raw[tag]), "%s fully converted" % TrainingEventData.tag_name(tag))
	var text := (_tree.current_scene.get_node("%ItemsLabel") as Label).text
	check(text.contains("今天的散步，主人") and text.contains("被狗拖著跑了一大段路"), "result describes experiences")
	for tag_name: String in TrainingEventData.Tag.keys():
		check(not text.contains(tag_name), "result hides raw tag %s" % tag_name)

	SaveManager.load_game()
	Game.load_profile()
	check(is_equal_approx(Game.human_growth.get_growth(TrainingEventData.Tag.RUN), raw[TrainingEventData.Tag.RUN]), "growth persisted to save")

	# --- Debug: full growth, then the same walk looks different -----------------
	_tree.current_scene.get_node("%HomeButton").pressed.emit()
	await _wait_for_scene(Game.HOME_SCENE)
	_tree.current_scene.get_node("%WalkButton").pressed.emit()
	await _wait_for_scene(Game.RUN_MAP_SCENE)
	await _physics(3)
	parts = _parts()
	run = parts.run
	human = parts.human
	behavior = parts.behavior
	coordinator = parts.coordinator
	dog = run.dog
	var debug := _tree.current_scene.get_node("RunHUD").get_node("%DebugPanel") as DebugPanel
	debug.get_node("%GrowFullButton").pressed.emit()
	check(Game.human_growth.perks.size() == balance.perks.size(), "debug: full growth unlocks every perk")
	check_eq(behavior.traits.hesitation_time, balance.hesitation_trained, "trained owner does not hesitate")
	var trained_stumbles: Array[int] = [0]
	behavior.stumbled.connect(func() -> void: trained_stumbles[0] += 1)
	await _drag(dog, human, Vector2.UP, 4.0)
	check_eq(trained_stumbles[0], 0, "trained owner keeps up without stumbling")
	for i in balance.heavy_bag_slots:
		run.debug_give_item(&"boxing_gloves")
	await _physics(2)
	check_eq(human.speed_multiplier, 1.0, "trained owner is not slowed by a heavy bag")
	behavior.exertion = 0.99
	await _drag(dog, human, Vector2.DOWN, 3.0)
	check(human.hold_time <= balance.recovery_trained, "trained owner catches breath quickly")
	var other: OpponentPair = coordinator.get_pairs()[0]
	dog.global_position = other.global_position + Vector2(-120, 60)
	human.global_position = dog.global_position + Vector2(-60, 40)
	await _physics(3)
	check(human.hold_time <= balance.recovery_trained, "trained owner walks up to pairs without hanging back")
	run.start_run(SEED + 2)
	await _physics(2)
	var fighter := human.fighter
	check(fighter.stats.agility > (load("res://data/combat/fighters/player_human.tres") as FighterData).stats.agility, "growth shows up in combat stats")

	debug.get_node("%ResetGrowthButton").pressed.emit()
	check(Game.human_growth.perks.is_empty(), "debug: growth reset")

	# --- Defeat keeps half ------------------------------------------------------
	run.start_run(SEED + 1)
	human.global_position = Vector2(-1500, 300)
	dog.global_position = human.global_position + Vector2(100, 0)
	await _physics(2)
	await _drag(dog, human, Vector2.RIGHT, 3.8)
	var dragged := run.training.total(TrainingEventData.Tag.RUN)
	check(dragged > 0.0, "gathered RUN before defeat")
	run.defeat_run("測試")
	await _wait_for_scene(Game.RUN_RESULT_SCENE)
	check(is_equal_approx(Game.human_growth.get_growth(TrainingEventData.Tag.RUN), dragged * balance.defeat_conversion), "defeat keeps half the learning")
	check((_tree.current_scene.get_node("%ItemsLabel") as Label).text.contains("只記住了一半"), "result explains partial learning")
	_tree.current_scene.get_node("%HomeButton").pressed.emit()
	await _wait_for_scene(Game.HOME_SCENE)
	check(not (_tree.current_scene.get_node("%GrowthLabel") as Label).text.is_empty(), "Home describes the owner")

	DirAccess.remove_absolute(TEST_SAVE)
	finish()


# --- helpers ---------------------------------------------------------------

func _parts() -> Dictionary:
	var map := _tree.current_scene
	return {
		"run": map.get_node("RunManager"),
		"human": map.get_node("Actors/Human"),
		"behavior": map.get_node("OwnerBehavior"),
		"observer": map.get_node("TrainingObserver"),
		"coordinator": map.get_node("CombatCoordinator"),
	}


## Keeps the dog running ahead of the owner so the leash stays taut.
func _drag(dog: DogController, human: HumanFollower, direction: Vector2, seconds: float) -> void:
	var frames := int(seconds * Engine.physics_ticks_per_second)
	for i in frames:
		dog.global_position = human.global_position + direction * 165.0
		dog.velocity = Vector2.ZERO
		await _tree.physics_frame


func _seconds(seconds: float, dog: DogController, at: Vector2) -> void:
	for i in int(seconds * Engine.physics_ticks_per_second):
		dog.global_position = at
		await _tree.physics_frame


func _hold_until_free(human: HumanFollower) -> void:
	for i in 400:
		if human.hold_time <= 0.0:
			return
		await _tree.physics_frame


func _count(run: RunManager, event_id: StringName) -> int:
	return run.training.events.filter(func(e: TrainingEvent) -> bool: return e.data.id == event_id).size()


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
