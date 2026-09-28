extends "res://tests/test_case.gd"
## P04-01 (ADR-016) in the real 3D walk: the dog cannot pass through the
## owner, an opponent human or an opponent dog, in or out of a fight; it slides
## round a body it only clips; running into someone is answered with a small
## balance reaction and never with a fight or damage; and a dog put inside a
## body is pushed back out.

const TEST_SAVE: String = "user://tests/physical_presence_save.json"
const MOVES: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]
## Closer than this (m, centre to centre on the ground) the dog is inside the
## other body. Real contact sits well above it: the dog's side is 0.25 m from
## its centre and a person is 0.24 m wide at the waist.
const PENETRATION: float = 0.4

var _tree: SceneTree
var map: RunMap3D
var coordinator: CombatCoordinator3D
var dog: DogController3D
var human: HumanFollower3D


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

	var pair := map.get_node("Encounters/pair_park") as OpponentPair3D
	check(pair.encounter != null, "the park pair is out this walk")
	var them := pair.human_puppet
	var their_dog := pair._dog
	check(them.get_node_or_null("Presence") is PhysicalPresence3D, "opponent human has a body")
	check(their_dog.get_node_or_null("Presence") is PhysicalPresence3D, "opponent dog has a body")
	# Approach across the line from their human to their dog, so the dog is
	# never in the way of a pass, and clip the human on the side away from it.
	var to_their_dog := _flat(their_dog.global_position - them.global_position).normalized()
	var side := to_their_dog.cross(Vector3.UP)
	var offset := -to_their_dog * 0.3
	_park_owner(pair.global_position - side * 6.0 + Vector3(0, 0, 4.0))

	# --- Walking straight into an opponent human: stopped at their body -------------
	var at := them.global_position
	var closest := await _steer_from(at - side * 2.5, side, 0.6, 100, them)
	check(closest >= PENETRATION, "walking into an opponent does not enter them (closest %.2f m)" % closest)
	check(_along(dog.global_position - at, side) < 0.0, "and does not come out the other side")
	check(not coordinator.is_fighting(), "running into someone does not start a fight")

	# --- Clipping them off-centre: the dog slides round and carries on --------------
	closest = await _steer_from(at - side * 2.5 + offset, side, 0.6, 150, them)
	check(closest >= PENETRATION, "a glancing pass stays outside them (closest %.2f m)" % closest)
	check(_along(dog.global_position - at, side) > 0.5, "and the dog slides round to the far side")

	# --- Their dog: blocked too ------------------------------------------------------
	var dog_at := their_dog.global_position
	var toward_dog := dog_at - at
	toward_dog.y = 0.0
	toward_dog = toward_dog.normalized()
	closest = await _steer_from(dog_at + toward_dog * 2.5, -toward_dog, 0.6, 100, their_dog)
	check(closest >= PENETRATION - 0.1, "walking into their dog does not enter it (closest %.2f m)" % closest)

	# --- A fast bump is felt, a slow one is not ----------------------------------------
	var bumps: Array[Vector3] = []
	var on_bump := func(from: Vector3) -> void: bumps.append(from)
	them.bumped.connect(on_bump)
	await _steer_from(at - side * 2.5 + offset * 0.2, side, 0.6, 90, them)
	check(bumps.is_empty(), "walking into someone is only a block")
	await _wait_seconds(0.8)
	await _steer_from(at - side * 3.5, side, 1.0, 70, them)
	check(bumps.size() == 1, "sprinting into someone makes them give a little (%d)" % bumps.size())
	check(not coordinator.is_fighting(), "and still no fight")
	them.bumped.disconnect(on_bump)

	# --- The owner --------------------------------------------------------------------
	var home := pair.global_position - side * 6.0 + Vector3(0, 0, 4.0)
	_park_owner(home)
	await _physics(3)
	var owner_at := human.global_position
	var owner_bumps: Array[Vector3] = []
	human.puppet.bumped.connect(func(from: Vector3) -> void: owner_bumps.append(from))
	closest = await _steer_from(owner_at + Vector3(2.5, 0, 0), Vector3.LEFT, 0.6, 100, human)
	check(closest >= PENETRATION, "the dog cannot walk through its own owner (closest %.2f m)" % closest)
	check(owner_bumps.is_empty(), "a slow nudge is not a bump")
	await _wait_seconds(0.8)
	_park_owner(owner_at)
	await _steer_from(owner_at + Vector3(3.5, 0, 0), Vector3.LEFT, 1.0, 70, human)
	check(owner_bumps.size() == 1, "running into the owner is felt (%d)" % owner_bumps.size())
	check(human.is_following(), "and the owner carries on walking")

	# --- In a fight: the fighters are still bodies ----------------------------------
	human.hold_time = 0.0
	human.global_position = at + side * -1.6 + Vector3(0, 0.1, 0)
	dog.global_position = at + side * -1.0 + offset * 2.0 + Vector3(0, 0.1, 0)
	await _physics(3)
	Input.action_press(&"interact")
	await _tree.physics_frame
	Input.action_release(&"interact")
	await _physics(2)
	check(coordinator.is_fighting(), "fight started")
	coordinator.time_scale = 0.0
	var sim := coordinator.engagement.simulation
	var hp_before := [sim.fighters[0].hp, sim.fighters[1].hp]
	var fighter_at := them.global_position
	var line := fighter_at - human.global_position
	line.y = 0.0
	var across := line.normalized().cross(Vector3.UP)
	closest = await _steer_from(fighter_at + across * 2.5, -across, 0.6, 100, them)
	check(closest >= PENETRATION, "the dog cannot walk through a fighter (closest %.2f m)" % closest)
	closest = await _steer_from(human.global_position - across * 2.5, across, 0.6, 100, human)
	check(closest >= PENETRATION, "nor through its own owner mid-fight (closest %.2f m)" % closest)
	check(hp_before == [sim.fighters[0].hp, sim.fighters[1].hp], "contact never deals damage")

	# --- P04-02: the fight moves on the ground, and the fighters never overlap -------
	# How much a fight turns is the simulation's business (combat_spacing_test);
	# here the ground has to follow it: the right distance, the line pointing
	# where the simulation says, and never two bodies overlapping.
	var fighters_closest := INF
	var mismatch := 0.0
	var off_line := 0.0
	coordinator.time_scale = 1.5
	for i in 240:
		await _tree.physics_frame
		if not coordinator.is_fighting():
			break
		var gap := _flat(them.global_position - human.global_position)
		fighters_closest = minf(fighters_closest, gap.length())
		mismatch = maxf(mismatch, absf(gap.length() - sim.distance() / CombatCoordinator3D.UNITS_PER_METER))
		var expected := coordinator._axis * cos(sim.line_angle) + coordinator._side_axis * sin(sim.line_angle)
		off_line = maxf(off_line, absf(expected.signed_angle_to(gap.normalized(), Vector3.UP)))
	coordinator.time_scale = 0.0
	var bodies := 2.0 * DataRegistry.presence.human_radius
	check(fighters_closest >= bodies, "two fighters never stand inside each other (closest %.2f m, bodies %.2f m)" % [fighters_closest, bodies])
	check(mismatch < 0.02, "on the ground they are as far apart as the fight says (off by %.3f m)" % mismatch)
	check(off_line < 0.02, "and the line between them points where the fight says (off by %.3f rad)" % off_line)
	fighter_at = them.global_position
	line = _flat(fighter_at - human.global_position)
	across = line.normalized().cross(Vector3.UP)

	# --- Put inside a body, the dog is pushed back out ----------------------------------
	# A fighter stepping onto part of the dog, not the dog dropped dead centre.
	var inside := fighter_at + across * 0.15
	dog.global_position = Vector3(inside.x, dog.global_position.y, inside.z)
	dog.velocity = Vector3.ZERO
	await _physics(10)
	var gap := _flat(dog.global_position - them.global_position).length()
	check(gap >= PENETRATION, "a dog left inside a fighter comes back out (%.2f m)" % gap)

	# P04-08: even dead centre, where physics has no direction to push.
	var centre := them.global_position
	dog.global_position = Vector3(centre.x, dog.global_position.y, centre.z)
	dog.velocity = Vector3.ZERO
	# It steps out of the deep part itself; physics finishes the separation.
	await _physics(45)
	gap = _flat(dog.global_position - them.global_position).length()
	check(gap >= PENETRATION, "a dog left dead centre inside a fighter steps out (%.2f m)" % gap)

	# P04-08: the fight knows where fighters cannot stand.
	check(sim.walkable.is_valid(), "the fight asks the Run World where people can stand")
	var clear := Vector2.ZERO
	var found := false
	for ground: Vector2 in [Vector2(0, 300), Vector2(0, -300), Vector2(300, 0), Vector2(-300, 0)]:
		if coordinator._walkable(ground):
			clear = ground
			found = true
			break
	check(found, "somewhere near the fight is open ground")
	var wall := StaticBody3D.new()
	wall.collision_layer = Greybox.WORLD_LAYER
	var box := CollisionShape3D.new()
	box.shape = BoxShape3D.new()
	(box.shape as BoxShape3D).size = Vector3(1.0, 2.0, 1.0)
	box.position.y = 1.0
	wall.add_child(box)
	map.add_child(wall)
	wall.global_position = coordinator._ground_to_world(clear)
	await _physics(2)
	check(not coordinator._walkable(clear), "and a wall there is somewhere they cannot")
	wall.queue_free()

	coordinator.debug_force_result(CombatSimulation.Result.DISENGAGED)
	coordinator.time_scale = 1.0
	await _physics(3)
	finish()


