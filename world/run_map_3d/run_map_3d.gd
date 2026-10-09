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
## S05-03: the walk's tension, shown as the light turning towards evening and
## home calling more strongly.
var tension: RunTensionDirector
var atmosphere: CombatAtmosphere3D

const DAY_SKY := Color(0.62, 0.75, 0.88)
const EVENING_SKY := Color(0.9, 0.7, 0.56)
const DAY_AMBIENT := Color(0.75, 0.75, 0.8)
const EVENING_AMBIENT := Color(0.8, 0.68, 0.62)
const EVENING_SUN := Color(1.0, 0.8, 0.6)
## The sky overhead and at the horizon, day and evening (the walk's haze is
## the horizon colour).
const DAY_SKY_TOP := Color(0.36, 0.56, 0.82)
const EVENING_SKY_TOP := Color(0.4, 0.42, 0.62)
const DAY_HORIZON := Color(0.78, 0.84, 0.9)
const EVENING_HORIZON := Color(0.96, 0.72, 0.52)
const SKYLINE := preload("res://assets/environment/walk_kit/skyline.glb")
var _environment: Environment
var _sun: DirectionalLight3D
var _sky: ProceduralSkyMaterial


func _ready() -> void:
	_build_environment()
	_build_street()
	_build_street_clutter()
	_build_park()
	rig = CameraRig3D.new()
	add_child(rig)
	rig.dog = dog
	rig.owner_actor = human
	rig.coordinator = coordinator
	# The view shakes when a punch lands (Core Experience Gate 02 feel pass).
	coordinator.camera = rig
	rig.snap_behind_dog()
	_build_bark_button()
	# D4/P02-009: the dog's read of danger to its owner, shown in its body.
	var instinct := DogInstinct.new()
	instinct.name = "DogInstinct"
	instinct.dog = dog
	instinct.coordinator = coordinator
	add_child(instinct)
	tension = RunTensionDirector.new()
	tension.name = "RunTensionDirector"
	tension.run_manager = run_manager
	tension.dog = dog
	tension.temptation_director = get_node_or_null("TemptationDirector") as TemptationDirector
	add_child(tension)
	tension.tension_changed.connect(_apply_tension)
	var agency := get_node_or_null("DogAgency")
	# P03-E09: sound and the world's reaction around a fight.
	atmosphere = CombatAtmosphere3D.new()
	atmosphere.name = "CombatAtmosphere"
	atmosphere.coordinator = coordinator
	atmosphere.rig = rig
	atmosphere.dog = dog
	atmosphere.agency = agency
	atmosphere.instinct = instinct
	add_child(atmosphere)
	var hud := get_node_or_null("RunHUD")
	if agency != null and hud != null:
		agency.outcome.connect(func(text: String, positive: bool) -> void:
			# P04-11: explaining the fight in words is debug-only.
			if FighterPuppet3D.show_combat_text:
				hud.show_toast(text, Color(0.6, 1.0, 0.7) if positive else Color(1.0, 0.75, 0.6)))
	if hud != null:
		_voice_territories(hud)
	run_manager.run_started.connect(_greet)
	run_manager.loot_gained.connect(_on_loot_gained)
	# P05-10: finds to fight with are left lying where they were found, and
	# whatever the owner holds is in their hand on the walk too.
	run_manager.weapon_found.connect(_lay_down_weapon)
	run_manager.weapon_changed.connect(func(weapon: WeaponData) -> void:
		human.puppet.hold(weapon, run_manager.equipped_state()))


## S06-08: how the human sets off with their dog says how close they are.
func _greet(_seed: int) -> void:
	if not Game.has_pair():
		human.say("好，出去散步吧！")
		human.puppet.play_gesture("M2M_Greeting", 1.4)
		return
	# S06-10: the very first walk remembers how they met.
	var first := Memories.recall_for(Game.pair_state, &"shelter")
	if int(SaveManager.data["statistics"]["runs"]) == 0 and not first.is_empty():
		human.say(str(first["recall"]))
	else:
		human.say(Bond.greeting(Game.pair_state))
	if Bond.pets_before_walk(Game.pair_state):
		human.puppet.play_acknowledge(dog.global_position)
		dog.play_petted()
	else:
		# Off we go: a wave to the dog (Mesh2Motion "Greeting").
		human.puppet.play_gesture("M2M_Greeting", 1.4)


