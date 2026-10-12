extends Node
## Still evidence alongside the unchanged Movie Maker showcase/fight scenes.
var folder: String
var frame := 0
var busy := false
func _enter_tree() -> void:
	seed(1234)
	var args := OS.get_cmdline_user_args()
	var at := args.find("--art-output")
	assert(at >= 0 and at + 1 < args.size())
	folder = args[at + 1]
	DirAccess.make_dir_recursive_absolute(folder)
func _process(_delta: float) -> void:
	frame += 1
	if frame % 30 != 0 or busy: return
	busy = true
	await RenderingServer.frame_post_draw
	var result := get_viewport().get_texture().get_image().save_png(folder + "/%04d.png" % frame)
	assert(result == OK)
	busy = false
