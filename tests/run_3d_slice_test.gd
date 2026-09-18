extends "res://tests/test_case.gd"
## P-02 3D vertical slice through real scenes: Home -> 3D walk, dog camera
## (camera-relative movement, no spin, owner/wall fading, collision), search
## loot, seamless fight + disengage and victory, extraction -> result -> Home.

const TEST_SAVE: String = "user://tests/run_3d_slice_save.json"
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
	var rig := map.rig
	var coordinator := map.coordinator
	coordinator.time_scale = 25.0
	check(run.is_running() and run.dog_actor == dog, "3D walk running with the 3D dog")
	check(rig.is_dog_visible(), "dog view: dog visible at start")
	check(rig.global_position.y - dog.global_position.y < 1.6, "camera starts low behind the dog")
	check(not map.find_child("ViewButton", true, false), "no view switch: dog view only")

	# --- Camera-relative movement ------------------------------------------------
	var start := dog.global_position
	await _hold(&"move_up", 40)
	check(dog.global_position.z < start.z - 0.8, "up walks away from the camera")
	check(human.global_position.distance_to(dog.global_position) < 4.0, "owner follows on the leash")

	dog.global_position = Vector3(0, 0.1, 2.5)
	dog.velocity = Vector3.ZERO
	await _physics(2)
	dog.facing = Vector3.RIGHT
	rig.snap_behind_dog()
	check(is_equal_approx(rig.yaw, dog.heading()), "camera snaps behind the dog")
	start = dog.global_position
	await _hold(&"move_up", 30)
	check(dog.global_position.x > start.x + 0.8, "up walks where the dog was facing")
	check(rig.is_dog_visible(), "dog visible while walking")

	# Push right: the dog sets off right at once, and holding it keeps turning
	# the view that way at a steady rate instead of stalling after one turn.
	dog.global_position = Vector3(-8, 0.1, 0.0)
	dog.velocity = Vector3.ZERO
	dog.facing = Vector3.FORWARD
	rig.snap_behind_dog()
	await _physics(2)
	var start_right := dog.global_position
	Input.action_press(&"move_right")
	await _physics(30)
	check(dog.global_position.x > start_right.x + 0.8, "pushing right sets off to the right")
	var turns: Array[float] = []
	for window in 3:
		var yaw_before := rig.yaw
		await _physics(60)
		turns.append(angle_difference(yaw_before, rig.yaw))
	Input.action_release(&"move_right")
	check(turns[1] < -0.2 and turns[2] < -0.2, "holding a direction keeps turning the view (%.2f then %.2f rad/s)" % [turns[1], turns[2]])
	check(absf(turns[1]) < 1.7 and absf(turns[2]) < 1.7, "a held turn stays a steady arc, not a spin")

	# Up-left: the reported case. It must keep turning left, and more gently
	# than a full sideways push, so a diagonal is a curve and not a pivot.
	dog.global_position = Vector3(-8, 0.1, 6.0)
	dog.velocity = Vector3.ZERO
	dog.facing = Vector3.FORWARD
	rig.snap_behind_dog()
	await _physics(2)
	Input.action_press(&"move_up")
	Input.action_press(&"move_left")
	await _physics(30)
	var diagonal: Array[float] = []
	for window in 2:
		var yaw_before := rig.yaw
		await _physics(60)
		diagonal.append(angle_difference(yaw_before, rig.yaw))
	Input.action_release(&"move_up")
	Input.action_release(&"move_left")
	check(diagonal[0] > 0.2 and diagonal[1] > 0.2, "holding up-left keeps turning left (%.2f then %.2f rad/s)" % [diagonal[0], diagonal[1]])
	check(diagonal[1] < absf(turns[2]), "a diagonal curves more gently than a full sideways push")

	# Released and pushed up again: "up" is wherever the camera now looks.
	dog.velocity = Vector3.ZERO
	await _physics(20)
	var view_forward := Vector3(0, 0, -1).rotated(Vector3.UP, rig.yaw)
	var before_up := dog.global_position
	await _hold(&"move_up", 40)
	var travelled := dog.global_position - before_up
	travelled.y = 0.0
	check(travelled.length() > 1.0 and travelled.normalized().dot(view_forward) > 0.85, "after the view turned, up goes where the camera looks")

	# Turning then walking forward: the camera eases round smoothly (no jumps).
	dog.global_position = Vector3(0, 0.1, 2.5)
	dog.velocity = Vector3.ZERO
	await _physics(20)
	var largest_step := 0.0
	var previous := rig.yaw
	Input.action_press(&"move_up")
	for i in 90:
		await _tree.physics_frame
		largest_step = maxf(largest_step, absf(angle_difference(previous, rig.yaw)))
		previous = rig.yaw
	Input.action_release(&"move_up")
	check(largest_step < 0.08, "camera turns without jumps (max step %.3f rad)" % largest_step)

	# Arrow keys turn the camera by hand, and auto-follow waits.
	rig.yaw = 0.0
	dog.velocity = Vector3.ZERO
	await _physics(10)
	await _hold(&"camera_turn_right", 20)
	check(rig.yaw < -0.3, "arrow key turns the camera")
	var turned := rig.yaw
	await _physics(10)
	check(is_equal_approx(rig.yaw, turned), "camera stays where the player turned it")

	# Owner between camera and dog fades.
	dog.global_position = Vector3(0, 0.1, 2.5)
	dog.velocity = Vector3.ZERO
	dog.facing = Vector3.FORWARD
	human.global_position = dog.global_position + Vector3(0, 0, 1.6)
	rig.snap_behind_dog()
	await _physics(2)
	check(human.faded, "owner blocking the camera fades")

	# A wall behind the dog pulls the camera in but keeps it low.
	dog.global_position = Vector3(-12, 0.1, 3.3)
	human.global_position = dog.global_position + Vector3(1.5, 0, 0)
	rig.snap_behind_dog()
	await _physics(2)
	check(rig.collided and rig.is_dog_visible(), "wall pulls camera in, dog still visible")
	check(rig.global_position.y - dog.global_position.y < 1.6, "camera stays low near walls")
	dog.global_position = Vector3(-12, 0.1, 4.8)
	rig.snap()
	await _physics(2)
	check(not rig.collided and rig._faded.size() > 0 and rig.global_position.y - dog.global_position.y < 1.6, "too close to a wall, the wall fades")

	# --- Search ------------------------------------------------------------------
	var trash := map.get_node("SearchPoints/trash_street_east") as SearchPoint3D
	await _interact_at(dog, human, trash)
	check(trash.is_searching(), "3D search started")
	await _seconds(trash.search_duration + 0.3)
	check(run.is_searched(&"trash_street_east"), "3D search completes through RunManager")

	# --- Fight: disengage, then victory -------------------------------------------
	var pair := map.get_node("Encounters/pair_park") as OpponentPair3D
	coordinator.time_scale = 0.0
	await _interact_at(dog, human, pair)
	check(coordinator.is_fighting() and human.state == HumanFollower3D.State.COMBAT, "provoke starts a fight in place")
	await _physics(2)
	check(rig.is_combat_framing(), "camera reframes for the fight")
	check_eq(rig.context, CameraRig3D.Context.TENSION, "before the first blow it is tension, not action")

	# D4/P02-001: the two jobs come apart — the boom still hangs behind the dog,
	# but the camera is now looking at the owner, not at the dog.
	# The fight is already held still, so the framing can be read without it
	# ending. Put the dog where the feature matters: off to the side, away from
	# its human. (Standing on top of the owner, looking at one is looking at
	# the other.)
	await _physics(2)
	dog.global_position = human.global_position + Vector3(3.0, 0, 1.5)
	dog.velocity = Vector3.ZERO
	await _physics(40)
	var to_owner := human.global_position - rig.global_position
	var to_dog := dog.global_position - rig.global_position
	var aim := -rig.global_basis.z
	check(aim.normalized().dot(to_owner.normalized()) > aim.normalized().dot(to_dog.normalized()), "the camera looks at the owner rather than the dog")
	var cam_to_dog := (dog.global_position + Vector3(0, 0.4, 0)) - rig.camera.global_position
	var cam_aim := -rig.camera.global_basis.z
	check(rig.is_dog_visible(), "and the dog is still on screen")
	check(rig._focus.distance_to(dog.global_position + Vector3(0, rig.current["pivot"], 0)) < 0.6, "the boom still hangs behind the dog")

	# D4/P02-002: soft composition, not a lock-on. The owner's position during a
	# fight belongs to the coordinator, so this reads the composition itself.
	var composed := rig._composed_look(rig._focus)
	var subject_gap := rig._focus.distance_to(human.global_position + Vector3(0, rig.current["pivot"], 0))
	var aim_gap := rig._focus.distance_to(composed)
	check(aim_gap > 0.0, "the aim leaves the dog for the owner")
	check(aim_gap < subject_gap, "but never all the way onto them (no lock-on)")
	# Anything inside the dead-zone is simply ignored, so shuffling never drags
	# the view around.
	var real_dead_zone := rig.focus_dead_zone
	rig.focus_dead_zone = subject_gap + 5.0
	check_eq(rig._composed_look(rig._focus), rig._focus, "movement inside the dead-zone does not move the camera")
	rig.focus_dead_zone = real_dead_zone
	coordinator.time_scale = 25.0

	# Gate 02 feel pass: a landed punch reads as contact, and a heavy one reads
	# heavier than a jab. Presentation only — the simulation still decides.
	check(coordinator._impact_weight(1.0) < coordinator._impact_weight(CombatCoordinator3D.HEAVY_DAMAGE), "a heavy hit weighs more than a jab")
	check_eq(coordinator._impact_weight(CombatCoordinator3D.HEAVY_DAMAGE * 3.0), 1.0, "impact weight is capped")
	rig._trauma = 0.0
	coordinator._punch_landed(1.0)
	check(coordinator._hitstop_left > 0.0, "a hit stops the fight for a beat")
	check(rig._trauma > 0.0, "and shakes the view")
	var heavy_stop := coordinator._hitstop_left
	coordinator._hitstop_left = 0.0
	coordinator._punch_landed(0.0)
	check(coordinator._hitstop_left < heavy_stop, "a light hit stops it for less")
	check(coordinator._hitstop_left <= CombatCoordinator3D.HITSTOP_HEAVY, "the pause is always short")
	# The pause holds the clock; it must never advance the fight by itself.
	coordinator._hitstop_left = CombatCoordinator3D.HITSTOP_HEAVY
	var hp_before: float = coordinator.engagement.simulation.fighters[CombatSimulation.OPPONENT].hp
	var time_before: float = coordinator.engagement.simulation.time
	await _physics(3)
	check_eq(coordinator.engagement.simulation.time, time_before, "the simulation does not advance during the pause")
	check_eq(coordinator.engagement.simulation.fighters[CombatSimulation.OPPONENT].hp, hp_before, "and nobody takes damage from it")
	coordinator._hitstop_left = 0.0
	var dog_before := dog.global_position
	await _hold(&"move_left", 15)
	check(dog.global_position.distance_to(dog_before) > 0.3, "dog stays controllable during the fight")
	dog.global_position = human.global_position + Vector3(0, 0, CombatCoordinator3D.DISENGAGE_DISTANCE + 2.0)
	await _physics(3)
	check_eq(coordinator.last_result, CombatSimulation.Result.DISENGAGED, "running away disengages")
	check(human.is_following(), "owner follows again")
	# D4/P02-006: it is over, but the camera holds the beat before letting go.
	check_eq(rig.context, CameraRig3D.Context.RELEASE, "the camera holds the resolution beat")
	await _wait_until(func() -> bool: return rig.context == CameraRig3D.Context.EXPLORE, 300)
	check(not rig.is_combat_framing(), "and then blends back to walking")
	await _wait_until(func() -> bool: return pair.state == OpponentPair3D.State.IDLE, 600)

	human.fighter = OLD_MASTER
	var gained: Array[int] = [0]
	run.loot_gained.connect(func(_i: ItemData, q: int) -> void: gained[0] += q)
	await _interact_at(dog, human, pair)
	await _wait_until(func() -> bool: return not coordinator.is_fighting(), 900)
	check_eq(coordinator.last_result, CombatSimulation.Result.VICTORY, "3D fight won autonomously")
	check(pair.is_beaten() and gained[0] > 0, "beaten pair, reward in the bag")

	# --- Extraction -> result -> Home ---------------------------------------------
	run.debug_unlock_all_extractions()
	var bus := map.get_node("ExtractionPoints/bus_stop") as ExtractionPoint3D
	check(bus.available, "extraction point unlocks")
	await _interact_at(dog, human, bus)
	await _wait_for_scene(Game.RUN_RESULT_SCENE)
	check(Game.last_run_result != null and Game.last_run_result.is_success(), "extracted from the 3D walk")
	_tree.current_scene.get_node("%HomeButton").pressed.emit()
	await _wait_for_scene(Game.HOME_SCENE)
	check(Game.home_stash.used_slot_count() > 0, "3D loot reached the home stash")

	DirAccess.remove_absolute(TEST_SAVE)
	finish()


# --- helpers ---------------------------------------------------------------

func _interact_at(dog: DogController3D, human: HumanFollower3D, target: Node3D) -> void:
	dog.global_position = target.global_position + Vector3(0.6, 0.2, 0.6)
	dog.velocity = Vector3.ZERO
	human.global_position = dog.global_position + Vector3(1.0, 0, 1.0)
	await _physics(4)
	check(dog.focused == target, "dog focuses %s" % target.name)
	Input.action_press(&"interact")
	await _tree.physics_frame
	Input.action_release(&"interact")
	await _physics(2)


func _hold(action: StringName, frames: int) -> void:
	Input.action_press(action)
	await _physics(frames)
	Input.action_release(action)


func _seconds(seconds: float) -> void:
	await _tree.create_timer(seconds).timeout


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