## S05-05: what the dog makes of a place is said in the walk, in its own voice,
## the same way as the walk's temptations.
func _voice_territories(hud: Node) -> void:
	var voice := Color(1.0, 0.92, 0.66)
	for node in get_tree().get_nodes_in_group(TerritoryPoint3D.GROUP):
		var point := node as TerritoryPoint3D
		if not is_ancestor_of(point):
			continue
		point.discovered.connect(func(t: TerritoryData) -> void: hud.show_toast(t.discovered_text, voice, true))
		point.rival_scent_found.connect(func(t: TerritoryData) -> void: hud.show_toast(t.rival_scent_text, voice, true))
		point.scents_read.connect(func(_t: TerritoryData, text: String) -> void: hud.show_toast(text, voice))
		point.marked.connect(func(t: TerritoryData) -> void: hud.show_toast(t.marked_text, voice))
		point.reward_found.connect(func(t: TerritoryData, _item: ItemData) -> void: hud.show_toast(t.reward_found_text, voice, true))


## Presentation only: the mood of the walk, never its rules.
func _apply_tension(level: float) -> void:
	_environment.background_color = DAY_SKY.lerp(EVENING_SKY, level)
	_sky.sky_top_color = DAY_SKY_TOP.lerp(EVENING_SKY_TOP, level)
	_sky.sky_horizon_color = DAY_HORIZON.lerp(EVENING_HORIZON, level)
	_sky.ground_horizon_color = _sky.sky_horizon_color
	_environment.fog_light_color = _sky.sky_horizon_color
	_environment.ambient_light_color = DAY_AMBIENT.lerp(EVENING_AMBIENT, level)
	_sun.light_color = Color.WHITE.lerp(EVENING_SUN, level)
	_sun.light_energy = lerpf(1.1, 0.95, level)
	for node in get_tree().get_nodes_in_group(ExtractionPoint.GROUP):
		var point := node as ExtractionPoint3D
		if point != null:
			point.set_call(level)


func _lay_down_weapon(stack: ItemStack, at: Vector3) -> void:
	var found := WorldWeapon3D.new()
	found.setup(stack, run_manager, human)
	add_child(found)
	# In front of the spot, on the ground, where the dog can stand over it.
	found.global_position = Vector3(at.x, 0.0, at.z) + Vector3(0.0, 0.0, 0.9)
	human.say("（%s——這個好像能用？）" % stack.item.display_name, Color(1.0, 0.95, 0.8), 2.0)


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
	# A real sky and a light haze over the distance, instead of a flat colour
	# (Claude, art at the owner's request 2026-10-07). The city beyond the
	# map's edges stands in that haze.
	environment.background_mode = Environment.BG_SKY
	environment.background_color = DAY_SKY
	_sky = ProceduralSkyMaterial.new()
	_sky.sky_top_color = DAY_SKY_TOP
	_sky.sky_horizon_color = DAY_HORIZON
	_sky.ground_horizon_color = DAY_HORIZON
	_sky.ground_bottom_color = Color(0.4, 0.42, 0.4)
	_sky.sun_angle_max = 20.0
	environment.sky = Sky.new()
	environment.sky.sky_material = _sky
	environment.fog_enabled = true
	environment.fog_light_color = DAY_HORIZON
	environment.fog_density = 0.003
	environment.fog_sky_affect = 0.0
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.75, 0.75, 0.8)
	environment.ambient_light_energy = 0.6
	world_env.environment = environment
	add_child(world_env)
	_environment = environment
	add_child(SKYLINE.instantiate())
	var sun := DirectionalLight3D.new()
	_sun = sun
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)


