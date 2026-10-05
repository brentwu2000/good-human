extends SceneTree
## ART candidate comparison; does not alter gameplay or save data.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var showroom = load("res://assets/art_previews/dogs/dog_lineup.tscn").instantiate()
	root.add_child(showroom)
	showroom.set_process(false)
	for i in 10:
		await process_frame
	for dog in showroom.dogs:
		dog.visible = false
	for player in showroom.players:
		player.stop()
	var folder := "res://build/dogs_muzzle_r8/godot"
	DirAccess.make_dir_recursive_absolute(folder)
	var candidate = load("res://assets/art_previews/dogs/candidates/r8/pomeranian.glb").instantiate()
	showroom.add_child(candidate)
	candidate.position = showroom.dogs[1].position
	SoftToon.register(candidate)
	var player = candidate.find_child("AnimationPlayer", true, false)
	for clip in ["Idle", "Walk", "Sit"]:
		assert(player.has_animation(clip))
	player.stop()
	showroom.camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	showroom.camera.size = 0.38 * 0.78
	var target: Vector3 = candidate.position + Vector3(0, 0.38 * 0.70, 0.38 * 0.22)
	for version in ["r6", "r8"]:
		candidate.visible = version == "r8"
		showroom.dogs[1].visible = version == "r6"
		for toon in [false, true]:
			SoftToon.set_enabled(self, toon)
			for degrees in [-45, 0, 45]:
				var angle := deg_to_rad(float(degrees))
				showroom.camera.position = target + Vector3(sin(angle), 0.10, cos(angle)) * 2
				showroom.camera.look_at(target)
				showroom.label.text = "Pomeranian %s / toon=%s / %s degrees" % [version, toon, degrees]
				for frame in 8:
					await process_frame
				await RenderingServer.frame_post_draw
				assert(root.get_texture().get_image().save_png("%s/%s_%s_%s.png" % [folder, version, toon, degrees]) == OK)
	print("POMERANIAN_R8_CAPTURE_OK versions=2 angles=3 materials=2 clips=3")
	quit()
