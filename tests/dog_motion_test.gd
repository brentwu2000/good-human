extends "res://tests/test_case.gd"
## Owner, 2026-10-09 (「好的，狗的部分也要使用」): every dog model gets
## Mesh2Motion's run, nose-down, bark and alert clips (baked per model), plays
## them in the right moments, and stays on its feet doing so — each breed at
## its own size, nothing floating or sunk into the ground.

const MODELS: Array[String] = [
	"res://assets/characters/dog/models/shiba_01/shiba_01.glb",
	"res://assets/characters/dog/models/breeds/chihuahua.glb",
	"res://assets/characters/dog/models/breeds/corgi.glb",
	"res://assets/characters/dog/models/breeds/frenchie.glb",
	"res://assets/characters/dog/models/breeds/golden.glb",
	"res://assets/characters/dog/models/breeds/pomeranian.glb",
	"res://assets/characters/dog/models/breeds/poodle.glb",
	"res://assets/characters/dog/models/breeds/shiba.glb",
]


func _ready() -> void:
	for path in MODELS:
		var name := path.get_file()
		var model := (load(path) as PackedScene).instantiate() as Node3D
		add_child(model)
		var motion := DogModelMotion3D.new()
		add_child(motion)
		motion.bind(model)
		var player := motion._player
		for clip in [DogModelMotion3D.RUN_CLIP, DogModelMotion3D.SNIFF_CLIP, DogModelMotion3D.BARK_CLIP, DogModelMotion3D.ALERT_CLIP]:
			check(player.has_animation(clip), "%s has %s" % [name, clip])
		# The right clip at the right moment.
		motion.update_motion(0.016, 5.5, true)
		check(player.current_animation == DogModelMotion3D.RUN_CLIP, "%s runs with the run (%s)" % [name, player.current_animation])
		motion.update_motion(0.016, 0.0, false)
		motion.play_sniff()
		motion.update_motion(0.016, 0.0, false)
		check(player.current_animation == DogModelMotion3D.SNIFF_CLIP, "%s puts its nose down" % name)
		motion._sniff_left = 0.0
		motion.play_bark()
		motion.update_motion(0.016, 0.0, false)
		check(player.current_animation == DogModelMotion3D.BARK_CLIP, "%s barks with its body" % name)
		motion._bark_left = 0.0
		motion.set_alert(true)
		motion.update_motion(0.016, 0.0, false)
		check(player.current_animation == DogModelMotion3D.ALERT_CLIP, "%s stands alert" % name)
		# On its feet: through the run, the lowest paw stays near the ground.
		var skeleton := motion._find_skeleton(model)
		var length := player.get_animation(DogModelMotion3D.RUN_CLIP).length
		var lowest := INF
		var highest_low := -INF
		for i in 12:
			player.play(DogModelMotion3D.RUN_CLIP)
			player.seek(length * i / 12.0, true)
			var low := INF
			for bone in ["front_paw_L", "front_paw_R", "rear_paw_L", "rear_paw_R"]:
				low = minf(low, (skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(bone))).origin.y)
			lowest = minf(lowest, low)
			highest_low = maxf(highest_low, low)
		check(lowest > -0.08, "%s: its paws don't sink into the ground running (%.2f m)" % [name, lowest])
		check(highest_low < 0.35, "%s: nor does it float off it (%.2f m)" % [name, highest_low])
		motion.queue_free()
		model.queue_free()
	finish()
