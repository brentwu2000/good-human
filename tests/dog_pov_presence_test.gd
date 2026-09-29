extends "res://tests/test_case.gd"
## P04-09: physical presence as the player sees it — from inside the dog's
## head during a live fight. The dog can circle the fight, push in and back
## out; the lens never ends up inside a person; the dog never stands inside
## one; and the view never snaps while bodies move round it (P-04 gate:
## "Dog POV navigable; no body penetration; auto-framing remains stable").

const TEST_SAVE: String = "user://tests/dog_pov_presence_save.json"
const MOVES: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]

var _tree: SceneTree
var map: RunMap3D
var coordinator: CombatCoordinator3D
var dog: DogController3D
var human: HumanFollower3D
var rig: CameraRig3D
var pair: OpponentPair3D

## Measured over the whole run.
var closest_lens := INF
var longest_overlap := 0
var overlap_run := 0
var sharpest_turn := 0.0
var travelled := 0.0
var angle_round := 0.0
var pov_frames := 0
var frames := 0


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
	map = _tree.current_scene as RunMap3D
	coordinator = map.coordinator
	dog = map.dog
	human = map.human
	rig = map.rig
	pair = map.get_node("Encounters/pair_park") as OpponentPair3D

	# Provoke, then let the fight proper start so the camera is in the dog's eyes.
	human.global_position = pair.global_position + Vector3(0, 0.1, 1.6)
	dog.global_position = pair.global_position + Vector3(0.9, 0.1, 1.2)
	await _physics(3)
	Input.action_press(&"interact")
	await _tree.physics_frame
	Input.action_release(&"interact")
	await _physics(2)
	check(coordinator.is_fighting(), "a fight to be inside")
	# Slow enough that it is still going when the dog has done its rounds.
	coordinator.time_scale = 0.35
	coordinator.blows_landed = 1
	await _wait_until(func() -> bool: return rig.pov > 0.9, 180)
	check(rig.pov > 0.9, "the camera is in the dog's eyes (pov %.2f)" % rig.pov)

	# Round the fight one way, straight in, back out, round the other way.
	await _drive(func() -> Vector3: return _around(1.0), 150)
	await _drive(func() -> Vector3: return _towards_fight(), 60)
	await _drive(func() -> Vector3: return -_towards_fight(), 50)
	await _drive(func() -> Vector3: return _around(-1.0), 150)

	check(pov_frames > frames * 0.8, "the dog's-eye view held for the fight (%d of %d frames)" % [pov_frames, frames])
	check(travelled > 3.0, "the dog moves freely in its own view (%.1f m)" % travelled)
	check(angle_round > 1.5, "and can circle the fight (%.2f rad round it)" % angle_round)
	var drawn := DataRegistry.presence.human_radius
	check(closest_lens > drawn, "the lens never enters a person (closest %.2f m, drawn body %.2f m)" % [closest_lens, drawn])
	check(longest_overlap <= 3, "the dog never stays inside a person (longest %d frames)" % longest_overlap)
	check(sharpest_turn < 0.12, "the view never snaps as bodies move round it (sharpest %.3f rad in a frame)" % sharpest_turn)

	await _test_stationary_dog()

	coordinator.debug_force_result(CombatSimulation.Result.DISENGAGED)
	coordinator.time_scale = 1.0
	await _physics(3)
	finish()


