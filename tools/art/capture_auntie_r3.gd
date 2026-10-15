extends SceneTree
## Market auntie r3 review captures (Claude, 2026-10-15): full views, close-ups of the
## head, hands and towel shoulder, and three frames of every clip, all in Godot.
##   godot --path <project> --resolution 640x640 --script res://tools/art/capture_auntie_r3.gd -- <res://model.glb> <out dir> [prefix]

var failures: Array = []


func _initialize() -> void:
	run.call_deferred()


func _shot(cam: Camera3D, target: Vector3, dir_deg: float, elev: float, size: float, path: String) -> void:
	var t := deg_to_rad(dir_deg)
	cam.size = size
	cam.position = target + Vector3(sin(t), elev, cos(t)).normalized() * 6.0
	cam.look_at(target, Vector3.UP)
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)


func run() -> void:
	var args := OS.get_cmdline_user_args()
	var model_path: String = args[0]
	var out: String = args[1]
	var prefix: String = args[2] if args.size() > 2 else "r3"
	DirAccess.make_dir_recursive_absolute(out)
	root.size = Vector2i(640, 640)
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(.80, .84, .88)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(.9, .9, .95)
	env.environment.ambient_light_energy = .6
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 25, 0)
	world.add_child(sun)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	world.add_child(cam)
	cam.make_current()
	var model := (load(model_path) as PackedScene).instantiate() as Node3D
	world.add_child(model)
	var sk := model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var ap := model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	var aabb := AABB()
	var first := true
	for m: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		var box := m.global_transform * m.get_aabb()
		aabb = box if first else aabb.merge(box)
		first = false
	var centre := aabb.get_center()
	var h := aabb.size.y

	var func_bone_pos := func(n: String) -> Vector3:
		return sk.global_transform * sk.get_bone_global_pose(sk.find_bone(n)).origin

	# Rest-ish: first clip at t=0 is what the game shows standing.
	# Stills in the rest pose (arms down), so paint and shape read without a clip.
	ap.stop()
	sk.reset_bone_poses()
	sk.force_update_all_bone_transforms()
	for v in [["front", 0.0], ["back", 180.0], ["left", 90.0], ["right", -90.0], ["three_quarter", 45.0]]:
		await _shot(cam, centre, v[1], 0.0, h * 1.15, "%s/%s_full_%s.png" % [out, prefix, v[0]])
	var head: Vector3 = func_bone_pos.call("head") + Vector3(0, h * 0.06, 0)
	for v in [["front", 0.0], ["three_quarter", 40.0], ["side", 90.0], ["back", 180.0], ["top", 0.0]]:
		var elev := 1.2 if v[0] == "top" else 0.05
		await _shot(cam, head, v[1], elev, h * 0.36, "%s/%s_head_%s.png" % [out, prefix, v[0]])
	for side in ["l", "r"]:
		var hp: Vector3 = func_bone_pos.call("hand_" + side)
		var d := 60.0 if side == "l" else -60.0
		await _shot(cam, hp, d, 0.1, h * 0.22, "%s/%s_hand_%s.png" % [out, prefix, side])
	var sh: Vector3 = (func_bone_pos.call("clavicle_l") + func_bone_pos.call("clavicle_r")) * 0.5
	for v in [["front", 0.0], ["left", 70.0], ["right", -70.0], ["back", 180.0]]:
		await _shot(cam, sh, v[1], 0.15, h * 0.42, "%s/%s_shoulder_%s.png" % [out, prefix, v[0]])
	# Motion: three frames per clip, the whole body (wide frame so lunges stay inside).
	for clip in ap.get_animation_list():
		var dur := ap.get_animation(clip).length
		ap.play(clip)
		for k in 3:
			ap.seek(dur * (0.15 + 0.35 * k), true)
			sk.force_update_all_bone_transforms()
			for b in sk.get_bone_count():
				if not sk.get_bone_global_pose(b).is_finite():
					failures.append(clip + " non-finite pose")
			await _shot(cam, centre, 30.0, 0.1, h * 1.6, "%s/%s_motion_%s_%d.png" % [out, prefix, String(clip).replace("/", "_"), k])
			if k == 1 and String(clip) in ["Idle", "Block", "Jab", "Walk_Relaxed", "HeavyHook"]:
				var chest: Vector3 = func_bone_pos.call("spine_03")
				await _shot(cam, chest, 20.0, 0.1, h * 0.62, "%s/%s_upper_%s.png" % [out, prefix, String(clip)])
	print("AUNTIE_R3_CAPTURE ", out, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