func _build_street() -> void:
	# The ground's look is GroundMaterials (generated, world-space); the boxes
	# and their collision are unchanged.
	var ground := Greybox.solid_box(Vector3(64, 0.2, 120), Color(0.45, 0.45, 0.47), Vector3(0, -0.1, -30))
	GroundMaterials.apply(ground, GroundMaterials.concrete())
	add_child(ground)
	var road := Greybox.box(Vector3(64, 0.02, 7), Color(0.3, 0.3, 0.32), Vector3(0, 0.01, -2))
	GroundMaterials.apply(road, GroundMaterials.asphalt())
	add_child(road)
	for x in range(-28, 29, 4):
		add_child(Greybox.box(Vector3(1.6, 0.03, 0.15), Color(0.9, 0.9, 0.85), Vector3(x, 0.02, -2)))
	# Low curbs: actors can step onto the sidewalks.
	for z in [3.0, -7.0]:
		var walk := Greybox.solid_box(Vector3(64, 0.05, 3), Color(0.7, 0.68, 0.64), Vector3(0, 0.025, z))
		GroundMaterials.apply(walk, GroundMaterials.pavers())
		add_child(walk)
	for i in 5:
		add_child(EnvironmentKit.building(Vector3(9, 6, 6), Color(0.62 + 0.05 * (i % 2), 0.55, 0.5), Vector3(-24.0 + i * 12.0, 3, 8.5), i))
	# West blocks leave a 3 m alley at x = -14.5.
	for x in [-20.0, -9.0, 9.0, 19.0]:
		add_child(EnvironmentKit.building(Vector3(8, 5, 10), Color(0.55, 0.5, 0.48), Vector3(x, 2.5, -13.5), int(absf(x))))
	var alley := Greybox.box(Vector3(3, 0.02, 10), Color(0.4, 0.37, 0.33), Vector3(-14.5, 0.02, -13.5))
	GroundMaterials.apply(alley, GroundMaterials.asphalt())
	add_child(alley)
	var approach := Greybox.box(Vector3(6, 0.02, 12), Color(0.62, 0.58, 0.5), Vector3(0, 0.02, -14))
	GroundMaterials.apply(approach, GroundMaterials.pavers())
	add_child(approach)
	for x in [-27.0, -15.0, -3.0, 9.0, 21.0]:
		add_child(EnvironmentKit.lamp(Vector3(x, 0.05, 4.0)))
	add_child(EnvironmentKit.bus_stop(Vector3(20, 0.05, 3.0)))
	_add_rest_spot(&"RestBusStop", Vector3(20, 0, 3.0))
	# Map edges.
	var edges: Array[StaticBody3D] = [
		Greybox.solid_box(Vector3(1, 3, 120), Color(0.4, 0.4, 0.42), Vector3(-32, 1.5, -30)),
		Greybox.solid_box(Vector3(1, 3, 120), Color(0.4, 0.4, 0.42), Vector3(32, 1.5, -30)),
		Greybox.solid_box(Vector3(64, 3, 1), Color(0.4, 0.4, 0.42), Vector3(0, 1.5, 12)),
		Greybox.solid_box(Vector3(64, 3, 1), Color(0.4, 0.4, 0.42), Vector3(0, 1.5, -70)),
	]
	for edge in edges:
		GroundMaterials.apply(edge, GroundMaterials.concrete())
		add_child(edge)


## The lane's clutter (Claude, art at the owner's request 2026-10-07): parked
## scooters, pot plants, light-box signs, an A-board, plastic stools, a cone,
## utility boxes — kept against the shop fronts, out of the way of the walk,
## its search spots and its people. The big ones are solid (the dog goes
## round them) and fade for the camera like trees do.
const CLUTTER_DIR := "res://assets/environment/walk_kit/clutter/%s.glb"
const CLUTTER: Array = [
	# [piece, x, z, yaw, solid size (or zero)]
	[&"scooter", -21.6, 5.0, 0.0, Vector3(1.6, 1.1, 0.6)],
	[&"scooter", -20.4, 5.05, 0.05, Vector3(1.6, 1.1, 0.6)],
	[&"scooter", -9.6, 5.0, PI, Vector3(1.6, 1.1, 0.6)],
	[&"scooter", 3.6, 5.0, 0.0, Vector3(1.6, 1.1, 0.6)],
	[&"scooter", 14.6, 5.05, PI, Vector3(1.6, 1.1, 0.6)],
	[&"scooter", -6.0, -8.4, 0.0, Vector3(1.6, 1.1, 0.6)],
	[&"scooter", 4.6, -8.4, PI, Vector3(1.6, 1.1, 0.6)],
	[&"potted_plant", -26.0, 5.1, 0.0, Vector3.ZERO],
	[&"potted_plant", -17.8, 5.1, 0.0, Vector3.ZERO],
	[&"potted_plant", -5.4, 5.1, 0.0, Vector3.ZERO],
	[&"potted_plant", 6.9, 5.1, 0.0, Vector3.ZERO],
	[&"potted_plant", 18.2, 5.1, 0.0, Vector3.ZERO],
	[&"potted_plant", -18.0, -8.5, 0.0, Vector3.ZERO],
	[&"potted_plant", 8.4, -8.5, 0.0, Vector3.ZERO],
	[&"light_box_sign", -14.0, 5.0, 0.0, Vector3.ZERO],
	[&"light_box_sign", 2.2, 5.0, 0.3, Vector3.ZERO],
	[&"light_box_sign", 12.8, 5.0, -0.2, Vector3.ZERO],
	[&"a_board", -2.2, 4.85, 0.2, Vector3.ZERO],
	[&"a_board", 10.6, 4.85, -0.15, Vector3.ZERO],
	[&"plastic_stool", -23.6, 5.0, 0.0, Vector3.ZERO],
	[&"plastic_stool", -23.0, 5.15, 0.4, Vector3.ZERO],
	[&"plastic_stool", 26.0, 5.0, 0.0, Vector3.ZERO],
	[&"cone", -12.9, -8.1, 0.0, Vector3.ZERO],
	[&"utility_box", -29.6, 5.0, 0.0, Vector3(0.8, 1.35, 0.45)],
	[&"utility_box", 29.0, -8.4, PI, Vector3(0.8, 1.35, 0.45)],
]


