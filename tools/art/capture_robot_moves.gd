extends "res://tests/test_case.gd"
## Capture tool (Claude, 2026-10-17): the bunny robot in a real fight, from its side, many
## frames, to read which arm moves and which way.
##   godot --path <project> --resolution 540x540 res://tools/art/capture_robot_moves.tscn -- <out_dir>

var _tree: SceneTree


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_tree = get_tree()
	var out: String = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	SaveManager.save_path = "user://tests/robot_moves_save.json"
	var placeholder := Node.new()
	_tree.root.add_child(placeholder)
	_tree.current_scene = placeholder
	_tree.change_scene_to_file(Game.BOOT_SCENE)
	await _wait_for_scene(Game.HOME_SCENE)
	var xiaomi := HumanCandidate.new()
	xiaomi.id = &"human_xiaomi"
	xiaomi.background_id = &"granddaughter"
	for stat in HumanCandidate.STAT_NAMES:
		xiaomi.stats[stat] = 5
	Game.pair_state = PairState.adopted(PairState.classic().dog, xiaomi, "小米", "")
	_tree.current_scene.get_node("%Walk3DButton").pressed.emit()
	await _wait_for_scene(Game.RUN_MAP_3D_SCENE)
	await _frames(5)
	var map := _tree.current_scene as RunMap3D
	var coordinator := map.coordinator
	var pair: OpponentPair3D = null
	for p in coordinator.get_pairs():
		if p.is_present() and p.is_idle():
			pair = p
			break
	map.dog.global_position = pair.global_position + Vector3(0.7, 0.2, 0.9)
	map.human.global_position = pair.global_position + Vector3(1.6, 0.2, 2.0)
	coordinator.start_engagement(pair)
	await _frames(30)
	var robot := coordinator.proxy
	var cam := Camera3D.new()
	map.add_child(cam)
	cam.current = true
	coordinator.engagement.simulation.fighters[CombatSimulation.PLAYER].hp = 9999.0
	for i in 70:
		var opp := pair.human_global_position()
		var mid := (robot.global_position + opp) * 0.5
		var across := (opp - robot.global_position).cross(Vector3.UP).normalized()
		cam.global_position = robot.global_position + across * 2.2 + (robot.global_position - opp).normalized() * 0.6 + Vector3(0, 0.8, 0)
		cam.look_at(robot.global_position + Vector3(0, 0.5, 0))
		await _seconds(0.12)
		var fighter := coordinator.engagement.simulation.fighters[CombatSimulation.PLAYER] if coordinator.engagement != null else null
		var tag := "%s_%s" % [CombatFighter.Phase.keys()[fighter.phase], fighter.action.animation_key if fighter != null and fighter.action != null else "none"] if fighter != null else "end"
		get_viewport().get_texture().get_image().save_png("%s/%02d_%s.png" % [out, i, tag])
		# Where each arm's lowest point is, relative to the robot's facing (+ = towards the opponent).
		var facing := (opp - robot.global_position)
		facing.y = 0.0
		facing = facing.normalized()
		var body := robot.puppet._body
		var line := "MEASURE %s" % tag
		for nm in ["ArmL", "ArmR", "LegL", "LegR"]:
			var joint := Greybox.part(body, nm)
			var lowest := Vector3.INF
			for m in joint.find_children("*", "MeshInstance3D", true, false):
				var mi := m as MeshInstance3D
				var bb := mi.global_transform * mi.get_aabb()
				var c := bb.get_center()
				if lowest == Vector3.INF or c.y < lowest.y:
					lowest = c
			var rel := lowest - joint.global_position
			var side := facing.cross(Vector3.UP)
			line += "  %s fwd %+.2f side %+.2f (joint side %+.2f)" % [nm, rel.dot(facing), rel.dot(side), (joint.global_position - robot.global_position).dot(side)]
		print(line)
	check(true, "captured")
	finish()


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
