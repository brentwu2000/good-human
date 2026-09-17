class_name RunMap3D
extends Node3D
## 3D vertical slice level (P-02): a street, a path and a park entrance.
## Gameplay nodes (points, pairs, actors, managers) live in the scene; this
## script builds the greybox geometry, wires the camera and adds the view
## switch button. Geometry is placeholder until the 3D art kit exists.

@export var dog: DogController3D
@export var human: HumanFollower3D
@export var run_manager: RunManager
@export var coordinator: CombatCoordinator3D

var rig: CameraRig3D

var _view_button: Button


func _ready() -> void:
	_build_environment()
	_build_street()
	_build_park()
	rig = CameraRig3D.new()
	add_child(rig)
	rig.dog = dog
	rig.owner_actor = human
	rig.coordinator = coordinator
	rig.view_changed.connect(_on_view_changed)
	_build_view_button()
	rig.set_view(CameraRig3D.View.DOG)
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


func _on_view_changed(view: CameraRig3D.View) -> void:
	_view_button.text = "👁 %s" % CameraRig3D.VIEW_NAMES[view]


func _build_view_button() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 3
	add_child(layer)
	_view_button = Button.new()
	_view_button.name = "ViewButton"
	_view_button.focus_mode = Control.FOCUS_NONE
	_view_button.anchor_left = 1.0
	_view_button.anchor_right = 1.0
	_view_button.offset_left = -220.0
	_view_button.offset_right = -24.0
	_view_button.offset_top = 110.0
	_view_button.offset_bottom = 180.0
	_view_button.add_theme_font_size_override("font_size", 28)
	_view_button.pressed.connect(rig.toggle)
	layer.add_child(_view_button)


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
	var fade_top := Greybox.FADE_TOP_DOWN_GROUP
	add_child(Greybox.solid_box(Vector3(64, 0.2, 120), Color(0.45, 0.45, 0.47), Vector3(0, -0.1, -30)))
	add_child(Greybox.box(Vector3(64, 0.02, 7), Color(0.3, 0.3, 0.32), Vector3(0, 0.01, -2)))
	for x in range(-28, 29, 4):
		add_child(Greybox.box(Vector3(1.6, 0.03, 0.15), Color(0.9, 0.9, 0.85), Vector3(x, 0.02, -2)))
	# Low curbs: actors can step onto the sidewalks.
	add_child(Greybox.solid_box(Vector3(64, 0.05, 3), Color(0.7, 0.68, 0.64), Vector3(0, 0.025, 3)))
	add_child(Greybox.solid_box(Vector3(64, 0.05, 3), Color(0.7, 0.68, 0.64), Vector3(0, 0.025, -7)))
	for i in 5:
		add_child(Greybox.solid_box(Vector3(9, 6, 6), Color(0.62 + 0.05 * (i % 2), 0.55, 0.5), Vector3(-24.0 + i * 12.0, 3, 8.5), fade_top))
	for x in [-19.0, -9.0, 9.0, 19.0]:
		add_child(Greybox.solid_box(Vector3(8, 5, 10), Color(0.55, 0.5, 0.48), Vector3(x, 2.5, -13.5), fade_top))
	add_child(Greybox.box(Vector3(6, 0.02, 12), Color(0.62, 0.58, 0.5), Vector3(0, 0.02, -14)))
	# Map edges.
	for x in [-32.0, 32.0]:
		add_child(Greybox.solid_box(Vector3(1, 3, 120), Color(0.4, 0.4, 0.42), Vector3(x, 1.5, -30)))
	add_child(Greybox.solid_box(Vector3(64, 3, 1), Color(0.4, 0.4, 0.42), Vector3(0, 1.5, 12)))
	add_child(Greybox.solid_box(Vector3(64, 3, 1), Color(0.4, 0.4, 0.42), Vector3(0, 1.5, -70)))


func _build_park() -> void:
	add_child(Greybox.box(Vector3(62, 0.03, 50), Color(0.36, 0.55, 0.33), Vector3(0, 0.02, -45)))
	for x in [-3.2, 3.2]:
		add_child(Greybox.solid_box(Vector3(0.5, 2.6, 0.5), Color(0.5, 0.45, 0.4), Vector3(x, 1.3, -20)))
	add_child(Greybox.box(Vector3(7, 0.4, 0.4), Color(0.45, 0.35, 0.3), Vector3(0, 2.8, -20)))
	for p: Vector3 in [Vector3(-8, 0, -28), Vector3(10, 0, -31), Vector3(-7, 0, -43), Vector3(13, 0, -50), Vector3(-13, 0, -54), Vector3(4, 0, -58)]:
		add_child(Greybox.tree(p))
	for p: Vector3 in [Vector3(-3, 0, -30), Vector3(6, 0, -26), Vector3(-11, 0, -37), Vector3(9, 0, -41)]:
		var bush := Greybox.solid_box(Vector3(1.6, 1.2, 1.6), Color(0.3, 0.5, 0.25), p + Vector3(0, 0.6, 0), Greybox.FADE_GROUP)
		add_child(bush)
	add_child(Greybox.solid_box(Vector3(2.2, 0.5, 0.7), Color(0.55, 0.38, 0.25), Vector3(-2, 0.25, -36)))
