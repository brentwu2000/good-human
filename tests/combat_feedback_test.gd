extends "res://tests/test_case.gd"
## P-02 remainder in the real 3D walk: the owner's condition in their body
## (D4/P02-008), the dog's instinct (D4/P02-009), and the debug and camera
## comparison tools (D4/P02-011, for the P02-012 blind comparison).

const TEST_SAVE: String = "user://tests/combat_feedback_save.json"
const KICK: CombatSkillData = preload("res://data/combat/skills/skill_kick.tres")

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
	pair = map.get_node("Encounters/pair_park") as OpponentPair3D

	human.global_position = pair.global_position + Vector3(0, 0.1, 1.6)
	dog.global_position = pair.global_position + Vector3(0.9, 0.1, 1.2)
	await _physics(3)
	Input.action_press(&"interact")
	await _tree.physics_frame
	Input.action_release(&"interact")
	await _physics(2)
	check(coordinator.is_fighting(), "a fight")
	coordinator.time_scale = 0.0

	await _test_owner_condition()
	await _test_dog_instinct()
	await _test_camera_comparison()
	_test_debug_tools()
	await _test_bodies_stay_upright()

	coordinator.debug_force_result(CombatSimulation.Result.DISENGAGED)
	coordinator.time_scale = 1.0
	await _physics(3)
	finish()


## D4/P02-008: HEALTHY / HURT / CRITICAL read in the body. Hurt: breathing
## hard, guard pulled in. Critical: the guard sags, they sway, and now and then
## they falter.
func _test_owner_condition() -> void:
	var puppet := human.puppet
	var arm := Greybox.part(puppet._body, "ArmR")
	var torso := Greybox.part(puppet._body, "Torso")
	var head := Greybox.part(puppet._body, "Head")
	for pair_: Array in [[1.0, FighterPuppet3D.Condition.HEALTHY], [0.5, FighterPuppet3D.Condition.HURT], [0.2, FighterPuppet3D.Condition.CRITICAL]]:
		puppet.set_hp_ratio(pair_[0])
		check_eq(puppet.condition_state(), pair_[1], "%d%% health reads as %s" % [int(pair_[0] * 100.0), FighterPuppet3D.Condition.keys()[pair_[1]]])

	var sample := func(ratio: float) -> Dictionary:
		if puppet._pose_tween != null:
			puppet._pose_tween.kill()
		puppet._reset_pose()
		puppet.set_guard(false)
		puppet.motion.state = CombatMotion3D.State.CIRCLE
		puppet.set_hp_ratio(ratio)
		var breath := Vector2(INF, -INF)
		var tucked := 0.0
		var sway := 0.0
		var faltered := false
		for i in 150:
			puppet._time += 1.0 / 60.0
			puppet.play_motion(1.0 / 60.0)
			breath = Vector2(minf(breath.x, torso.rotation.x), maxf(breath.y, torso.rotation.x))
			tucked = minf(tucked, arm.rotation.x)
			sway = maxf(sway, absf(puppet._body.rotation.z))
			faltered = faltered or head.rotation.x > 0.2
		return {"breath": breath.y - breath.x, "tucked": tucked, "sway": sway, "faltered": faltered}

	var fine: Dictionary = sample.call(1.0)
	var hurt: Dictionary = sample.call(0.5)
	var critical: Dictionary = sample.call(0.2)
	check(fine["breath"] < 0.01 and fine["tucked"] > -0.1, "healthy: steady, arms loose")
	check(hurt["breath"] > 0.06, "hurt: breathing hard (%.2f rad of chest)" % hurt["breath"])
	check(hurt["tucked"] < -0.3, "hurt: guard pulled in tight (%.2f rad)" % hurt["tucked"])
	check(critical["tucked"] > -0.1, "critical: the guard sags with fatigue (%.2f rad)" % critical["tucked"])
	check(critical["sway"] > 0.03, "critical: unsteady on their feet (%.2f rad)" % critical["sway"])
	check(critical["faltered"] and not hurt["faltered"], "critical: now and then they falter")
	puppet.set_hp_ratio(1.0)
	puppet._reset_pose()


