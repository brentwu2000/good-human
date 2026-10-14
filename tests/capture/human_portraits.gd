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
	# Adopter backgrounds with their own model: the background id.
	"office_worker": "office_worker",
	"market_auntie": "market_vendor",
	"retired_fisher": "retiree",
	"delivery_rider": "delivery_rider",
	"gym_coach": "gym_coach",
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


## A fighter file, or a person of that background in its first clothes colours.
func _fighter(source: String) -> FighterData:
	# "glb:<path>": the old master's data wearing another model (pipeline outputs).
	if source.begins_with("glb:"):
		var f := (load(FIGHTERS["grandma"]) as FighterData).duplicate() as FighterData
		f.skeletal_model = load(source.substr(4))
		return f
	if source.begins_with("res://"):
		return load(source)
	var human := HumanCandidate.new()
	human.background_id = StringName(source)
	var bg := human.background()
	human.shirt_color = bg.shirt_colors[0]
	human.pants_color = bg.pants_colors[0]
	return human.to_fighter_data("")


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
		puppet.apply(_fighter(FIGHTERS[key]))
		var body := puppet._body as P04HumanVisual
		if body != null:
			body.play_clip(body.ambient_clip(false), true)
		for i in 3:
			await get_tree().process_frame
		# Face views follow the head: from the neck to the top of the model, so
		# big-headed characters are framed as well as the owner (neck 1.49, top 1.76).
		var lift := 0.0
		var zoom := 1.0
		if body != null and body.skeleton != null and body.skeleton.find_bone("neck_01") >= 0:
			var neck := (body.skeleton.global_transform * body.skeleton.get_bone_global_pose(body.skeleton.find_bone("neck_01"))).origin.y
			var top := neck
			for mesh: MeshInstance3D in body.model.find_children("*", "MeshInstance3D", true, false):
				top = maxf(top, (mesh.global_transform * mesh.get_aabb()).end.y)
			lift = (neck + top) / 2.0 - 1.625
			zoom = clampf((top - neck) / 0.27, 0.6, 2.5)
		for view: Array in VIEWS:
			puppet.rotation.y = view[1]
			var is_face := String(view[0]).begins_with("face")
			var dy := Vector3(0, lift, 0) if is_face else Vector3.ZERO
			var target: Vector3 = view[3] + dy
			camera.position = target + ((view[2] as Vector3) - (view[3] as Vector3)) * (zoom if is_face else 1.0)
			camera.look_at(target, Vector3.UP)
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
