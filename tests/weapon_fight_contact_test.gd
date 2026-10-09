extends "res://tests/test_case.gd"
## Owner, 2026-10-09 (「穿模了」): in a real fight a held weapon stops on the
## other person's body like a fist does (`FighterPuppet3D.stop_at_body`
## counts it) — never sunk into them. Same bar as fight_body_contact_test:
## past a light press for no more than a few frames, never deep. The weapon
## is measured from its model where the hand holds it.

const TEST_SAVE: String = "user://tests/weapon_fight_contact_save.json"
const ALLOWED_PRESS: float = 0.05
## Resting on their guard (forearms up) is a weapon meeting a guard, as arms
## meet arms in fight_body_contact_test.
const ALLOWED_ON_ARMS: float = 0.08
const ARMS: Array[String] = ["arm", "forearm"]
const MOST_FRAMES_PAST: int = 3
## Never deeper than this, even for a frame (a kick can arrive in one frame
## before the weapon has turned away from it).
const NEVER_DEEPER: float = 0.15
const FIGHT_FRAMES: int = 900

var _tree: SceneTree


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_tree = get_tree()
	for id: StringName in [&"umbrella", &"broom"]:
		await _fight(id)
	finish()


func _fight(id: StringName) -> void:
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
	var weapon := DataRegistry.get_weapon(id)
	map.run_manager.equipped_weapon = weapon
	map.human.puppet.hold(weapon)
	var coordinator := map.coordinator
	var pair := map.get_node("Encounters/pair_park") as OpponentPair3D
	map.dog.global_position = pair.global_position + Vector3(1.0, 0.1, 1.0)
	await _physics(6)
	pair.interact(map.run_manager)
	await _physics(6)
	check(coordinator.is_fighting(), "%s: the fight is on" % id)
	var ours := map.human.puppet
	var theirs := pair.human_puppet._body as P04HumanVisual
	var sim := coordinator.engagement.simulation
	var deepest := 0.0
	var run := 0
	var longest := 0
	var frames := 0
	var what := ""
	for i in FIGHT_FRAMES:
		await _tree.process_frame
		if not coordinator.is_fighting():
			break
		for f in sim.fighters:
			f.hp = maxf(f.hp, f.max_hp * 0.5)
		frames += 1
		var hit := BodyContact.deepest(ours.weapon_capsules(), BodyContact.capsules(theirs.skeleton))
		var depth: float = hit[0]
		deepest = maxf(deepest, depth)
		run = run + 1 if depth > (ALLOWED_ON_ARMS if hit[2] in ARMS else ALLOWED_PRESS) else 0
		if run > longest:
			longest = run
			what = "%s %s into their %s (%s), %.2f m apart" % [String((ours._body as P04HumanVisual).player.current_animation).get_file(), hit[1], hit[2], String(theirs.player.current_animation).get_file(), sim.distance() / 100.0]
	print("  %s: deepest %.3f m, longest %d frames past %.2f m (%s)" % [id, deepest, longest, ALLOWED_PRESS, what])
	check(frames > 300, "%s: a long fight was watched (%d frames)" % [id, frames])
	check(longest <= MOST_FRAMES_PAST, "%s: the weapon does not stay inside the other person (%d frames)" % [id, longest])
	check(deepest <= NEVER_DEEPER, "%s: nor ever goes deep into them (%.3f m)" % [id, deepest])
	coordinator.debug_force_result(CombatSimulation.Result.DISENGAGED)
	await _physics(3)


func _physics(n: int) -> void:
	for i in n:
		await _tree.physics_frame


func _wait_for_scene(path: String) -> void:
	for i in 600:
		await _tree.process_frame
		if _tree.current_scene != null and _tree.current_scene.scene_file_path == path:
			return
	push_error("timed out waiting for " + path)