func _build_street_clutter() -> void:
	for entry: Array in CLUTTER:
		var piece := (load(CLUTTER_DIR % entry[0]) as PackedScene).instantiate() as Node3D
		var at := Vector3(float(entry[1]), 0.0, float(entry[2]))
		var solid: Vector3 = entry[4]
		if solid != Vector3.ZERO:
			var body := Greybox.solid_box(solid, Color.WHITE, at + Vector3(0, solid.y * 0.5, 0), Greybox.FADE_GROUP)
			for mesh in body.find_children("*", "MeshInstance3D", true, false):
				(mesh as MeshInstance3D).visible = false
			body.rotation.y = float(entry[3])
			piece.position = Vector3(0, -solid.y * 0.5, 0)
			body.add_child(piece)
			add_child(body)
		else:
			piece.position = at
			piece.rotation.y = float(entry[3])
			add_child(piece)


## S05-02: the owner can catch their breath here.
func _add_rest_spot(spot_name: StringName, at: Vector3) -> void:
	var spot := RestSpot3D.new()
	spot.name = spot_name
	spot.run_manager = run_manager
	spot.human = human
	spot.position = at
	add_child(spot)


func _build_park() -> void:
	var lawn := Greybox.box(Vector3(62, 0.03, 50), Color(0.36, 0.55, 0.33), Vector3(0, 0.02, -45))
	GroundMaterials.apply(lawn, GroundMaterials.grass())
	add_child(lawn)
	add_child(EnvironmentKit.park_gate(Vector3(0, 0, -20)))
	for p: Vector3 in [Vector3(-8, 0, -28), Vector3(10, 0, -31), Vector3(-7, 0, -43), Vector3(13, 0, -50), Vector3(-13, 0, -54), Vector3(4, 0, -58)]:
		if p == Vector3(-13, 0, -54):
			# The banyan is a place, not scenery: a TerritoryPoint3D owns it and
			# picks the landmark variant from what the dog remembers (P4-006).
			var banyan := TerritoryPoint3D.new()
			banyan.name = "BanyanTerritory"
			banyan.territory_id = &"banyan"
			banyan.run_manager = run_manager
			banyan.dog = dog
			banyan.position = p
			add_child(banyan)
		else:
			add_child(EnvironmentKit.tree(p, 1.0 + 0.08 * fposmod(absf(p.x), 3.0)))
	for p: Vector3 in [Vector3(-3, 0, -30), Vector3(6, 0, -26), Vector3(-11, 0, -37), Vector3(9, 0, -41)]:
		add_child(EnvironmentKit.bush(p))
	add_child(EnvironmentKit.bench(Vector3(-2, 0, -36)))
	_add_rest_spot(&"RestBench", Vector3(-2, 0, -36))
	add_child(EnvironmentKit.bin(Vector3(2.4, 0, -36), EnvironmentKit.TEAL))
	for p: Vector3 in [Vector3(-5, 0, -24), Vector3(7, 0, -39), Vector3(-9, 0, -49)]:
		add_child(EnvironmentKit.lamp(p))