## D4/P02-009: a heavy blow winding up at the owner makes the dog bristle; the
## owner in a bad way makes it whine; both in its own body, first and third
## person.
func _test_dog_instinct() -> void:
	var instinct := map.get_node("DogInstinct") as DogInstinct
	check(instinct != null, "the walk has a dog instinct")
	var sim := coordinator.engagement.simulation
	var them := sim.fighters[CombatSimulation.OPPONENT]
	check_eq(instinct.state, DogInstinct.Instinct.CALM, "calm while nothing threatens the owner")

	them.action = KICK
	them.phase = CombatFighter.Phase.WINDUP
	them.phase_time_left = 5.0
	await _physics(15)
	check_eq(instinct.state, DogInstinct.Instinct.THREAT, "a kick winding up at the owner: the dog bristles")
	check(dog._visual.rotation.x < -0.08, "head down and forward (%.2f rad)" % dog._visual.rotation.x)
	check(dog._bark_label.text == "grr", "and a growl")
	var view := dog.first_person_view
	if view != null:
		check(view._muzzle.rotation.x > 0.1, "in its own eyes: the muzzle lifts in a snarl")
		check(view._ears[0].position.y > view._ear_rest[0].origin.y, "and the ears prick up")

	them.phase = CombatFighter.Phase.IDLE
	them.action = null
	coordinator.debug_set_owner_condition(0.2)
	await _physics(15)
	check_eq(instinct.state, DogInstinct.Instinct.WORRY, "the owner in a bad way: the dog worries")
	check(dog._bark_label.text == "嗚…", "and whines")
	if view != null:
		check(view._ears[0].position.y < view._ear_rest[0].origin.y, "ears laid back and down")

	coordinator.debug_set_owner_condition(1.0)
	await _physics(15)
	check_eq(instinct.state, DogInstinct.Instinct.CALM, "and settles once it is over")
	check(absf(dog._visual.rotation.x) < 0.02, "head back up")


## D4/P02-011/012: the P-02 owner-focused third person, for the comparison.
func _test_camera_comparison() -> void:
	var rig := map.rig
	coordinator.blows_landed = 1
	CameraRig3D.combat_pov = false
	await _physics(90)
	check_eq(rig.context, CameraRig3D.Context.ACTIVE, "the fight proper")
	check(rig.pov < 0.05, "the P-02 camera stays in third person (pov %.2f)" % rig.pov)
	CameraRig3D.combat_pov = true
	await _physics(90)
	check(rig.pov > 0.9, "the Dog POV camera snaps into the dog's eyes (pov %.2f)" % rig.pov)


func _test_debug_tools() -> void:
	check(coordinator.debug_text().begins_with("Combat:"), "debug overlay: camera and owner condition")
	var instinct := map.get_node("DogInstinct") as DogInstinct
	check(instinct.debug_text().begins_with("Instinct:"), "debug overlay: the dog's instinct")
	var panel := map.find_children("*", "DebugPanel", true, false)
	if panel.is_empty():
		return
	var buttons := (panel[0] as Node).find_children("*", "Button", true, false)
	var camera_button: Button = null
	var critical_button: Button = null
	for node in buttons:
		var button := node as Button
		if button.text.begins_with("戰鬥鏡頭"):
			camera_button = button
		elif button.text.begins_with("主人重傷"):
			critical_button = button
	check(camera_button != null and critical_button != null, "the debug panel has the camera switch and the critical-owner button")
	if camera_button != null:
		var before := CameraRig3D.combat_pov
		var log_before := FighterPuppet3D.show_combat_text
		camera_button.pressed.emit()
		check(CameraRig3D.combat_pov != before, "the camera switch flips the combat camera")
		check_eq(FighterPuppet3D.show_combat_text, log_before, "and nothing else")
		camera_button.pressed.emit()
	if critical_button != null:
		critical_button.pressed.emit()
		check(coordinator.owner_condition() <= 0.26, "the critical-owner button puts the owner at 25%% (%.2f)" % coordinator.owner_condition())
		coordinator.debug_set_owner_condition(1.0)


## Codex's model in a real fight: the clips carry the body and the
## choreography layers over them, and nothing accumulates. The layer once added
## onto its own output wherever a clip did not key a bone (the import drops
## constant tracks), and the pelvis drifted to 90–160°: fighters leaning far
## back, one turned on its side in mid-air.
func _test_bodies_stay_upright() -> void:
	if not coordinator.is_fighting():
		return
	var skeletal := human.puppet._body as P04HumanVisual
	if skeletal == null:
		return
	coordinator.time_scale = 1.0
	var pelvis := skeletal.skeleton.find_bone("pelvis")
	var tilt := func() -> float:
		var up := (skeletal.skeleton.global_basis * skeletal.skeleton.get_bone_global_pose(pelvis).basis).y.normalized()
		return rad_to_deg(acos(clampf(up.dot(Vector3.UP), -1.0, 1.0)))
	var rest_up := (skeletal.skeleton.global_basis * skeletal.skeleton.get_bone_global_rest(pelvis).basis).y.normalized()
	var rest: float = rad_to_deg(acos(clampf(rest_up.dot(Vector3.UP), -1.0, 1.0)))
	var worst := 0.0
	var clips := {}
	for i in 600:
		await _tree.physics_frame
		if not coordinator.is_fighting():
			break
		worst = maxf(worst, absf(tilt.call() - rest))
		clips[skeletal.player.current_animation] = true
	check(clips.size() >= 3, "the fight plays several of Codex's clips (%s)" % ", ".join(clips.keys()))
	check(worst < 35.0, "and the hips never drift from upright (%.0f° from rest at worst)" % worst)
	coordinator.time_scale = 0.0


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
