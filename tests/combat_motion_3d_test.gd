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

	await _test_dog_pov(map, coordinator, dog, human, pair)
	finish()


## P03-E04/E05/E06: the Combat Snap drops the camera into the dog's eyes, tracks
## the fight from there, and comes back out afterwards (ADR-015).
func _test_dog_pov(map: RunMap3D, coordinator: CombatCoordinator3D, dog: DogController3D, human: HumanFollower3D, pair: OpponentPair3D) -> void:
	var rig := map.rig
	if not coordinator.is_fighting():
		dog.global_position = pair.global_position + Vector3(1.0, 0.1, 1.0)
		await _physics(6)
		pair.interact(map.run_manager)
		await _physics(6)
	check(coordinator.is_fighting(), "a fight to watch")
	coordinator.time_scale = 0.0

	# Before the first blow the camera is still the chase shot.
	coordinator.blows_landed = 0
	await _physics(60)
	check_eq(rig.context, CameraRig3D.Context.TENSION, "tension first")
	check(rig.pov < 0.2, "the dog is still on screen while the fight builds (pov %.2f)" % rig.pov)
	var chase_position := rig.global_position

	# The snap: blows land, and the camera moves into the dog's head.
	coordinator.blows_landed = 1
	await _physics(90)
	check_eq(rig.context, CameraRig3D.Context.ACTIVE, "blows landing means the fight proper")
	check(rig.pov > 0.9, "the camera is looking through the dog's eyes (pov %.2f)" % rig.pov)
	check(rig.global_position.distance_to(dog.eye_position()) < 0.25, "and it sits at the dog's eye, not behind it")
	check(rig.global_position.distance_to(chase_position) > 0.5, "which is somewhere else entirely from the chase shot")
	check(not dog._visual.visible, "the dog's own body is not filling the lens")

	# It watches the fight, biased towards the owner, without being told to.
	var centre := rig.combat_center()
	var owner_head := human.global_position + Vector3(0, 1.1, 0)
	var opponent_head := pair.human_global_position() + Vector3(0, 1.1, 0)
	# The point the camera watches is at the height of the people fighting, not
	# floating above their heads.
	check(absf(centre.y - owner_head.y) < 0.3, "the fight is watched at head height (%.2f vs %.2f)" % [centre.y, owner_head.y])
	check(centre.distance_to(owner_head) < centre.distance_to(opponent_head), "the fight is watched from the owner's side")
	var aim := -rig.global_basis.z
	check(aim.dot((centre - rig.global_position).normalized()) > 0.9, "the camera is pointed at the fight")

	# Pushing forward must go where the player is looking. In first person the
	# boom is behind their eyes and means nothing; reading the stick against it
	# sends the dog somewhere else and the player backs away without meaning to.
	var view := rig.view_yaw()
	var screen_forward := Vector3.FORWARD.rotated(Vector3.UP, view)
	check(absf(angle_difference(view, rig.yaw)) > 0.15, "in first person the view has left the boom behind")
	var to_fight := rig.combat_center() - dog.global_position
	to_fight.y = 0.0
	check(screen_forward.dot(to_fight.normalized()) > 0.6, "and the view is pointed at the fight")
	var before := dog.global_position
	Input.action_press(&"move_up")
	for i in 30:
		await _tree.physics_frame
	Input.action_release(&"move_up")
	var travelled := dog.global_position - before
	travelled.y = 0.0
	check(travelled.length() > 0.2, "the dog actually moves")
	check(travelled.normalized().dot(screen_forward) > 0.7, "pushing forward walks into the screen, not away from it")
	dog.global_position = before
	dog.velocity = Vector3.ZERO
	await _physics(4)

	# The snap is a blend, not a cut: it never jumps.
	coordinator.blows_landed = 0
	var largest := 0.0
	var previous := rig.global_position
	for i in 90:
		await _tree.physics_frame
		largest = maxf(largest, rig.global_position.distance_to(previous))
		previous = rig.global_position
	check(largest < 0.3, "coming back out is a blend, not a cut (largest step %.3f m)" % largest)
	check(rig.pov < 0.2, "and the camera is back behind the dog")
	check(dog._visual.visible, "which means the dog can be seen again")
	coordinator.time_scale = 25.0


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
