extends "res://tests/test_case.gd"
## Sprint 04 in the real 3D walk: bark outside and inside a fight (useful side,
## own side, facing away, resistance), leash pulls (save, stumble, drag out),
## searching during a fight, opponent dog reactions, training moments, debug.

const TEST_SAVE: String = "user://tests/dog_agency_3d_save.json"

var _tree: SceneTree
var map: RunMap3D
var agency: DogAgency
var coordinator: CombatCoordinator3D
var dog: DogController3D
var human: HumanFollower3D
var run: RunManager


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
	agency = map.get_node("DogAgency") as DogAgency
	coordinator = map.coordinator
	dog = map.dog
	human = map.human
	run = map.run_manager
	check(map.find_child("BarkButton", true, false) is TouchActionButton, "bark button for touch")

	var pair := map.get_node("Encounters/pair_park") as OpponentPair3D

	# --- Bark outside a fight ---------------------------------------------------------
	await _place(pair.global_position + Vector3(0, 0.1, 3.0), pair.global_position)
	await _press(&"bark")
	check_eq(agency.last_bark, DogAgency.BarkResult.SOCIAL, "bark near a pair: their dog answers")
	check((pair._dog_label.text as String).contains("汪"), "opponent dog barks back")

	# --- Provoke; freeze the fight so positions are controlled ------------------------
	await _wait_seconds(0.7)
	human.global_position = pair.global_position + Vector3(0, 0.1, 1.6)
	dog.global_position = pair.global_position + Vector3(0.5, 0.1, 1.0)
	await _physics(3)
	await _press(&"interact")
	check(coordinator.is_fighting(), "fight started")
	coordinator.time_scale = 0.0
	var sim := coordinator.engagement.simulation
	var opponent_pos := pair.human_global_position()
	var owner_pos := human.global_position
	var side := (owner_pos - opponent_pos).cross(Vector3.UP).normalized()

	# Useful side, facing the opponent: distracted.
	await _place(opponent_pos + side * 2.0, opponent_pos)
	await _press(&"bark")
	check_eq(agency.last_bark, DogAgency.BarkResult.DISTRACTED, "bark from the flank distracts the opponent")
	check(sim.fighters[CombatSimulation.OPPONENT].distracted_until > sim.time, "opponent looks away")
	check(_count(&"agency_bark_distract") == 1, "COURAGE: barking beside a fight")
	var looked_away := sim.fighters[CombatSimulation.OPPONENT].distracted_until - sim.time

	# Resistance: quick repeats lose effect, then get ignored.
	await _wait_seconds(0.7)
	sim.fighters[CombatSimulation.OPPONENT].distracted_until = -1.0
	await _press(&"bark")
	check(agency.last_bark == DogAgency.BarkResult.DISTRACTED and sim.fighters[CombatSimulation.OPPONENT].distracted_until - sim.time < looked_away, "second bark works less")
	await _wait_seconds(0.7)
	await _press(&"bark")
	check_eq(agency.last_bark, DogAgency.BarkResult.IGNORED, "spamming barks gets ignored")

	# From behind your own human: startles the owner.
	agency.recent_barks.clear()
	await _wait_seconds(0.7)
	await _place(owner_pos + (owner_pos - opponent_pos).normalized() * 1.2, opponent_pos)
	await _press(&"bark")
	check_eq(agency.last_bark, DogAgency.BarkResult.STARTLED_OWNER, "barking from behind startles the owner")
	check(sim.fighters[CombatSimulation.PLAYER].distracted_until > sim.time, "owner loses a moment")

	# Facing away: unheard.
	await _wait_seconds(0.7)
	dog.global_position = opponent_pos + side * 2.0
	dog.facing = side
	await _press(&"bark")
	check_eq(agency.last_bark, DogAgency.BarkResult.UNHEARD, "barking the wrong way does nothing")

	# --- Leash: good pull out of an incoming kick -----------------------------------------
	var them := sim.fighters[CombatSimulation.OPPONENT]
	them.distracted_until = -1.0
	them.action = preload("res://data/combat/skills/skill_kick.tres")
	them.phase = CombatFighter.Phase.WINDUP
	them.phase_time_left = 5.0
	var away := (human.global_position - opponent_pos)
	away.y = 0.0
	away = away.normalized()
	var owner_before := human.global_position
	await _pull(away, human.max_length + 0.6, 3)
	check_eq(agency.last_pull, &"saved", "pulling away during a kick saves the owner")
	check(sim.fighters[CombatSimulation.PLAYER].pulled_until > sim.time, "owner out of the kick's way")
	coordinator.time_scale = 0.0
	await _physics(2)
	check(human.global_position.distance_to(opponent_pos) > owner_before.distance_to(opponent_pos), "owner moved away from the opponent")
	check_eq(_count(&"agency_pull_save"), 1, "STRAIN: pulled out of a punch")

	# Pulling again right away in a good direction is not punished.
	them.phase = CombatFighter.Phase.IDLE
	them.action = null
	await _wait_seconds(1.1)
	await _pull(side, human.max_length + 0.6, 3)
	check_eq(agency.last_pull, &"repositioned", "sideways pull just repositions")
	check_eq(_count(&"agency_bad_pull"), 0, "no stumble for sideways pulls")

	# Bad pull: dragging the owner towards the opponent.
	await _wait_seconds(1.1)
	var towards := pair.human_global_position() - human.global_position
	towards.y = 0.0
	await _pull(towards.normalized(), human.max_length + 0.6, 3)
	check_eq(agency.last_pull, &"stumbled", "pulling the owner into the opponent makes them stumble")
	check_eq(_count(&"agency_bad_pull"), 1, "ENDURE: stumbling from your own dog")

	# Drag out: long hard pull away ends the fight before the normal distance.
	await _wait_seconds(1.1)
	away = (human.global_position - pair.human_global_position())
	away.y = 0.0
	await _pull(away.normalized(), human.max_length + DogAgency.DRAG_OUT_EXTRA + 0.3, int((DogAgency.DRAG_OUT_SECONDS + 0.3) * 60))
	check_eq(coordinator.last_result, CombatSimulation.Result.DISENGAGED, "sustained pull drags the owner out")
	check_eq(agency.last_pull, &"escaped", "drag-out result")
	check_eq(_count(&"agency_pull_escape"), 1, "RUN: dragged away from a fight")

	# --- Searching while a fight goes on ----------------------------------------------
	await _wait_until(func() -> bool: return pair.is_idle(), 900)
	human.global_position = pair.global_position + Vector3(0, 0.1, 1.6)
	await _place(pair.global_position + Vector3(0.5, 0.1, 1.0), pair.global_position)
	await _press(&"interact")
	check(coordinator.is_fighting(), "second fight")
	coordinator.time_scale = 0.0
	var bench := map.get_node("SearchPoints/bench_park") as SearchPoint3D
	dog.global_position = bench.global_position + Vector3(0.5, 0.1, 0.5)
	dog.velocity = Vector3.ZERO
	await _physics(4)
	check(dog.focused == bench, "world stays interactable during a fight")
	await _press(&"interact")
	check(bench.is_searching(), "the dog can sniff around while the humans fight")

	# --- Opponent dog watches the player dog ---------------------------------------------
	coordinator.debug_force_result(CombatSimulation.Result.VICTORY)
	await _physics(3)
	var other := map.get_node("Encounters/pair_far_side") as OpponentPair3D
	dog.global_position = other.global_position + Vector3(3.0, 0.1, 0)
	await _physics(30)
	var to_player := dog.global_position - other._dog.global_position
	check(absf(angle_difference(other._dog.rotation.y, atan2(-to_player.x, -to_player.z))) < 0.4, "opponent dog turns to watch the player dog")

	# --- Debug overlay -------------------------------------------------------------------
	check(agency.debug_text().begins_with("Agency:"), "debug overlay line")

	DirAccess.remove_absolute(TEST_SAVE)
	finish()


# --- helpers ---------------------------------------------------------------

func _place(at: Vector3, look_at_point: Vector3) -> void:
	dog.global_position = Vector3(at.x, 0.1, at.z)
	dog.velocity = Vector3.ZERO
	var d := look_at_point - dog.global_position
	d.y = 0.0
	dog.facing = d.normalized()
	await _physics(2)


## Keeps the dog running in `direction` at `distance` from the owner.
func _pull(direction: Vector3, distance: float, frames: int) -> void:
	coordinator.time_scale = 1.0
	for i in frames:
		if not coordinator.is_fighting():
			return
		dog.global_position = human.global_position + direction * distance + Vector3(0, 0.1, 0)
		dog.velocity = direction * 4.0
		await _tree.physics_frame
		coordinator.time_scale = 0.001


func _press(action: StringName) -> void:
	Input.action_press(action)
	await _tree.physics_frame
	Input.action_release(action)
	await _physics(2)


func _count(event_id: StringName) -> int:
	return run.training.events.filter(func(e: TrainingEvent) -> bool: return e.data.id == event_id).size()


func _wait_seconds(seconds: float) -> void:
	await _physics(int(seconds * 60))


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
