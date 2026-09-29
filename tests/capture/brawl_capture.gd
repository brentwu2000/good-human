extends Node
## P03-E12: implementation captures for QA and ART review (P03-D10, D4-17,
## P04 capture requests). Plays one scripted case in the real 3D walk under
## normal presentation (no debug, no fight text) and quits, so Godot's Movie
## Maker can record it:
##
##   godot --path <project> --write-movie build/captures/<case>.avi \
##         --fixed-fps 30 --resolution 405x720 \
##         res://tests/capture/brawl_capture.tscn -- <case>
##
## `tests/capture/record.sh` records every case. Cases: snap, orbit_cw,
## orbit_ccw, behind_bark, leash_pull, critical, win, loss, p02_snap, banyan
## (the dog walking up to the Big Banyan, no fight).
## This is a recording tool, not a test: it asserts nothing.

const CASES: Array[String] = ["snap", "orbit_cw", "orbit_ccw", "behind_bark", "leash_pull", "critical", "win", "loss", "p02_snap", "banyan", "inspect"]
const MOVES: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]

var _tree: SceneTree
var map: RunMap3D
var coordinator: CombatCoordinator3D
var dog: DogController3D
var human: HumanFollower3D
var pair: OpponentPair3D


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_tree = get_tree()
	var args := OS.get_cmdline_user_args()
	var case_name: String = args[0] if not args.is_empty() else "snap"
	if not CASES.has(case_name):
		push_error("brawl_capture: unknown case %s (%s)" % [case_name, ", ".join(CASES)])
		_tree.quit(1)
		return
	SaveManager.save_path = "user://captures/capture_save.json"
	DirAccess.make_dir_recursive_absolute("user://captures")
	if FileAccess.file_exists(SaveManager.save_path):
		DirAccess.remove_absolute(SaveManager.save_path)
	FighterPuppet3D.show_combat_text = false
	CameraRig3D.combat_pov = case_name != "p02_snap"
	var placeholder := Node.new()
	_tree.root.add_child(placeholder)
	_tree.current_scene = placeholder
	_tree.change_scene_to_file(Game.BOOT_SCENE)
	await _wait_for_scene(Game.HOME_SCENE)
	_tree.current_scene.get_node("%Walk3DButton").pressed.emit()
	await _wait_for_scene(Game.RUN_MAP_3D_SCENE)
	map = _tree.current_scene as RunMap3D
	coordinator = map.coordinator
	dog = map.dog
	human = map.human
	pair = map.get_node("Encounters/pair_park") as OpponentPair3D
	await _seconds(0.5)
	if case_name == "banyan":
		await _walk_to_banyan()
		_tree.quit()
		return
	if case_name == "inspect":
		await _inspect()
		_tree.quit()
		return

	# Every case starts the same way: walking up to the pair from a few metres
	# out and provoking them, so the Snap is always in the recording.
	var start := pair.global_position + Vector3(0, 0.1, 5.0)
	dog.global_position = start
	human.global_position = start + Vector3(0.7, 0, 1.2)
	map.rig.snap_behind_dog()
	await _seconds(0.6)
	await _drive_to(pair.global_position + Vector3(0.6, 0, 1.1), 0.6, 4.0)
	await _press(&"interact")

	match case_name:
		"snap", "p02_snap":
			await _seconds(10.0)
		"orbit_cw":
			await _seconds(2.5)
			await _drive(func() -> Vector3: return _around(1.0), 10.0, 0.7)
		"orbit_ccw":
			await _seconds(2.5)
			await _drive(func() -> Vector3: return _around(-1.0), 10.0, 0.7)
		"behind_bark":
			await _seconds(2.5)
			await _drive(func() -> Vector3: return _towards(_behind_opponent()), 4.0, 0.7, func() -> bool: return _flat(dog.global_position - _behind_opponent()).length() < 0.4)
			await _face(pair.human_global_position())
			await _press(&"bark")
			await _seconds(4.0)
		"leash_pull":
			await _seconds(2.0)
			for i in 2:
				await _wait_until(func() -> bool: return coordinator.is_fighting() and coordinator.engagement.simulation.fighters[CombatSimulation.OPPONENT].is_winding_up_attack(), 8.0)
				await _drive(func() -> Vector3: return _away_from_fight(), 0.8, 1.0)
				await _seconds(2.5)
		"critical":
			await _seconds(2.5)
			coordinator.debug_set_owner_condition(0.25)
			await _seconds(8.0)
		"win":
			await _seconds(4.0)
			coordinator.debug_force_result(CombatSimulation.Result.VICTORY)
			await _seconds(5.0)
		"loss":
			await _seconds(4.0)
			coordinator.debug_force_result(CombatSimulation.Result.DEFEAT)
			await _drive(func() -> Vector3: return _towards(human.global_position), 1.2, 0.5)
			await _seconds(1.5)
	_release_moves()
	_tree.quit()


