class_name P01World
extends Node3D
## P-01 DOG EYE CAMERA greybox: street, sidewalk, park entrance, trees and
## bushes, a searchable trash can, dog + owner + leash, an opponent pair and
## a squirrel. Switch cameras with 1/2/3 or the on-screen buttons.
## Isolated experiment: nothing here is used by production scenes.

const TOUCH_CONTROLS: PackedScene = preload("res://ui/hud/touch_controls.tscn")
const DOG_START: Vector3 = Vector3(0, 0.2, 3.0)

var dog: ProtoDog
var owner_actor: ProtoOwner
var opponent: ProtoOpponent
var squirrel: ProtoSquirrel
var search_spot: ProtoSearchSpot
var rig: ProtoCameraRig

var _info: Label
var _hint: Label


func _ready() -> void:
	_build_environment()
	_build_street()
	_build_park()
	_spawn_actors()
	_build_ui()
	set_variant(ProtoCameraRig.Variant.A_TOP_DOWN)
	print("P-01 DOG EYE CAMERA greybox ready")


func set_variant(value: ProtoCameraRig.Variant) -> void:
	rig.set_variant(value)
	rig.snap()


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("proto_cam_a"):
		set_variant(ProtoCameraRig.Variant.A_TOP_DOWN)
	elif Input.is_action_just_pressed("proto_cam_b"):
		set_variant(ProtoCameraRig.Variant.B_DOG_CHASE)
	elif Input.is_action_just_pressed("proto_cam_c"):
		set_variant(ProtoCameraRig.Variant.C_HYBRID)
	if Input.is_action_just_pressed("interact"):
		interact()
	_update_info()


## Context action: sniff the trash can or provoke the pair, whichever is near.
func interact() -> void:
	if search_spot.start():
		return
	opponent.provoke()


func reset_scene() -> void:
	dog.global_position = DOG_START
	dog.velocity = Vector3.ZERO
	dog.sniffing = false
	owner_actor.set_state(ProtoOwner.State.FOLLOW)
	owner_actor.global_position = DOG_START + Vector3(1.2, 0, 0.9)
	opponent.reset()
	squirrel.reset()
	search_spot.reset()
	rig.yaw = 0.0
	rig.snap()


# --- Greybox ------------------------------------------------------------------

func _build_environment() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.62, 0.75, 0.88)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.75, 0.75, 0.8)
	environment.ambient_light_energy = 0.6
	env.environment = environment
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)


func _build_street() -> void:
	# Ground and road (world layer so the camera can collide with it).
	add_child(ProtoShapes.solid_box(Vector3(60, 0.2, 110), Color(0.45, 0.45, 0.47), Vector3(0, -0.1, -25)))
	add_child(ProtoShapes.box(Vector3(60, 0.02, 7), Color(0.3, 0.3, 0.32), Vector3(0, 0.01, -2)))
	for x in range(-26, 27, 4):
		add_child(ProtoShapes.box(Vector3(1.6, 0.03, 0.15), Color(0.9, 0.9, 0.85), Vector3(x, 0.02, -2)))
	# Sidewalks.
	add_child(ProtoShapes.solid_box(Vector3(60, 0.15, 3), Color(0.7, 0.68, 0.64), Vector3(0, 0.075, 3)))
	add_child(ProtoShapes.solid_box(Vector3(60, 0.15, 3), Color(0.7, 0.68, 0.64), Vector3(0, 0.075, -7)))
	# House fronts behind the near sidewalk, and blocks along the far one.
	for i in 5:
		var x := -24.0 + i * 12.0
		add_child(ProtoShapes.solid_box(Vector3(9, 6, 6), Color(0.62 + 0.05 * (i % 2), 0.55, 0.5), Vector3(x, 3, 8.5)))
	for x in [-18.0, -9.0, 9.0, 18.0]:
		add_child(ProtoShapes.solid_box(Vector3(7, 5, 10), Color(0.55, 0.5, 0.48), Vector3(x, 2.5, -13.5)))
	# Path to the park between the far blocks.
	add_child(ProtoShapes.box(Vector3(6, 0.02, 12), Color(0.62, 0.58, 0.5), Vector3(0, 0.02, -14)))
	search_spot = ProtoSearchSpot.new()
	search_spot.position = Vector3(3.5, 0.15, 3.2)
	add_child(search_spot)
	add_child(ProtoShapes.solid_box(Vector3(0.9, 1.2, 0.5), Color(0.8, 0.3, 0.3), Vector3(-4, 0.75, 3.5)))


