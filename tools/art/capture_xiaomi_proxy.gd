extends "res://tests/test_case.gd"
## Capture tool (Claude, 2026-10-17): screenshots of a Xiaomi robot fight in the real walk.
##   godot --path <project> --resolution 720x1280 res://tools/art/capture_xiaomi_proxy.tscn -- <out_dir>
## Xiaomi toy proxy (docs/04_systems/XIAOMI_TOY_PROXY.md, Phase 1), through the
## real 3D walk with Xiaomi as the adopted owner. Her bunny robot fights; she
## steps away, is never on the fighting side, never hit, never knocked down.
## Win, call-back and loss all clean the robot up; a loss is the robot's
## battery, and the walk's usual loss rules still apply.

const TEST_SAVE: String = "user://tests/xiaomi_proxy_save.json"

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

	# Xiaomi is the dog's human.
	var bg := DataRegistry.get_human_background(&"granddaughter")
	check(bg != null and bg.combat_proxy != null, "the granddaughter background has a robot to fight for her")
	var xiaomi := HumanCandidate.new()
	xiaomi.id = &"human_xiaomi"
	xiaomi.background_id = &"granddaughter"
	xiaomi.reaction_set = &"granddaughter"
	for stat in HumanCandidate.STAT_NAMES:
		xiaomi.stats[stat] = 5
	Game.pair_state = PairState.adopted(PairState.classic().dog, xiaomi, "小米", "")
	check(Game.owner_has_proxy(), "her fights are fought by a proxy")
	check_eq(Game.owner_fighter().skeletal_model, bg.skeletal_model, "she walks as her own model")
	check_eq(Game.owner_proxy_fighter().body_kind, &"bunny_robot", "the proxy is the bunny robot")
	check_eq(Game.owner_proxy_fighter().stats.strength, 5, "with her own rolled stats")

	_tree.current_scene.get_node("%Walk3DButton").pressed.emit()
	await _wait_for_scene(Game.RUN_MAP_3D_SCENE)
	await _frames(5)
	var map := _tree.current_scene as RunMap3D
	var run := map.run_manager
	var coordinator := map.coordinator
	var human := map.human
	var dog := map.dog
	check(coordinator.uses_proxy(), "the walk knows her robot fights")

	# She carries a weapon in her backpack, not in her hand.
	var gear_id: StringName = StringName(OS.get_cmdline_user_args()[1]) if OS.get_cmdline_user_args().size() > 1 else &"umbrella"
	var umbrella := ItemStack.new(DataRegistry.get_item(gear_id), 1)
	run.take_weapon(umbrella)
	await _frames(2)
	check(human.puppet.held == null, "a weapon she finds goes in her backpack, not her hand")

	var out: String = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "user://xiaomi_capture"
	DirAccess.make_dir_recursive_absolute(out)
	var first := _present(coordinator)[0]
	_stand_beside(human, dog, first)
	await _seconds(0.5)
	_shot(out + "/0_walk.png")
	coordinator.start_engagement(first)
	await _seconds(0.6)
	var robot := coordinator.proxy
	var aabb := _aabb(robot.puppet)
	print("ROBOT body scale ", robot.puppet._body.scale, " height ", aabb.size.y, " at ", robot.global_position)
	print("OPP at ", first.human_global_position(), " gap ", robot.global_position.distance_to(first.human_global_position()))
	print("XIAOMI at ", human.global_position, " DOG at ", dog.global_position, " cam ", get_viewport().get_camera_3d().global_position)
	for i in 8:
		await _seconds(0.6)
		_shot(out + "/%d_fight.png" % (i + 1))
		if i == 3:
			# A bystander's view from the side, to read the layout.
			var game_cam := get_viewport().get_camera_3d()
			var side := Camera3D.new()
			map.add_child(side)
			var mid := (robot.global_position + first.human_global_position()) * 0.5
			var across := (first.human_global_position() - robot.global_position).cross(Vector3.UP).normalized()
			side.global_position = mid + across * 5.0 + Vector3(0, 1.6, 0)
			side.look_at(mid + Vector3(0, 0.7, 0))
			side.current = true
			await _frames(3)
			_shot(out + "/side.png")
			# Close on the robot, from the opponent's side (its face, the glove).
			var to_opp := (first.human_global_position() - robot.global_position).normalized()
			side.global_position = robot.global_position + to_opp * 1.3 + across * 0.5 + Vector3(0, 0.7, 0)
			side.look_at(robot.global_position + Vector3(0, 0.5, 0))
			await _frames(3)
			_shot(out + "/robot_close.png")
			side.current = false
			game_cam.current = true
			side.queue_free()
			print("OPP visible ", first.human_puppet.visible, " is_visible_in_tree ", first.human_puppet.is_visible_in_tree())
	coordinator.debug_force_result(CombatSimulation.Result.DEFEAT)
	await _seconds(0.8)
	_shot(out + "/9_defeat.png")
	finish()


func _aabb(node: Node3D) -> AABB:
	var box := AABB()
	var first_box := true
	for m in node.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		var b := mi.global_transform * mi.get_aabb()
		box = b if first_box else box.merge(b)
		first_box = false
	return box


func _shot(path: String) -> void:
	get_viewport().get_texture().get_image().save_png(path)


func umbrella_weapon() -> WeaponData:
	return DataRegistry.weapon_for_item(&"umbrella")


## Pairs that are in the park right now (some only come at certain times).
func _present(coordinator: CombatCoordinator3D) -> Array[OpponentPair3D]:
	var out: Array[OpponentPair3D] = []
	for p in coordinator.get_pairs():
		if p.is_present() and p.is_idle():
			out.append(p)
	return out


func _stand_beside(human: HumanFollower3D, dog: DogController3D, pair: OpponentPair3D) -> void:
	dog.global_position = pair.global_position + Vector3(0.7, 0.2, 0.9)
	dog.velocity = Vector3.ZERO
	human.global_position = pair.global_position + Vector3(1.6, 0.2, 2.0)


func _flat(v: Vector3) -> float:
	return Vector2(v.x, v.z).length()


func _ids(stacks: Array) -> Array:
	var out: Array = []
	for s in stacks:
		out.append(String(s.item_id) if s is ItemStack else String(s))
	return out


func _frames(count: int) -> void:
	for i in count:
		await _tree.process_frame


func _seconds(s: float) -> void:
	await _tree.create_timer(s).timeout


func _wait_for_scene(path: String) -> void:
	for i in 600:
		if _tree.current_scene != null and _tree.current_scene.scene_file_path == path:
			return
		await _tree.process_frame
	check(false, "scene %s never loaded" % path)
