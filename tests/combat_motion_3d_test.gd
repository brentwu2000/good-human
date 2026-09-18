extends "res://tests/test_case.gd"
## P-03 P03-E01 in the real 3D walk: the humans are bodies in a fight, not two
## statues exchanging HP. The exit gate is that a fight reads with the combat
## text hidden, so every check here is about what the world actually does.

const TEST_SAVE: String = "user://tests/combat_motion_save.json"

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
	var coordinator := map.coordinator
	var dog := map.dog
	var human := map.human
	var pair := map.get_node("Encounters/pair_park") as OpponentPair3D

	_test_states_are_authored()

	# Start a fight and watch it as the player would.
	dog.global_position = pair.global_position + Vector3(1.0, 0.1, 1.0)
	await _physics(6)
	pair.interact(map.run_manager)
	await _physics(6)
	check(coordinator.is_fighting(), "the fight is on")
	var ours := human.puppet
	var theirs := pair.human_puppet

	# The humans move. This is the requirement the spec states plainly:
	# they must not stand fixed and exchange HP.
	var our_start := human.global_position
	var their_start := pair.human_global_position()
	var our_travel := 0.0
	var their_travel := 0.0
	var states: Dictionary[int, bool] = {}
	var our_previous := our_start
	var their_previous := their_start
	for i in 240:
		await _tree.physics_frame
		if not coordinator.is_fighting():
			break
		our_travel += human.global_position.distance_to(our_previous)
		their_travel += pair.human_global_position().distance_to(their_previous)
		our_previous = human.global_position
		their_previous = pair.human_global_position()
		states[int(ours.motion.state)] = true
		states[int(theirs.motion.state)] = true
	check(our_travel > 0.5, "the owner moves their feet during a fight (%.2f m)" % our_travel)
	check(their_travel > 0.5, "so does the opponent (%.2f m)" % their_travel)

	# And they do recognisably different things while doing it.
	check(states.size() >= 3, "the fight passes through several body states (%d)" % states.size())
	check(states.has(int(CombatMotion3D.State.WINDUP)), "attacks are telegraphed, which is what the dog reacts to")
	var moving_states := states.has(int(CombatMotion3D.State.APPROACH)) or states.has(int(CombatMotion3D.State.CIRCLE))
	check(moving_states, "they close the distance or work for an angle, rather than only trading blows")

	finish()


## The states the spec asks for, and the reaction hold that makes a hit read.
func _test_states_are_authored() -> void:
	for required: String in ["IDLE_COMBAT", "APPROACH", "CIRCLE", "WINDUP", "ATTACK", "BLOCK", "DODGE", "HIT_REACT", "STAGGER", "DOWN", "RECOVER"]:
		check(CombatMotion3D.State.keys().has(required), "the spec's %s state exists" % required)

	var motion := CombatMotion3D.new()
	var balance := DataRegistry.balance
	var fighter := CombatFighter.new(preload("res://data/combat/fighters/opp01_jogger.tres"), 0, balance)
	motion.update(0.1, fighter, true, false)
	check_eq(motion.state, CombatMotion3D.State.APPROACH, "far away and free: they close in")
	motion.update(0.1, fighter, false, false)
	check_eq(motion.state, CombatMotion3D.State.CIRCLE, "in range and free: they work for an angle")

	# A hit holds the body for its own moment rather than flickering back.
	motion.react(false)
	motion.update(0.01, fighter, false, false)
	check_eq(motion.state, CombatMotion3D.State.HIT_REACT, "a hit reads as a hit")
	motion.update(CombatMotion3D.REACT_SECONDS, fighter, false, false)
	motion.update(0.01, fighter, false, false)
	check_eq(motion.state, CombatMotion3D.State.CIRCLE, "and then the fight takes the body back")
	motion.react(true)
	motion.update(0.01, fighter, false, false)
	check_eq(motion.state, CombatMotion3D.State.STAGGER, "a stagger reads as worse than a hit")
	check(CombatMotion3D.STAGGER_SECONDS > CombatMotion3D.REACT_SECONDS, "and holds longer")

	motion.update(0.01, fighter, false, true)
	check_eq(motion.state, CombatMotion3D.State.DOWN, "being defeated overrides everything")
	check(motion.is_committed(), "and the body is not free")


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
