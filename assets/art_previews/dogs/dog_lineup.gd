extends Node3D
## ART-only review of the breed-sheet dogs (AI 3D dog factory). Not in any build
## (export_presets exclude assets/art_previews/*). Every GLB in models/ stands in a
## row on the shared shiba rig.
##   ui_accept: next clip (Idle → Walk → Sit)   ui_select: soft toon on/off
##   ui_left / ui_right: orbit                  ui_up / ui_down: zoom
## Run with `-- --capture <png>` to save one frame and quit.
const MODEL_DIR := "res://assets/art_previews/dogs/models/"
const CLIPS := ["Idle", "Walk", "Sit"]
const NAMES := {
	"shiba": "柴犬", "poodle": "貴賓犬", "corgi": "柯基犬", "golden": "黃金獵犬",
	"frenchie": "法國鬥牛犬", "chihuahua": "吉娃娃", "pomeranian": "博美犬",
}
const ORDER := ["chihuahua", "pomeranian", "poodle", "frenchie", "corgi", "shiba", "golden"]
const SPACING := 0.85

var dogs: Array[Node3D] = []
var players: Array[AnimationPlayer] = []
var camera: Camera3D
var label: Label
var clip_index := 0
var yaw := -30.0
var distance := 4.2
var toon := false


func _ready() -> void:
	get_viewport().msaa_3d = Viewport.MSAA_2X
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("c9d3d6")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("e2e6e4")
	env.environment.ambient_light_energy = 0.75
	add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_color = Color("fff0d8")
	light.shadow_enabled = true
	add_child(light)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(14, 8)
	ground.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("8b8d80")
	ground.material_override = mat
	add_child(ground)
	var found := _model_names()
	var x := -SPACING * (found.size() - 1) / 2.0
	for breed in found:
		var scene := load(MODEL_DIR + breed + ".glb") as PackedScene
		if scene == null:
			continue
		var dog := scene.instantiate() as Node3D
		dog.position = Vector3(x, 0, 0)
		add_child(dog)
		SoftToon.register(dog)
		dogs.append(dog)
		var player := dog.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if player:
			players.append(player)
		var tag := Label3D.new()
		tag.text = NAMES.get(breed, breed)
		tag.font_size = 48
		tag.pixel_size = 0.0016
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tag.position = Vector3(x, 0.8, 0)
		add_child(tag)
		x += SPACING
	camera = Camera3D.new()
	camera.fov = 40
	add_child(camera)
	label = Label.new()
	label.position = Vector2(16, 12)
	label.add_theme_font_size_override("font_size", 20)
	var layer := CanvasLayer.new()
	layer.add_child(label)
	add_child(layer)
	distance = maxf(1.8, dogs.size() * 0.75 + 1.0)
	_play()
	_place_camera()
	var args := OS.get_cmdline_user_args()
	var at := args.find("--capture")
	if at >= 0 and at + 1 < args.size():
		_capture(args[at + 1])


func _model_names() -> Array[String]:
	var names: Array[String] = []
	for breed in ORDER:
		if ResourceLoader.exists(MODEL_DIR + breed + ".glb"):
			names.append(breed)
	return names


func _play() -> void:
	var clip: String = CLIPS[clip_index]
	for player in players:
		if player.has_animation(clip):
			var anim := player.get_animation(clip)
			anim.loop_mode = Animation.LOOP_NONE if clip == "Sit" else Animation.LOOP_LINEAR
			player.play(clip)
	label.text = "犬種預覽（%d 隻）  動作：%s  卡通：%s\nEnter 換動作 · Space 卡通 · ←→ 旋轉 · ↑↓ 遠近" % [
		dogs.size(), clip, "開" if toon else "關"]


func _place_camera() -> void:
	var r := deg_to_rad(yaw)
	camera.position = Vector3(sin(r) * distance, 0.25 + distance * 0.22, cos(r) * distance)
	camera.look_at(Vector3(0, 0.3, 0))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		clip_index = (clip_index + 1) % CLIPS.size()
		_play()
	elif event.is_action_pressed("ui_select"):
		toon = not toon
		SoftToon.set_enabled(get_tree(), toon)
		_play()


func _process(delta: float) -> void:
	var turn := Input.get_axis("ui_left", "ui_right")
	var zoom := Input.get_axis("ui_up", "ui_down")
	if turn != 0.0 or zoom != 0.0:
		yaw += turn * 60.0 * delta
		distance = clampf(distance + zoom * 2.0 * delta, 1.5, 8.0)
		_place_camera()


func _capture(path: String) -> void:
	for i in 30:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("DOG_LINEUP_CAPTURE ", path)
	get_tree().quit()
