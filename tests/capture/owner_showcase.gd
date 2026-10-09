extends Node
## Owner, 2026-10-09: the owner's Mesh2Motion clips, captioned, side-on.
## A recording tool, not a test:
##
##   godot --path <project> --write-movie build/captures/owner.avi --fixed-fps 30 \
##         res://tests/capture/owner_showcase.tscn

const STEPS := [
	["打招呼（出門散步）", "M2M_Greeting", 1.4], ["勝利", "M2M_Victory", 1.0], ["撿東西", "M2M_PickUp", 1.3],
	["受傷時站著", "M2M_Idle_Hurt", 1.0], ["點頭", "M2M_Nod", 1.0], ["歡呼", "M2M_Cheer", 1.0], ["疲累", "M2M_Tired", 1.0],
]


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var tree := get_tree()
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
	environment.environment.ambient_light_energy = 0.7
	world.add_child(environment)
	var puppet := FighterPuppet3D.new()
	world.add_child(puppet)
	puppet.apply(preload("res://data/combat/fighters/player_human.tres"))
	puppet.rotation.y = -PI * 0.35
	var body := puppet._body as P04HumanVisual
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(0.6, 1.1, 3.4)
	camera.look_at(Vector3(0, 0.9, 0), Vector3.UP)
	camera.fov = 45.0
	camera.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	var caption := Label.new()
	caption.add_theme_font_size_override("font_size", 40)
	caption.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	caption.add_theme_constant_override("outline_size", 10)
	caption.position = Vector2(24, 18)
	layer.add_child(caption)
	for step: Array in STEPS:
		caption.text = "主人｜%s" % step[0]
		var name := body.m2m_clip(step[1])
		body.play_clip(name, false)
		body.player.speed_scale = step[2]
		for i in int(minf(body.player.get_animation(name).length / step[2], 3.5) * 30.0) + 15:
			await tree.process_frame
	tree.quit()