## Drives the dog from `start` along `direction` through the real Input Map at
## `strength` (1.0 sprints) for `frames`, and returns how close it got to
## `target` on the ground.
func _steer_from(start: Vector3, direction: Vector3, strength: float, frames: int, target: Node3D) -> float:
	dog.global_position = Vector3(start.x, dog.global_position.y, start.z)
	dog.velocity = Vector3.ZERO
	await _physics(2)
	var closest := INF
	for i in frames:
		# Input is camera-relative, and the chase camera turns with the dog.
		var local := direction.rotated(Vector3.UP, -dog.camera_yaw)
		_hold(&"move_right", local.x * strength)
		_hold(&"move_left", -local.x * strength)
		_hold(&"move_down", local.z * strength)
		_hold(&"move_up", -local.z * strength)
		await _tree.physics_frame
		closest = minf(closest, _flat(dog.global_position - target.global_position).length())
	for action in MOVES:
		Input.action_release(action)
	await _physics(10)
	return closest


func _hold(action: StringName, value: float) -> void:
	if value > 0.01:
		Input.action_press(action, clampf(value, 0.0, 1.0))
	else:
		Input.action_release(action)


## Stands the owner still somewhere out of the way.
func _park_owner(at: Vector3) -> void:
	human.global_position = Vector3(at.x, human.global_position.y, at.z)
	human.velocity = Vector3.ZERO
	human.hold_time = 60.0


func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


func _along(v: Vector3, direction: Vector3) -> float:
	return _flat(v).dot(direction)


func _wait_seconds(seconds: float) -> void:
	await _physics(int(seconds * 60))


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