## P03-E12 (found in the captures): a dog standing still right beside the
## fight. Fighters used to circle straight onto it and bury its eyes in their
## clothing; they now keep clear of it (P-04: adjust path round the dog), and
## anyone at the lens is faded.
func _test_stationary_dog() -> void:
	if not coordinator.is_fighting():
		return
	var centre := _fight_centre()
	var line := _flat(pair.human_global_position() - human.global_position).normalized()
	# Right up against the fight, as a player standing by it would be.
	dog.global_position = centre + line.cross(Vector3.UP) * 0.7 + Vector3(0, 0.1, 0)
	dog.velocity = Vector3.ZERO
	coordinator.time_scale = 1.0
	var closest := INF
	var pressed := 0
	var watched := 0
	var ignored := 0
	var unfaded_at_lens := 0
	for i in 360:
		await _tree.physics_frame
		if not coordinator.is_fighting():
			break
		watched += 1
		# Kept from closing too long, the fighters stop walking round the dog
		# and shove it aside (so it can never jam the fight): not counted here.
		var dog_counts := coordinator._dog_counts()
		if not dog_counts:
			ignored += 1
		var lens := rig.camera.global_position
		for body: Node3D in [human.puppet, pair.human_puppet]:
			var gap := _flat(dog.global_position - body.global_position).length()
			closest = minf(closest, gap)
			if gap < 0.6 and dog_counts:
				pressed += 1
			if _flat(lens - body.global_position).length() < rig.near_fade_distance and not rig._near_faded.has(body):
				unfaded_at_lens += 1
	coordinator.time_scale = 0.35
	check(watched > 60, "the fight went on around a dog standing still (%d frames)" % watched)
	check(pressed <= watched * 0.05, "fighters keep clear of a dog standing beside them (%d of %d frames pressed onto it, closest %.2f m)" % [pressed, watched, closest])
	check(ignored <= watched * 0.5, "and only push past it when it keeps them from each other (%d of %d frames)" % [ignored, watched])
	# The fade follows the fighters' move by a frame at most.
	check(unfaded_at_lens <= 3, "nobody right at the lens is drawn solid for more than a frame or two (%d)" % unfaded_at_lens)


## Steers the dog along `direction.call()` through the real Input Map, read
## against the view it has (first person), and measures as it goes.
func _drive(direction: Callable, count: int) -> void:
	var last_forward := -rig.camera.global_basis.z
	var last_dog := dog.global_position
	var last_bearing := _bearing()
	for i in count:
		if not coordinator.is_fighting():
			break
		var world: Vector3 = direction.call()
		var local := world.rotated(Vector3.UP, -dog.camera_yaw)
		_hold(&"move_right", local.x)
		_hold(&"move_left", -local.x)
		_hold(&"move_down", local.z)
		_hold(&"move_up", -local.z)
		await _tree.physics_frame
		frames += 1
		if rig.pov > 0.9:
			pov_frames += 1
		var lens := rig.camera.global_position
		var inside := false
		for body: Node3D in [human, pair.human_puppet]:
			closest_lens = minf(closest_lens, _flat(lens - body.global_position).length())
			if _flat(dog.global_position - body.global_position).length() < 0.4:
				inside = true
		overlap_run = overlap_run + 1 if inside else 0
		longest_overlap = maxi(longest_overlap, overlap_run)
		var forward := -rig.camera.global_basis.z
		sharpest_turn = maxf(sharpest_turn, last_forward.angle_to(forward))
		last_forward = forward
		travelled += _flat(dog.global_position - last_dog).length()
		last_dog = dog.global_position
		var bearing := _bearing()
		angle_round += absf(angle_difference(last_bearing, bearing))
		last_bearing = bearing
	for action in MOVES:
		Input.action_release(action)


func _fight_centre() -> Vector3:
	return (human.global_position + pair.human_global_position()) * 0.5


## Tangent round the fight, `sense` +1 or -1, a little inwards to keep close.
func _around(sense: float) -> Vector3:
	var out := _flat(dog.global_position - _fight_centre())
	if out.length() < 0.01:
		out = Vector3.RIGHT
	var tangent := out.normalized().cross(Vector3.UP) * sense
	var keep := (1.6 - out.length()) * 0.6
	return (tangent + out.normalized() * keep).normalized()


func _towards_fight() -> Vector3:
	var inward := _flat(_fight_centre() - dog.global_position)
	return inward.normalized() if inward.length() > 0.01 else Vector3.FORWARD


func _bearing() -> float:
	var out := _flat(dog.global_position - _fight_centre())
	return atan2(out.x, out.z)


func _hold(action: StringName, value: float) -> void:
	if value > 0.01:
		Input.action_press(action, clampf(value, 0.0, 1.0))
	else:
		Input.action_release(action)


func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


func _wait_until(done: Callable, max_frames: int) -> void:
	for i in max_frames:
		if done.call():
			return
		await _tree.physics_frame


func _physics(count: int) -> void:
	for i in count:
		await _tree.physics_frame


func _wait_for_scene(path: String) -> void:
	for i in 300:
		await _tree.process_frame
		if _tree.current_scene != null and _tree.current_scene.scene_file_path == path:
			await _tree.process_frame
			return
	check(false, "timed out waiting for scene %s" % path)
