extends Node
## Sprint 06: a still of any scene for review, not a test (asserts nothing).
##
##   godot --path <project> --resolution 405x720 \
##         res://tests/capture/scene_shot.tscn -- <scene path> <out.png> [frames]
##
## Uses the classic pair so scenes that need one (Home) have it.

func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("scene_shot: needs <scene path> <out.png> [frames]")
		get_tree().quit(1)
		return
	SaveManager.save_path = "user://captures/shot_save.json"
	DirAccess.make_dir_recursive_absolute("user://captures")
	var frames := int(args[2]) if args.size() > 2 else 30
	# Hand "current scene" to a placeholder so the change frees it, not this.
	var placeholder := Node.new()
	get_tree().root.add_child(placeholder)
	get_tree().current_scene = placeholder
	get_tree().change_scene_to_file(args[0])
	for i in frames:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(args[1])
	print("scene_shot: saved %s" % args[1])
	get_tree().quit(0)
