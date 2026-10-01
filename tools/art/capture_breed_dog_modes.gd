extends SceneTree
## ART screenshot helper; never advances gameplay or changes save data.
var showroom: Node3D

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	showroom = (load("res://assets/art_previews/dogs/dog_lineup.tscn") as PackedScene).instantiate()
	root.add_child(showroom)
	showroom.set_process(false)
	for i in 10:
		await process_frame
	for player in showroom.players:
		assert(player.has_animation("Idle") and player.has_animation("Walk") and player.has_animation("Sit"))
		player.play("Idle")
		player.seek(0.5, true)
		player.pause()
	var folder := "res://build/dogs_texture_codex/godot"
	DirAccess.make_dir_recursive_absolute(folder)
	for use_toon in [false, true]:
		SoftToon.set_enabled(self, use_toon)
		showroom.label.text = "Breed texture repair / " + ("Soft toon" if use_toon else "Standard")
		for i in 12:
			await process_frame
		await RenderingServer.frame_post_draw
		var name := "lineup_toon.png" if use_toon else "lineup_standard.png"
		assert(root.get_texture().get_image().save_png(folder + "/" + name) == OK)
	print("DOG_TEXTURE_MODES_OK dogs=", showroom.dogs.size(), " modes=2")
	quit()
