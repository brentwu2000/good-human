extends SceneTree
## The shared fight clips as the game plays them (P04HumanVisual + fight library), the same
## moments for every human, chest-up from the front-right (Claude, 2026-10-17).
##   godot --path <project> --resolution 360x360 --script res://tools/art/capture_fight_poses.gd -- <out_dir>
## GH_NO_RETARGET=1 shows the clips without the per-skeleton conversion.

var MODELS := ["p04_owner/p04_owner_refined", "office_worker/office_worker", "delivery_rider/delivery_rider",
	"retired_fisher/retired_fisher", "market_auntie/market_auntie", "ai_grandma/grandma", "gym_coach/gym_coach"]
var POSES := [["Fight_Stance", 0.3], ["Fight_Jab", 0.5], ["Fight_Hook", 0.5], ["Fight_Block", 0.5]]
## "relaxed" as the second argument: the walk/idle and Mesh2Motion gestures instead.
const RELAXED := [["relaxed/Idle_Relaxed", 0.3], ["relaxed/Walk_Relaxed", 0.4], ["m2m/M2M_Phone", 0.5], ["m2m/M2M_Cheer_One", 0.5]]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	if OS.get_cmdline_user_args().size() > 1 and OS.get_cmdline_user_args()[1] == "relaxed":
		POSES = RELAXED
		MODELS.append("xiaomi/xiaomi")
	DirAccess.make_dir_recursive_absolute(out)
	var world := Node3D.new()
	get_root().add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.8, 0.84, 0.88)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.9, 0.9, 0.95)
	env.environment.ambient_light_energy = 0.7
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.7, 0.6, 0)
	world.add_child(sun)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	world.add_child(cam)
	cam.current = true
	for m in MODELS:
		var visual := P04HumanVisual.new(load("res://assets/characters/human/models/%s.glb" % m) as PackedScene)
		world.add_child(visual)
		await process_frame
		var sk := visual.skeleton
		for pose in POSES:
			var clip_name: String = visual.fight_clip(pose[0]) if not "/" in pose[0] else pose[0]
			if not visual.player.has_animation(clip_name) and pose[0].begins_with("relaxed/"):
				clip_name = pose[0].get_file()  # a model with its own relaxed clips
			visual.pose_clip(clip_name, pose[1])
			for i in 8:
				await process_frame
			var chest := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("spine_03")).origin
			var head := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("head")).origin
			cam.size = head.y * 0.95
			# The fighter faces -Z: look from the front, a little to its right.
			cam.global_position = chest + Vector3(1.0, 0.1, -2.4)
			cam.look_at(chest + Vector3(0, 0.05, 0))
			for i in 3:
				await process_frame
			await RenderingServer.frame_post_draw
			get_root().get_texture().get_image().save_png("%s/%s_%s.png" % [out, m.get_file(), pose[0].get_file()])
		visual.queue_free()
		await process_frame
	print("FIGHT_POSES done")
	quit()
