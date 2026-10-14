extends Node
## Texturing v5 stage G: any GLB in Godot, front/back/left/right/three-quarter,
## same light and framing. A review tool, not a test.
##
##   godot --path <project> --resolution 640x640 res://tests/capture/model_turnaround.tscn -- <res://model.glb> <out dir> [prefix]

func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var scene := load(args[0]) as PackedScene
	var out_dir := args[1]
	var prefix := args[2] if args.size() > 2 else "godot"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var world := Node3D.new()
	add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.80, 0.84, 0.88)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.9, 0.9, 0.95)
	env.environment.ambient_light_energy = 0.6
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 25, 0)
	world.add_child(sun)
	var model := scene.instantiate() as Node3D
	world.add_child(model)
	var aabb := AABB()
	var first := true
	for m: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		var b := m.global_transform * m.get_aabb()
		aabb = b if first else aabb.merge(b)
		first = false
	var centre := aabb.get_center()
	var size := maxf(aabb.size.y, maxf(aabb.size.x, aabb.size.z))
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = size * 1.15
	world.add_child(cam)
	cam.make_current()
	for view: Array in [["front", 0.0], ["back", 180.0], ["left", 90.0], ["right", -90.0], ["three_quarter", 45.0]]:
		var t := deg_to_rad(view[1])
		cam.position = centre + Vector3(sin(t), 0, cos(t)) * size * 3.0
		cam.look_at(centre, Vector3.UP)
		for i in 4:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s_%s.png" % [out_dir, prefix, view[0]])
	get_tree().quit(0)