## A fixed side view for checking bodies: the owner walking beside the dog,
## then a fight, both seen square-on from 3.5 m.
func _inspect() -> void:
	var at := pair.global_position + Vector3(0, 0.1, 4.0)
	dog.global_position = at + Vector3(-3.0, 0, 0)
	human.global_position = at + Vector3(-3.7, 0, 0.6)
	var side := Camera3D.new()
	map.add_child(side)
	side.global_position = at + Vector3(0, 1.1, 4.0)
	side.look_at(at + Vector3(0, 0.9, 0), Vector3.UP)
	side.fov = 55.0
	side.make_current()
	await _drive(func() -> Vector3: return Vector3.RIGHT, 2.5, 0.55)
	await _seconds(1.0)
	side.global_position = pair.global_position + Vector3(3.2, 1.2, 1.4)
	side.look_at(pair.global_position + Vector3(0, 0.9, 1.0), Vector3.UP)
	dog.global_position = pair.global_position + Vector3(0.6, 0.1, 1.1)
	human.global_position = pair.global_position + Vector3(0, 0.1, 1.6)
	await _seconds(0.3)
	await _press(&"interact")
	await _seconds(9.0)


func _walk_to_banyan() -> void:
	var tree := map.get_node("BanyanTerritory") as Node3D
	var start := tree.global_position + Vector3(0, 0.1, 7.0)
	dog.global_position = start
	human.global_position = start + Vector3(0.7, 0, 1.2)
	map.rig.snap_behind_dog()
	await _seconds(0.6)
	await _drive_to(tree.global_position + Vector3(0.4, 0, 2.2), 0.5, 7.0)
	await _seconds(2.0)


## Steers the dog along `direction.call()` for `seconds` through the real
## Input Map, read against the view it has. `done` can end it early.
func _drive(direction: Callable, seconds: float, strength: float, done: Callable = Callable()) -> void:
	var frames := int(seconds * Engine.physics_ticks_per_second)
	for i in frames:
		if done.is_valid() and done.call():
			break
		var world: Vector3 = direction.call()
		var local := world.rotated(Vector3.UP, -dog.camera_yaw)
		_hold(&"move_right", local.x * strength)
		_hold(&"move_left", -local.x * strength)
		_hold(&"move_down", local.z * strength)
		_hold(&"move_up", -local.z * strength)
		await _tree.physics_frame
	_release_moves()


func _drive_to(target: Vector3, strength: float, max_seconds: float) -> void:
	await _drive(func() -> Vector3: return _towards(target), max_seconds, strength, func() -> bool: return _flat(dog.global_position - target).length() < 0.25)


## Turns the dog on the spot to face `point` with a light touch of the stick.
func _face(point: Vector3) -> void:
	await _drive(func() -> Vector3: return _towards(point), 0.15, 0.3)


func _fight_centre() -> Vector3:
	return (human.global_position + pair.human_global_position()) * 0.5


func _around(sense: float) -> Vector3:
	var out := _flat(dog.global_position - _fight_centre())
	if out.length() < 0.01:
		out = Vector3.RIGHT
	var tangent := out.normalized().cross(Vector3.UP) * sense
	return (tangent + out.normalized() * (1.8 - out.length()) * 0.6).normalized()


func _behind_opponent() -> Vector3:
	var from_owner := _flat(pair.human_global_position() - human.global_position).normalized()
	return pair.human_global_position() + from_owner * 1.3


func _away_from_fight() -> Vector3:
	var away := _flat(human.global_position - pair.human_global_position()).normalized()
	return (away + away.cross(Vector3.UP) * 0.3).normalized()


func _towards(point: Vector3) -> Vector3:
	var d := _flat(point - dog.global_position)
	return d.normalized() if d.length() > 0.01 else Vector3.ZERO


func _press(action: StringName) -> void:
	Input.action_press(action)
	await _tree.physics_frame
	Input.action_release(action)
	await _tree.physics_frame


func _hold(action: StringName, value: float) -> void:
	if value > 0.01:
		Input.action_press(action, clampf(value, 0.0, 1.0))
	else:
		Input.action_release(action)


func _release_moves() -> void:
	for action in MOVES:
		Input.action_release(action)


func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


func _seconds(value: float) -> void:
	for i in int(value * Engine.physics_ticks_per_second):
		await _tree.physics_frame


func _wait_until(done: Callable, max_seconds: float) -> void:
	for i in int(max_seconds * Engine.physics_ticks_per_second):
		if done.call():
			return
		await _tree.physics_frame


func _wait_for_scene(path: String) -> void:
	for i in 600:
		await _tree.process_frame
		if _tree.current_scene != null and _tree.current_scene.scene_file_path == path:
			await _tree.process_frame
			return
