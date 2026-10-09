extends Node
## Owner, 2026-10-09: the dogs' Mesh2Motion clips, side-on, four breeds (big
## ones behind, small in front), captioned. A recording tool, not a test:
##
##   godot --path <project> --write-movie build/captures/dogs.avi --fixed-fps 30 \
##         res://tests/capture/dog_showcase.tscn

const BREEDS: Array[String] = [
	"res://assets/characters/dog/models/breeds/golden.glb",
	"res://assets/characters/dog/models/shiba_01/shiba_01.glb",
	"res://assets/characters/dog/models/breeds/corgi.glb",
	"res://assets/characters/dog/models/breeds/chihuahua.glb",
]
const STEPS := [
	["走路（原本的）", "Walk", 2.0],
	["奔跑", "m2m/M2M_Run", 2.5],
	["低頭聞", "m2m/M2M_Fetch", 2.4],
	["吠叫", "m2m/M2M_Bark", 2.4],
	["警戒（主人有危險）", "m2m/M2M_Alert", 2.4],
	["潛行", "m2m/M2M_Sneak", 2.4],
	["跳", "m2m/M2M_Jump", 2.0],
	["嚎叫", "m2m/M2M_Howl", 2.4],
	["坐下（原本的）", "Sit", 2.0],
]

var _tree: SceneTree


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_tree = get_tree()
	var world := Node3D.new()
	add_child(world)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20, 20)
	ground.mesh = plane
	ground.material_override = Greybox.material(Color(0.45, 0.62, 0.38))
	world.add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.shadow_enabled = true
	world.add_child(sun)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.72, 0.84, 0.95)
	environment.environment.ambient_light_color = Color(0.8, 0.8, 0.85)
	environment.environment.ambient_light_energy = 0.7
	world.add_child(environment)
	var players: Array[AnimationPlayer] = []
	for i in BREEDS.size():
		var model := (load(BREEDS[i]) as PackedScene).instantiate() as Node3D
		world.add_child(model)
		# Two rows, the big dogs behind, all side-on facing the same way.
		model.position = Vector3(-0.7 if i < 2 else 0.5, 0, -0.45 + (i % 2) * 0.95)
		model.rotation.y = DogController3D.MODEL_YAW
		var motion := DogModelMotion3D.new()
		world.add_child(motion)
		motion.bind(model)
		motion.set_process(false)
		players.append(motion._player)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(2.6, 1.1, 0.05)
	camera.look_at(Vector3(0, 0.25, 0.05), Vector3.UP)
	camera.fov = 45.0
	camera.make_current()
	var caption := _caption()
	for step: Array in STEPS:
		caption.text = "狗｜%s" % step[0]
		for player in players:
			if player.has_animation(step[1]):
				var clip := player.get_animation(step[1])
				clip.loop_mode = Animation.LOOP_LINEAR if step[1] != "Sit" else Animation.LOOP_NONE
				player.speed_scale = 1.0
				player.play(step[1], 0.15)
		for i in int(step[2] * 30.0):
			await _tree.process_frame
	_tree.quit()


func _caption() -> Label:
	var layer := CanvasLayer.new()
	add_child(layer)
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 10)
	label.position = Vector2(24, 18)
	layer.add_child(label)
	return label
