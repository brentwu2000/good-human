class_name RunMap3D
extends Node3D
## 3D vertical slice level (P-02): a street, a path and a park entrance.
## Gameplay nodes (points, pairs, actors, managers) live in the scene; this
## script builds the greybox geometry and wires the dog camera. Geometry is
## placeholder until the 3D art kit exists.

const EnvironmentKit = preload("res://assets/environment/starter_kit/environment_kit_3d.gd")

@export var dog: DogController3D
@export var human: HumanFollower3D
@export var run_manager: RunManager
@export var coordinator: CombatCoordinator3D

var rig: CameraRig3D


func _ready() -> void:
	_build_environment()
	_build_street()
	_build_park()
	rig = CameraRig3D.new()
	add_child(rig)
	rig.dog = dog
	rig.owner_actor = human
	rig.coordinator = coordinator
	rig.snap_behind_dog()
	_build_bark_button()
	var agency := get_node_or_null("DogAgency")
	var hud := get_node_or_null("RunHUD")
	if agency != null and hud != null:
		agency.outcome.connect(func(text: String, positive: bool) -> void:
			hud.show_toast(text, Color(0.6, 1.0, 0.7) if positive else Color(1.0, 0.75, 0.6)))
	run_manager.run_started.connect(func(_s: int) -> void: human.say("好，出去散步吧！"))
	run_manager.loot_gained.connect(_on_loot_gained)


func _on_loot_gained(item: ItemData, _quantity: int) -> void:
	match item.rarity:
		ItemData.Rarity.RARE:
			human.say("哇！%s？！好狗狗！" % item.display_name, item.get_rarity_color(), 2.2)
		ItemData.Rarity.UNCOMMON:
			human.say("喔？這個不錯", item.get_rarity_color())
		_:
			human.say("嗯…收好了", Color(0.9, 0.9, 0.9), 1.0)


## Mobile: a bark button above the interact button (keyboard: Q).
func _build_bark_button() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	var button := TouchActionButton.new()
	button.name = "BarkButton"
	button.action = &"bark"
	button.text = "🐶 汪！"
	button.anchor_left = 1.0
	button.anchor_top = 1.0
	button.anchor_right = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = -200.0
	button.offset_top = -420.0
	button.offset_right = -60.0
	button.offset_bottom = -290.0
	button.add_theme_font_size_override("font_size", 30)
	layer.add_child(button)


# --- Greybox geometry -----------------------------------------------------------

func _build_environment() -> void:
	var world_env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.62, 0.75, 0.88)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.75, 0.75, 0.8)
	environment.ambient_light_energy = 0.6
	world_env.environment = environment
	add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)


func _build_street() -> void:
	add_child(Greybox.solid_box(Vector3(64, 0.2, 120), Color(0.45, 0.45, 0.47), Vector3(0, -0.1, -30)))
	add_child(Greybox.box(Vector3(64, 0.02, 7), Color(0.3, 0.3, 0.32), Vector3(0, 0.01, -2)))
	for x in range(-28, 29, 4):
		add_child(Greybox.box(Vector3(1.6, 0.03, 0.15), Color(0.9, 0.9, 0.85), Vector3(x, 0.02, -2)))
	# Low curbs: actors can step onto the sidewalks.
	add_child(Greybox.solid_box(Vector3(64, 0.05, 3), Color(0.7, 0.68, 0.64), Vector3(0, 0.025, 3)))
	add_child(Greybox.solid_box(Vector3(64, 0.05, 3), Color(0.7, 0.68, 0.64), Vector3(0, 0.025, -7)))
	for i in 5:
		add_child(EnvironmentKit.building(Vector3(9, 6, 6), Color(0.62 + 0.05 * (i % 2), 0.55, 0.5), Vector3(-24.0 + i * 12.0, 3, 8.5), i))
	# West blocks leave a 3 m alley at x = -14.5.
	for x in [-20.0, -9.0, 9.0, 19.0]:
		add_child(EnvironmentKit.building(Vector3(8, 5, 10), Color(0.55, 0.5, 0.48), Vector3(x, 2.5, -13.5), int(absf(x))))
	add_child(Greybox.box(Vector3(3, 0.02, 10), Color(0.4, 0.37, 0.33), Vector3(-14.5, 0.02, -13.5)))
	add_child(Greybox.box(Vector3(6, 0.02, 12), Color(0.62, 0.58, 0.5), Vector3(0, 0.02, -14)))
	for x in [-27.0, -15.0, -3.0, 9.0, 21.0]:
		add_child(EnvironmentKit.lamp(Vector3(x, 0.05, 4.0)))
	add_child(EnvironmentKit.bus_stop(Vector3(20, 0.05, 3.0)))
	# Map edges.
	for x in [-32.0, 32.0]:
		add_child(Greybox.solid_box(Vector3(1, 3, 120), Color(0.4, 0.4, 0.42), Vector3(x, 1.5, -30)))
	add_child(Greybox.solid_box(Vector3(64, 3, 1), Color(0.4, 0.4, 0.42), Vector3(0, 1.5, 12)))
	add_child(Greybox.solid_box(Vector3(64, 3, 1), Color(0.4, 0.4, 0.42), Vector3(0, 1.5, -70)))


func _build_park() -> void:
	add_child(Greybox.box(Vector3(62, 0.03, 50), Color(0.36, 0.55, 0.33), Vector3(0, 0.02, -45)))
	add_child(EnvironmentKit.park_gate(Vector3(0, 0, -20)))
	for p: Vector3 in [Vector3(-8, 0, -28), Vector3(10, 0, -31), Vector3(-7, 0, -43), Vector3(13, 0, -50), Vector3(-13, 0, -54), Vector3(4, 0, -58)]:
		if p == Vector3(-13, 0, -54):
			var banyan := BanyanLandmark3D.build(BanyanLandmark3D.TerritoryState.DISCOVERED)
			banyan.position = p
			add_child(banyan)
		else:
			add_child(EnvironmentKit.tree(p, 1.0 + 0.08 * fposmod(absf(p.x), 3.0)))
	for p: Vector3 in [Vector3(-3, 0, -30), Vector3(6, 0, -26), Vector3(-11, 0, -37), Vector3(9, 0, -41)]:
		add_child(EnvironmentKit.bush(p))
	add_child(EnvironmentKit.bench(Vector3(-2, 0, -36)))
	add_child(EnvironmentKit.bin(Vector3(2.4, 0, -36), EnvironmentKit.TEAL))
	for p: Vector3 in [Vector3(-5, 0, -24), Vector3(7, 0, -39), Vector3(-9, 0, -49)]:
		add_child(EnvironmentKit.lamp(p))