func _build_park() -> void:
	add_child(ProtoShapes.box(Vector3(60, 0.03, 50), Color(0.36, 0.55, 0.33), Vector3(0, 0.02, -45)))
	# Park entrance gate.
	for x in [-3.2, 3.2]:
		add_child(ProtoShapes.solid_box(Vector3(0.5, 2.6, 0.5), Color(0.5, 0.45, 0.4), Vector3(x, 1.3, -20)))
	add_child(ProtoShapes.box(Vector3(7, 0.4, 0.4), Color(0.45, 0.35, 0.3), Vector3(0, 2.8, -20)))
	var trees := [Vector3(-8, 0, -28), Vector3(9, 0, -32), Vector3(-6, 0, -42), Vector3(12, 0, -48), Vector3(-12, 0, -52), Vector3(3, 0, -55)]
	for p: Vector3 in trees:
		var trunk := ProtoShapes.solid_box(Vector3(0.5, 3.0, 0.5), Color(0.4, 0.28, 0.18), p + Vector3(0, 1.5, 0))
		add_child(trunk)
		add_child(ProtoShapes.sphere(2.0, Color(0.25, 0.45, 0.22), p + Vector3(0, 3.8, 0)))
	var bushes := [Vector3(-3, 0, -30), Vector3(5, 0, -26), Vector3(-10, 0, -36), Vector3(7, 0, -40)]
	for p: Vector3 in bushes:
		add_child(ProtoShapes.sphere(0.9, Color(0.3, 0.5, 0.25), p + Vector3(0, 0.6, 0)))
	add_child(ProtoShapes.solid_box(Vector3(2.2, 0.5, 0.7), Color(0.55, 0.38, 0.25), Vector3(-2, 0.25, -36)))


func _spawn_actors() -> void:
	dog = ProtoDog.new()
	dog.position = DOG_START
	add_child(dog)
	owner_actor = ProtoOwner.new()
	owner_actor.position = DOG_START + Vector3(1.2, 0, 0.9)
	owner_actor.dog = dog
	add_child(owner_actor)
	opponent = ProtoOpponent.new()
	opponent.position = Vector3(5, 0, -38)
	add_child(opponent)
	opponent.dog = dog
	opponent.owner_actor = owner_actor
	squirrel = ProtoSquirrel.new()
	squirrel.position = Vector3(-7, 0, -45)
	add_child(squirrel)
	squirrel.dog = dog
	search_spot.dog = dog
	rig = ProtoCameraRig.new()
	add_child(rig)
	rig.dog = dog
	rig.owner_actor = owner_actor
	rig.opponent = opponent


# --- UI -------------------------------------------------------------------------

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var touch := TOUCH_CONTROLS.instantiate() as Control
	layer.add_child(touch)
	(touch.get_node("%InteractButton") as Button).text = "聞／挑釁"
	(touch.get_node("%InteractButton") as Button).disabled = false

	_info = Label.new()
	_info.position = Vector2(16, 16)
	_info.add_theme_font_size_override("font_size", 22)
	_info.add_theme_color_override("font_outline_color", Color.BLACK)
	_info.add_theme_constant_override("outline_size", 6)
	layer.add_child(_info)

	var bar := HFlowContainer.new()
	bar.position = Vector2(16, 175)
	bar.size = Vector2(688, 130)
	layer.add_child(bar)
	for i in 3:
		_button(bar, ["A", "B", "C"][i], func() -> void: set_variant(i))
	for spec: Array in [["高+", "pivot", 0.2], ["高-", "pivot", -0.2], ["距+", "distance", 0.5], ["距-", "distance", -0.5],
			["俯+", "pitch", -4.0], ["俯-", "pitch", 4.0], ["FOV+", "fov", 4.0], ["FOV-", "fov", -4.0]]:
		_button(bar, spec[0], func() -> void: rig.tuning[spec[1]] += spec[2])
	_button(bar, "調整歸零", func() -> void: rig.tuning = {"pivot": 0.0, "pitch": 0.0, "distance": 0.0, "fov": 0.0})
	_button(bar, "重來", reset_scene)

	_hint = Label.new()
	_hint.position = Vector2(16, 850)
	_hint.add_theme_font_size_override("font_size", 20)
	_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	_hint.add_theme_constant_override("outline_size", 6)
	_hint.text = "WASD／搖桿移動・Shift 或推到底衝刺・E 聞垃圾桶／挑釁\n1/2/3 切換鏡頭　公園裡有松鼠和一組人狗"
	layer.add_child(_hint)


func _button(parent: Control, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(76, 56)
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(action)
	parent.add_child(button)


func _update_info() -> void:
	var c := rig.current
	if c.is_empty():
		return
	var fight_distance := dog.global_position.distance_to(opponent.human_position())
	_info.text = "鏡頭 %s　情境 %s\n高 %.2f 距 %.1f 俯 %.0f° FOV %.0f%s\n狗速 %.1f m/s　主人距離 %.1f m\n對手距離 %.1f m　脫戰 %.0f m　狀態 %s" % [
		ProtoCameraRig.VARIANT_NAMES[rig.variant], rig.context,
		c["pivot"], c["distance"], c["pitch"], c["fov"], "（撞牆拉近）" if rig.collided else "",
		dog.planar_speed(), dog.global_position.distance_to(owner_actor.global_position),
		fight_distance, ProtoOpponent.DISENGAGE_DISTANCE, ProtoOpponent.State.keys()[opponent.state],
	]
