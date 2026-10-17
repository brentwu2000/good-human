extends "res://tests/test_case.gd"
## Xiaomi toy proxy (docs/04_systems/XIAOMI_TOY_PROXY.md, Phase 1), through the
## real 3D walk with Xiaomi as the adopted owner. Her bunny robot fights; she
## steps away, is never on the fighting side, never hit, never knocked down.
## Win, call-back and loss all clean the robot up; a loss is the robot's
## battery, and the walk's usual loss rules still apply.

const TEST_SAVE: String = "user://tests/xiaomi_proxy_save.json"

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

	# Xiaomi is the dog's human.
	var bg := DataRegistry.get_human_background(&"granddaughter")
	check(bg != null and bg.combat_proxy != null, "the granddaughter background has a robot to fight for her")
	var xiaomi := HumanCandidate.new()
	xiaomi.id = &"human_xiaomi"
	xiaomi.background_id = &"granddaughter"
	xiaomi.reaction_set = &"granddaughter"
	for stat in HumanCandidate.STAT_NAMES:
		xiaomi.stats[stat] = 5
	Game.pair_state = PairState.adopted(PairState.classic().dog, xiaomi, "小米", "")
	check(Game.owner_has_proxy(), "her fights are fought by a proxy")
	check_eq(Game.owner_fighter().skeletal_model, bg.skeletal_model, "she walks as her own model")
	check_eq(Game.owner_proxy_fighter().body_kind, &"bunny_robot", "the proxy is the bunny robot")
	check_eq(Game.owner_proxy_fighter().stats.strength, 5, "with her own rolled stats")

	_tree.current_scene.get_node("%Walk3DButton").pressed.emit()
	await _wait_for_scene(Game.RUN_MAP_3D_SCENE)
	await _frames(5)
	var map := _tree.current_scene as RunMap3D
	var run := map.run_manager
	var coordinator := map.coordinator
	var human := map.human
	var dog := map.dog
	check(coordinator.uses_proxy(), "the walk knows her robot fights")

	# She carries a weapon in her backpack, not in her hand.
	var umbrella := ItemStack.new(DataRegistry.get_item(&"umbrella"), 1)
	run.take_weapon(umbrella)
	await _frames(2)
	check(human.puppet.held == null, "a weapon she finds goes in her backpack, not her hand")

	# --- A fight her robot wins -------------------------------------------------
	var pairs := _present(coordinator)
	check(pairs.size() >= 2, "at least two pairs are out (%d)" % pairs.size())
	var first := pairs[0]
	_stand_beside(human, dog, first)
	coordinator.time_scale = 0.0
	coordinator.start_engagement(first)
	await _frames(2)
	check(coordinator.is_fighting(), "the fight starts where they stand")
	check(coordinator.proxy != null, "her robot comes out")
	check(coordinator.fighter_node() == coordinator.proxy, "the robot is the body on her side")
	check(coordinator.proxy.puppet.find_child("BunnyRobot", true, false) != null, "built as the bunny robot")
	check_eq(human.state, HumanFollower3D.State.SAFE, "she steps back to safety")
	check_eq(coordinator.proxy.puppet.held, umbrella_weapon(), "the robot holds what she carries")
	check(human.puppet.held == null, "she does not")

	# Watch the fight: she is never in it, her robot takes every blow.
	coordinator.time_scale = 1.0
	var start_hp := coordinator.engagement.simulation.fighters[CombatSimulation.PLAYER].hp
	var closest := INF
	var bad_state := false
	var t := 0.0
	while t < 6.0 and coordinator.is_fighting():
		await _frames(1)
		t += get_process_delta_time()
		if human.state in [HumanFollower3D.State.COMBAT, HumanFollower3D.State.DOWN]:
			bad_state = true
		if t > 1.5 and coordinator.is_fighting():
			closest = minf(closest, _flat(human.global_position - first.human_global_position()))
	check(not bad_state, "she never enters the fight or goes down")
	check(closest >= 1.8, "she keeps well clear of the opponent (closest %.2f m)" % closest)
	check(human.puppet.condition_state() == FighterPuppet3D.Condition.HEALTHY, "she is never hurt")
	if coordinator.is_fighting():
		check(coordinator.engagement.simulation.fighters[CombatSimulation.PLAYER].hp <= start_hp, "the robot is the one taking blows")
		coordinator.debug_force_result(CombatSimulation.Result.VICTORY)
	await _frames(3)
	check(not coordinator.is_fighting(), "the fight ends")
	check(coordinator.proxy == null, "the robot packs away after a win")
	check_eq(human.state, HumanFollower3D.State.FOLLOW, "and she walks on")
	await _seconds(2.5)
	check(map.find_child("BunnyProxy", true, false) == null, "and is gone from the world")

	# --- Called back: the dog drags off, the robot returns ------------------------
	var second := pairs[1]
	_stand_beside(human, dog, second)
	coordinator.start_engagement(second)
	await _frames(2)
	check(coordinator.proxy != null, "a second fight brings it out again")
	coordinator.debug_force_result(CombatSimulation.Result.DISENGAGED)
	await _frames(3)
	check(coordinator.proxy == null and human.state == HumanFollower3D.State.FOLLOW, "called back, it packs away and she walks on")

	# --- A fight her robot loses ------------------------------------------------
	await _seconds(1.0)
	var left := _present(coordinator)
	check(not left.is_empty(), "a pair is left to meet")
	var third := left[0]
	_stand_beside(human, dog, third)
	coordinator.start_engagement(third)
	await _frames(2)
	check(coordinator.is_fighting(), "a third fight starts")
	coordinator.debug_force_result(CombatSimulation.Result.DEFEAT)
	await _frames(3)
	check(human.state != HumanFollower3D.State.DOWN, "a loss never knocks her down")
	check(not human.puppet.condition_state() == FighterPuppet3D.Condition.DOWN, "she plays no fall")
	check(coordinator.proxy_defeated, "the robot's battery ran flat")
	check(coordinator.is_owner_down(), "the walk still counts it as a loss")
	coordinator.time_scale = 50.0
	await _wait_for_scene(Game.RUN_RESULT_SCENE)
	var result := Game.last_run_result
	check(result != null and result.outcome == RunResult.Outcome.DEFEATED, "the walk ends in defeat, same rules")
	check(result != null and _ids(result.lost).has("umbrella"), "what she carried is lost like anyone's")
	await _frames(2)
	var title: String = _tree.current_scene.get("_title_label").text
	check(title.contains("兔兔") and not title.contains("醫院"), "the result says the robot is being repaired, not a hospital (%s)" % title)
	finish()


