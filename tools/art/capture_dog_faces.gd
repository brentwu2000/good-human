extends SceneTree
## Close-ups in the actual preview renderer, with fixed pose and both materials.
const BREEDS = ["chihuahua", "pomeranian", "poodle", "frenchie", "corgi", "shiba", "golden"]
const HEIGHTS = [0.35, 0.38, 0.45, 0.45, 0.45, 0.55, 0.75]

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var showroom = load("res://assets/art_previews/dogs/dog_lineup.tscn").instantiate()
	root.add_child(showroom)
	showroom.set_process(false)
	for i in 10:
		await process_frame
	assert(showroom.dogs.size() == 7 and showroom.players.size() == 7)
	for player in showroom.players:
		player.stop()
		for clip in ["Idle", "Walk", "Sit"]:
			assert(player.has_animation(clip))
	var folder := "res://build/dogs_face_repair_r5/godot"
	var args := OS.get_cmdline_user_args()
	var output_index := args.find("--output")
	if output_index >= 0 and output_index + 1 < args.size():
		folder = args[output_index + 1]
	DirAccess.make_dir_recursive_absolute(folder)
	showroom.camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	for use_toon in [false, true]:
		SoftToon.set_enabled(self, use_toon)
		var mode := "toon" if use_toon else "standard"
		for index in 7:
			for j in 7:
				showroom.dogs[j].visible = j == index
			var h: float = HEIGHTS[index]
			var target: Vector3 = showroom.dogs[index].position + Vector3(0, h * 0.70, h * 0.22)
			showroom.camera.size = h * 0.78
			for degrees in [-45, 0, 45]:
				var angle := deg_to_rad(float(degrees))
				showroom.camera.position = target + Vector3(sin(angle), 0.10, cos(angle)) * 2
				showroom.camera.look_at(target)
				showroom.label.text = "%s / %s / %s degrees" % [BREEDS[index], mode, degrees]
				for frame in 8:
					await process_frame
				await RenderingServer.frame_post_draw
				var path := "%s/%s_%s_%s.png" % [folder, BREEDS[index], mode, degrees]
				assert(root.get_texture().get_image().save_png(path) == OK)
	print("DOG_FACE_CAPTURE_OK dogs=7 angles=3 modes=2")
	quit()
