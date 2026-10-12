extends SceneTree
## ART geometry review: original, candidate and representative clip samples.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var options := {}
	for i in range(0, args.size() - 1, 2):
		options[args[i]] = args[i + 1]
	var candidate_path: String = options.get("--candidate", "res://assets/art_previews/dogs/candidates/r9/pomeranian.glb")
	var baseline_path: String = options.get("--baseline", "res://assets/art_previews/dogs/candidates/r9/pomeranian_r6.glb")
	var candidate_label: String = options.get("--label", "r9")
	var baseline_label: String = options.get("--baseline-label", "r6")
	var height: float = float(options.get("--height", "0.38"))
	var breed: String = options.get("--breed", "Pomeranian")
	if options.has("--encounter"):
		var encounter = load(options["--encounter"])
		assert(encounter.dog_model.resource_path == candidate_path)
		print("ENCOUNTER_MODEL_OK ", candidate_path)
	var room = load("res://assets/art_previews/dogs/dog_lineup.tscn").instantiate()
	root.add_child(room)
	room.set_process(false)
	for i in 10:
		await process_frame
	for dog in room.dogs:
		dog.visible = false
	for sign in room.find_children("*", "Label3D", true, false):
		sign.visible = false
	for p in room.players:
		p.stop()
	var folder: String = options.get("--output", "res://build/dogs_face_r9/godot")
	DirAccess.make_dir_recursive_absolute(folder)
	var dog = load(candidate_path).instantiate()
	room.add_child(dog)
	dog.position = room.dogs[1].position
	SoftToon.register(dog)
	var original = load(baseline_path).instantiate()
	room.add_child(original)
	original.position = dog.position
	SoftToon.register(original)
	original.find_child("AnimationPlayer", true, false).stop()
	var player = dog.find_child("AnimationPlayer", true, false)
	for clip in ["HeadLook", "Sniff"]:
		assert(player.has_animation(clip))
	player.stop()
	room.camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	room.camera.size = height * 0.78
	var target: Vector3 = dog.position + Vector3(0, height * 0.70, height * 0.22)
	for version in [baseline_label, candidate_label]:
		dog.visible = version == candidate_label
		original.visible = version == baseline_label
		for toon in [false, true]:
			SoftToon.set_enabled(self, toon)
			for degrees in [-90, -45, 0, 45, 90]:
				var angle := deg_to_rad(float(degrees))
				room.camera.position = target + Vector3(sin(angle), 0.10, cos(angle)) * 2
				room.camera.look_at(target)
				room.label.text = "%s %s / toon=%s / %s degrees" % [breed, version, toon, degrees]
				await capture("%s/%s_%s_%s.png" % [folder, version, toon, degrees])
	original.visible = false
	dog.visible = true
	SoftToon.set_enabled(self, false)
	room.camera.size = height * 1.65
	target = dog.position + Vector3(0, height * 0.60, 0)
	room.camera.position = target + Vector3(1.5, 0.25, 1.5)
	room.camera.look_at(target)
	for clip in ["HeadLook", "Sniff"]:
		for fraction in [0.0, 0.0625, 0.125, 0.1875, 0.25, 0.3125, 0.375, 0.4375, 0.5, 0.5625, 0.625, 0.6875, 0.75, 0.8125, 0.875, 0.9375, 1.0]:
			player.play(clip)
			player.seek(player.get_animation(clip).length * fraction, true)
			player.pause()
			room.label.text = "%s %s / %s / %.2f" % [breed, candidate_label, clip, fraction]
			await capture("%s/clip_%s_%s.png" % [folder, clip, int(fraction * 100)])
	print("POMERANIAN_%s_CAPTURE_OK rest=20 animation_samples=34" % candidate_label.to_upper())
	quit()

func capture(path: String) -> void:
	for frame in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(path) == OK)
