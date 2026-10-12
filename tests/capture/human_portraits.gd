extends Node
## Character refinement review: every human fighter as the game builds it,
## front / three-quarter / side / back plus a face close-up, one PNG each.
## A review tool, not a test (asserts nothing). Needs a desktop session.
##
##   godot --path <project> --resolution 720x960 \
##         res://tests/capture/human_portraits.tscn -- <out dir> [fighter ...]

const FIGHTERS := {
	"owner": "res://data/combat/fighters/player_human.tres",
	"jogger": "res://data/combat/fighters/opp01_jogger.tres",
	"delivery": "res://data/combat/fighters/opp02_delivery.tres",
	"gym": "res://data/combat/fighters/opp03_gym.tres",
	"student": "res://data/combat/fighters/opp04_student.tres",
	"grandma": "res://data/combat/fighters/oppx01_old_master.tres",
}
## [name, puppet yaw (the puppet faces -Z at PI), camera position, look-at point, fov]
const VIEWS := [
	["front", PI, Vector3(0, 1.0, 3.6), Vector3(0, 0.9, 0), 40.0],
	["three_quarter", PI * 0.75, Vector3(0, 1.0, 3.6), Vector3(0, 0.9, 0), 40.0],
	["side", PI * 0.5, Vector3(0, 1.0, 3.6), Vector3(0, 0.9, 0), 40.0],
	["back", 0.0, Vector3(0, 1.0, 3.6), Vector3(0, 0.9, 0), 40.0],
	["face", PI, Vector3(0, 1.62, 1.1), Vector3(0, 1.58, 0), 26.0],
	["face_three_quarter", PI * 0.75, Vector3(0, 1.62, 1.1), Vector3(0, 1.58, 0), 26.0],
]


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir := args[0] if args.size() > 0 else "user://portraits"
	var wanted: Array = Array(args.slice(1)) if args.size() > 1 else FIGHTERS.keys()
	DirAccess.make_dir_recursive_absolute(out_dir)
	var world := Node3D.new()
	add_child(world)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20, 20)
	ground.mesh = plane
	ground.material_override = Greybox.material(Color(0.62, 0.62, 0.60))
	world.add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 25, 0)
	sun.shadow_enabled = true
	world.add_child(sun)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.80, 0.84, 0.88)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.9, 0.9, 0.95)
	environment.environment.ambient_light_energy = 0.6
	world.add_child(environment)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.make_current()
	for key: String in wanted:
		var puppet := FighterPuppet3D.new()
		world.add_child(puppet)
		puppet.apply(load(FIGHTERS[key]))
		var body := puppet._body as P04HumanVisual
		if body != null:
			body.play_clip(body.ambient_clip(false), true)
		for view: Array in VIEWS:
			puppet.rotation.y = view[1]
			camera.position = view[2]
			camera.look_at(view[3], Vector3.UP)
			camera.fov = view[4]
			for i in 6:
				await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var path := "%s/%s_%s.png" % [out_dir, key, view[0]]
			get_viewport().get_texture().get_image().save_png(path)
			print("human_portraits: saved %s" % path)
		puppet.queue_free()
		await get_tree().process_frame
	get_tree().quit(0)
