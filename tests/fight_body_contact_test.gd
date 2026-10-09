extends "res://tests/test_case.gd"
## Fighting-game style follow-up (owner, 2026-10-07: 「打鬥的方式太生硬」):
## two bodies in a fight must not pass through each other. The root spacing
## test only keeps the pelvises apart; this measures the bodies the clips
## actually pose. Each skeleton is a set of capsules (`BodyContact`); every
## frame of a real fight the deepest overlap between the two people is
## recorded with the clips each was playing. A blow may touch what it hits,
## not sink in — and the blows still have to be thrown in full.

const TEST_SAVE: String = "user://tests/fight_body_contact_save.json"
## A landed blow presses in a little; anything deeper reads as passing through.
const ALLOWED_PRESS: float = 0.04
## Arms meeting arms (a blow on a guard, two guards touching) a little more:
## forearms crossing is what a guard is for, and a blend into a reaction
## can cross them for a frame or two.
const ALLOWED_ARMS: float = 0.08
const ARMS: Array[String] = ["arm", "forearm"]
## A blow landing can press past that for a frame (the procedural recoil on
## top of the clips moves a frame after the clips are settled); a body seen
## inside another is one that stays there. Three frames (50 ms) is a kick
## held on a thigh while the procedural knock-back catches up.
const MOST_FRAMES_PAST: int = 3
## And never this deep, even for a frame.
const NEVER_DEEPER: float = 0.1
const FIGHT_FRAMES: int = 1800
const ATTACKS: Array[String] = ["Fight_Jab", "Fight_Cross", "Fight_Hook", "Fight_Hook_Rear", "Fight_Kick", "Fight_Kick_Lead"]

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
	var pair := map.get_node("Encounters/pair_park") as OpponentPair3D
	map.dog.global_position = pair.global_position + Vector3(1.0, 0.1, 1.0)
	await _physics(6)
	pair.interact(map.run_manager)
	await _physics(6)
	check(coordinator.is_fighting(), "the fight is on")
	var ours := map.human.puppet._body as P04HumanVisual
	var theirs := pair.human_puppet._body as P04HumanVisual
	check(ours != null and theirs != null, "both fighters are skeletal")
	if ours == null or theirs == null:
		finish()
		return
	var sim := coordinator.engagement.simulation
	var deepest := 0.0
	var deepest_what := ""
	var run := 0
	var longest := 0
	var longest_what := ""
	var reached := {}
	var seen := {}
	var frames := 0
	for i in FIGHT_FRAMES:
		await _tree.process_frame
		if not coordinator.is_fighting():
			break
		# Nobody may go down: this is about bodies, not the result (a knock-down
		# mid-test left a body frozen in its down clip while the fight went on).
		for f in sim.fighters:
			f.hp = f.max_hp
		frames += 1
		for v: P04HumanVisual in [ours, theirs]:
			if _clip(v) != "":
				reached[_clip(v)] = maxf(reached.get(_clip(v), 0.0), _t(v))
				seen[_clip(v)] = seen.get(_clip(v), 0) + 1
		var hit := BodyContact.deepest(BodyContact.capsules(ours.skeleton), BodyContact.capsules(theirs.skeleton))
		var depth: float = hit[0]
		var what := "%s %s × %s %s" % [_clip(ours), hit[1], _clip(theirs), hit[2]]
		var limit := ALLOWED_ARMS if hit[1] in ARMS and hit[2] in ARMS else ALLOWED_PRESS
		run = run + 1 if depth > limit else 0
		if run > longest:
			longest = run
			longest_what = what
		if depth > deepest:
			deepest = depth
			deepest_what = what
	check(frames > 600, "a long fight was watched (%d frames)" % frames)
	check(longest <= MOST_FRAMES_PAST, "no body stays inside the other (%d frames past the allowance: %s)" % [longest, longest_what])
	check(deepest <= NEVER_DEEPER, "nor ever goes deep into it (deepest %.3f m: %s)" % [deepest, deepest_what])
	# Stopping blows at the body must not stop them being thrown. The bug this
	# guards against froze every blow at the start of its clip; a single fight
	# pressed chest to chest can rightly stop one kind of blow early, so: some
	# blow reaches its strike (0.5), and most kinds seen get well out of their
	# wind-up.
	var kinds := 0
	var thrown := 0
	var furthest := 0.0
	for clip: String in ATTACKS:
		if seen.get(clip, 0) >= 60:
			kinds += 1
			furthest = maxf(furthest, reached[clip])
			if reached[clip] >= 0.25:
				thrown += 1
	check(kinds >= 2, "several kinds of blow were thrown (%d)" % kinds)
	check(furthest >= 0.5, "blows still reach their strike (furthest %.2f)" % furthest)
	check(thrown * 2 >= kinds, "most kinds get out of their wind-up (%d of %d: %s)" % [thrown, kinds, reached])
	finish()


func _clip(visual: P04HumanVisual) -> String:
	return String(visual.player.current_animation).get_file()


func _t(visual: P04HumanVisual) -> float:
	var p := visual.player
	return p.current_animation_position / p.current_animation_length if p.current_animation != "" else -1.0


func _physics(frames: int) -> void:
	for i in frames:
		await _tree.physics_frame


func _wait_for_scene(path: String) -> void:
	for i in 600:
		await _tree.process_frame
		if _tree.current_scene != null and _tree.current_scene.scene_file_path == path:
			return
	push_error("timed out waiting for " + path)