func umbrella_weapon() -> WeaponData:
	return DataRegistry.weapon_for_item(&"umbrella")


## Pairs that are in the park right now (some only come at certain times).
func _present(coordinator: CombatCoordinator3D) -> Array[OpponentPair3D]:
	var out: Array[OpponentPair3D] = []
	for p in coordinator.get_pairs():
		if p.is_present() and p.is_idle():
			out.append(p)
	return out


func _stand_beside(human: HumanFollower3D, dog: DogController3D, pair: OpponentPair3D) -> void:
	dog.global_position = pair.global_position + Vector3(0.7, 0.2, 0.9)
	dog.velocity = Vector3.ZERO
	human.global_position = pair.global_position + Vector3(1.6, 0.2, 2.0)


func _flat(v: Vector3) -> float:
	return Vector2(v.x, v.z).length()


func _ids(stacks: Array) -> Array:
	var out: Array = []
	for s in stacks:
		out.append(String(s.item_id) if s is ItemStack else String(s))
	return out


func _frames(count: int) -> void:
	for i in count:
		await _tree.process_frame


func _seconds(s: float) -> void:
	await _tree.create_timer(s).timeout


func _wait_for_scene(path: String) -> void:
	for i in 600:
		if _tree.current_scene != null and _tree.current_scene.scene_file_path == path:
			return
		await _tree.process_frame
	check(false, "scene %s never loaded" % path)
