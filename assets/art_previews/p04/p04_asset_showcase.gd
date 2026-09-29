extends Node3D
## ART-only playable review. No save access, damage, territory progress or rewards.
const HUMAN := preload("res://assets/characters/human/modular/p04_human_visual.gd")
const TREE := preload("res://assets/environment/territory/models/banyan_01/banyan_01.glb")
const SCENT_VISUAL := preload("res://assets/environment/territory/p04_scent_visual.gd")
const GREED_PROPS := preload("res://assets/environment/territory/models/greed/greed_props.glb")
const DOG := preload("res://assets/characters/dog/models/shiba_01/shiba_01.glb")
const CLIPS := ["Idle", "Jab", "HeavyHook", "Kick", "Block", "Dodge", "HitLight", "HitHeavy", "Stumble", "Down", "Walk", "Approach", "Circle", "Backstep", "Idle_Untrained", "Idle_Scrapper", "Idle_Calm"]
var owner_actor: Node3D
var rival: Node3D
var dog: CharacterBody3D
var dog_model: Node3D
var dog_player: AnimationPlayer
var camera: Camera3D
var tree: Node3D
var scent_visual: Node3D
var greed_props: Node3D
var rival_dog: Node3D
var rival_pair_human: Node3D
var rival_tag: MeshInstance3D
var label: Label
var risk_hud: PanelContainer
var risk_copy: Label
var mode := 0
var clip_index := 0
var elapsed := 0.0
var free_camera := false
var leash: MeshInstance3D
var dog_case := 0
var scent_state_index := 0
const SCENT_STATES := ["UNKNOWN", "DISCOVERED", "CONTESTED", "CLAIMING", "OWNED"]
var territory_variant_index := 0
const TERRITORY_VARIANTS := ["UNKNOWN", "DISCOVERED", "CONTESTED", "OWNED"]
const DOG_CASES := ["Blocked by leg", "Around human", "Retreating human", "Behind rival", "Crossing path"]

func _ready() -> void:
	get_viewport().msaa_3d = Viewport.MSAA_2X
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("a6b5bd")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("d2dcdf")
	env.environment.ambient_light_energy = 0.7
	add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-42, -35, 0)
	light.light_color = Color("ffe0b1")
	light.light_energy = 1.0
	light.shadow_enabled = true
	light.directional_shadow_max_distance = 18.0
	light.shadow_normal_bias = 0.8
	add_child(light)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(28, 28)
	ground.mesh = plane
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ground.material_override = _material(Color("77786c"))
	add_child(ground)
	# Restrained seams make motion against the ground plane legible.
	for i in range(-6, 7):
		var seam := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(12, 0.003, 0.018)
		seam.mesh = box
		seam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		seam.position = Vector3(0, 0.012, float(i))
		seam.material_override = _material(Color("5a5d54"))
		add_child(seam)
	owner_actor = HUMAN.new()
	rival = HUMAN.new()
	add_child(owner_actor)
	add_child(rival)
	rival.set_outfit_colors(Color("343a3e"), Color("45483b"))
	owner_actor.play_clip("Idle")
	rival.play_clip("Idle_Calm")
	_add_human_collision(owner_actor)
	_add_human_collision(rival)
	dog = CharacterBody3D.new()
	dog.name = "ReviewDog"
	dog.collision_layer = 2
	dog.collision_mask = 1
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.19
	capsule.height = 0.45
	shape.shape = capsule
	shape.position.y = 0.23
	dog.add_child(shape)
	add_child(dog)
	dog_model = DOG.instantiate()
	dog.add_child(dog_model)
	dog_player = _animation_player(dog_model)
	if dog_player != null and dog_player.has_animation("Idle"):
		dog_player.get_animation("Idle").loop_mode = Animation.LOOP_LINEAR
		dog_player.play("Idle")
	tree = TREE.instantiate()
	add_child(tree)
	tree.position = Vector3(0, 0, -7)
	scent_visual = SCENT_VISUAL.new()
	add_child(scent_visual)
	# Review framing lifts the markers in front of the trunk so the state language is legible.
	scent_visual.position = tree.position + Vector3(0, 0.18, 0.55)
	scent_visual.scale = Vector3.ONE * 2.2
	greed_props = GREED_PROPS.instantiate()
	add_child(greed_props)
	greed_props.visible = false
	rival_dog = DOG.instantiate()
	add_child(rival_dog)
	rival_dog.position = Vector3(1.35, 0, -1.1)
	rival_dog.scale = Vector3.ONE * 0.72
	rival_dog.visible = false
	rival_pair_human = HUMAN.new()
	add_child(rival_pair_human)
	rival_pair_human.set_outfit_colors(Color("26334a"), Color("3f526b"))
	rival_pair_human.position = Vector3(1.85, 0, -1.55)
	rival_pair_human.rotation.y = PI * 0.92
	rival_pair_human.play_clip("Idle_Calm")
	rival_pair_human.visible = false
	rival_tag = MeshInstance3D.new()
	var tag_mesh := SphereMesh.new()
	tag_mesh.radius = 0.075
	tag_mesh.height = 0.15
	rival_tag.mesh = tag_mesh
	rival_tag.material_override = _material(Color("3aa59d"))
	add_child(rival_tag)
	rival_tag.position = Vector3(1.35, 0.72, -0.82)
	rival_tag.visible = false
	camera = Camera3D.new()
	camera.fov = 55
	camera.near = 0.05
	add_child(camera)
	camera.current = true
	leash = MeshInstance3D.new()
	leash.material_override = _material(Color("318d85"))
	add_child(leash)
	_make_ui()
	_make_risk_hud()
	_set_mode(0)
	if "--capture-art" in OS.get_cmdline_user_args():
		_capture_sequence()

func _make_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := VBoxContainer.new()
	panel.position = Vector2(18, 18)
	layer.add_child(panel)
	label = Label.new()
	label.add_theme_font_size_override("font_size", 22)
	panel.add_child(label)
	for pair: Array in [["1  Motion clips", 0], ["2  Footwork / dog POV", 1], ["3  Dog collision study", 2], ["4  Banyan landmark", 3], ["5  Personality comparison", 4], ["6  Greed moment", 5], ["7  Territory variants", 6]]:
		var button := Button.new()
		button.text = pair[0]
		button.pressed.connect(_set_mode.bind(pair[1]))
		panel.add_child(button)
	var next := Button.new()
	next.text = "Next action [Space]"
	next.pressed.connect(_next_clip)
	panel.add_child(next)
	var situation := Button.new()
	situation.text = "Dog situation [G]"
	situation.pressed.connect(_next_dog_case)
	panel.add_child(situation)
	var scent := Button.new()
	scent.text = "Scent state [T]"
	scent.pressed.connect(_next_scent_state)
	panel.add_child(scent)
	var sniff := Button.new()
	sniff.text = "Sniff / recognize [R]"
	sniff.pressed.connect(_sniff_scent)
	panel.add_child(sniff)
	var mark := Button.new()
	mark.text = "Mark / claim [M]"
	mark.pressed.connect(_mark_scent)
	panel.add_child(mark)
	var reward := Button.new()
	reward.text = "Reward reveal [Y]"
	reward.pressed.connect(_reward_scent)
	panel.add_child(reward)
	var variant := Button.new()
	variant.text = "Territory variant [7/T]"
	variant.pressed.connect(_next_territory_variant)
	panel.add_child(variant)
	var hint := Label.new()
	hint.text = "WASD: move dog   V: dog-eye view   T/R/M/Y: scent review\nART CANDIDATE / no gameplay or saves"
	hint.add_theme_font_size_override("font_size", 18)
	panel.add_child(hint)

func _make_risk_hud() -> void:
	risk_hud = PanelContainer.new()
	risk_hud.position = Vector2(18, 610)
	risk_hud.size = Vector2(360, 66)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.08, 0.09, 0.9)
	style.border_color = Color("2caaa0")
	style.border_width_left = 5
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	risk_hud.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	risk_hud.add_child(box)
	var title := Label.new()
	title.text = "  WALK VALUE"
	title.add_theme_color_override("font_color", Color("77d8c9"))
	title.add_theme_font_size_override("font_size", 14)
	box.add_child(title)
	risk_copy = Label.new()
	risk_copy.text = "  UNBANKED 12  ·  one more thing"
	risk_copy.add_theme_color_override("font_color", Color("f0d9a1"))
	risk_copy.add_theme_font_size_override("font_size", 17)
	box.add_child(risk_copy)
	add_child(risk_hud)

func _set_mode(value: int) -> void:
	mode = value
	elapsed = 0
	owner_actor.position = Vector3(-0.7, 0, 0)
	rival.position = Vector3(0.7, 0, -0.25)
	owner_actor.rotation.y = PI
	rival.rotation.y = PI
	dog.position = Vector3(0, 0, 3.8 if mode == 1 else 1.5)
	owner_actor.visible = mode != 3
	rival.visible = mode in [1, 2, 4]
	dog.visible = mode in [2, 5]
	leash.visible = mode in [2, 5]
	tree.visible = mode in [3, 5, 6]
	scent_visual.visible = mode in [3, 6]
	greed_props.visible = mode == 5
	rival_dog.visible = mode == 5
	rival_pair_human.visible = mode == 5
	rival_tag.visible = mode == 5
	risk_hud.visible = mode == 5
	if mode == 6:
		scent_visual.set_state(TERRITORY_VARIANTS[territory_variant_index])
	free_camera = false
	if mode == 0:
		owner_actor.position = Vector3.ZERO
		owner_actor.play_clip(CLIPS[clip_index])
	elif mode == 4:
		owner_actor.position.x = -0.55
		rival.position.x = 0.55
		owner_actor.play_clip("Idle_Untrained")
		rival.play_clip("Idle_Calm")
	else:
		owner_actor.play_clip("Idle")
		rival.play_clip("Block")
	label.text = ["P-04 / " + CLIPS[clip_index], "P-04 / 8 second exchange", "P-04 / blocked and around", "D5-01 / Big Banyan · scent " + SCENT_STATES[scent_state_index], "P-04 / personality seeds", "D5-04 / Greed moment · safe exit ↔ temptation", "D5-07 / Territory variant · " + TERRITORY_VARIANTS[territory_variant_index]][mode]
	if mode == 5:
		risk_copy.text = "  UNBANKED 12  ·  one more thing"

func _next_clip() -> void:
	clip_index = (clip_index + 1) % CLIPS.size()
	_set_mode(0)

func _next_dog_case() -> void:
	dog_case = (dog_case + 1) % DOG_CASES.size()
	_set_mode(2)
	dog.position = [Vector3(-0.7, 0, 0.55), Vector3(-0.3, 0, 0.4), Vector3(-0.7, 0, 0.9), Vector3(0.7, 0, -0.9), Vector3(-1.3, 0, 0.35)][dog_case]
	if dog_case == 2:
		owner_actor.rotation.y = 0
	label.text = "P-04 / " + DOG_CASES[dog_case]

func _next_scent_state() -> void:
	scent_state_index = (scent_state_index + 1) % SCENT_STATES.size()
	scent_visual.set_state(SCENT_STATES[scent_state_index])
	_set_mode(3)

func _sniff_scent() -> void:
	scent_visual.play_recognize()
	scent_state_index = 1
	_set_mode(3)

func _mark_scent() -> void:
	scent_visual.play_mark()
	scent_state_index = 3
	_set_mode(3)

func _reward_scent() -> void:
	scent_visual.play_reward_reveal()
	scent_state_index = 4
	_set_mode(3)

func _next_territory_variant() -> void:
	territory_variant_index = (territory_variant_index + 1) % TERRITORY_VARIANTS.size()
	_set_mode(6)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode >= KEY_1 and event.keycode <= KEY_7:
		_set_mode(event.keycode - KEY_1)
	elif event.keycode == KEY_SPACE:
		_next_clip()
	elif event.keycode == KEY_V:
		free_camera = not free_camera
	elif event.keycode == KEY_G:
		_next_dog_case()
	elif event.keycode == KEY_T:
		if mode == 6:
			_next_territory_variant()
		else:
			_next_scent_state()
	elif event.keycode == KEY_R:
		_sniff_scent()
	elif event.keycode == KEY_M:
		_mark_scent()
	elif event.keycode == KEY_Y:
		_reward_scent()

func _physics_process(delta: float) -> void:
	elapsed += delta
	if mode == 2 or free_camera:
		var direction := Vector3(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), 0, float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
		dog.velocity = direction.normalized() * 1.1
		dog.move_and_slide()
		if dog.velocity.length() > 0.05:
			dog_model.rotation.y = atan2(-dog.velocity.x, -dog.velocity.z)
		if dog_player != null:
			var clip := "Walk" if dog.velocity.length() > 0.05 else "Idle"
			if dog_player.has_animation(clip) and dog_player.current_animation != clip:
				dog_player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
				dog_player.play(clip, 0.15)
	if mode == 1:
		var t := fmod(elapsed, 8.0)
		var beats: Array = [[0.0,-0.85,0.0,0.85,0.0], [1.0,-0.55,0.1,0.65,0.1], [2.0,-0.45,0.35,0.45,-0.15], [2.8,-0.30,0.27,0.45,-0.15], [3.6,-0.45,0.4,0.7,-0.35], [4.8,-0.05,0.2,0.75,-0.55], [6.2,0.05,0.3,0.65,-0.35], [8.0,-0.25,0.55,0.75,-0.25]]
		var beat := 0
		while beat < beats.size() - 2 and t > float(beats[beat + 1][0]):
			beat += 1
		var a: Array = beats[beat]
		var b: Array = beats[beat + 1]
		var blend := inverse_lerp(float(a[0]), float(b[0]), t)
		owner_actor.position = Vector3(float(a[1]), 0, -float(a[2])).lerp(Vector3(float(b[1]), 0, -float(b[2])), blend)
		rival.position = Vector3(float(a[3]), 0, -float(a[4])).lerp(Vector3(float(b[3]), 0, -float(b[4])), blend)
		owner_actor.look_at(rival.position)
		rival.look_at(owner_actor.position)
		var clip := "Approach" if t < 2 else ("Jab" if t < 3.6 else ("HeavyHook" if t < 4.8 else ("Stumble" if t < 6.2 else "Backstep")))
		if owner_actor.player.current_animation != clip:
			owner_actor.play_clip(clip)
	if mode == 2 and dog_case == 2:
		owner_actor.position.z = minf(elapsed * 0.12, 0.55)
		if owner_actor.player.current_animation != "Backstep":
			owner_actor.play_clip("Backstep")
	if mode == 5:
		# Dog leans toward the scent while owner and safe exit remain readable.
		dog.position = Vector3(0.2, 0, -0.15 + sin(elapsed * 2.0) * 0.03)
		dog_model.rotation.y = PI * 0.82
		rival_dog.rotation.y = PI * 0.55
		rival_pair_human.look_at(Vector3(0.9, 0, -1.0))
		owner_actor.position = Vector3(-0.65, 0, 0.35)
		owner_actor.look_at(Vector3(0.5, 0, -1.1))
		if owner_actor.player.current_animation != "Idle_Untrained":
			owner_actor.play_clip("Idle_Untrained")
	if mode in [3, 6]:
		camera.position = Vector3(2.5, 0.42, 1.2)
		camera.look_at(tree.position + Vector3(0, 2.6, 0))
	elif mode == 5:
		camera.position = Vector3(0.1, 3.1, 6.4)
		camera.fov = 62
		camera.look_at(Vector3(-0.65, 0.9, -1.8))
	elif free_camera or mode == 1:
		camera.position = dog.position + Vector3(0, 0.40, 0)
		camera.look_at((owner_actor.position + rival.position) * 0.5 + Vector3(0, 1.05, 0))
	elif mode == 2:
		camera.position = Vector3(3.8, 2.1, 5.8)
		camera.look_at(Vector3(0, 0.7, 0.8))
	else:
		camera.position = Vector3(2.2 if mode == 0 else 0.1, 1.1, 3.7)
		camera.look_at(Vector3(0, 0.95, 0))
	if mode in [2, 5]:
		_update_leash()

func _update_leash() -> void:
	# Review-only slack curve. Does not implement gameplay Pull or wrapping.
	var start := dog.position + Vector3(0, 0.48, 0)
	var hand_index: int = owner_actor.skeleton.find_bone("hand_r")
	var end: Vector3 = owner_actor.skeleton.global_transform * owner_actor.skeleton.get_bone_global_pose(hand_index).origin
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in 17:
		var t := float(i) / 16.0
		mesh.surface_add_vertex(start.lerp(end, t) - Vector3(0, sin(t * PI) * 0.15, 0))
	mesh.surface_end()
	leash.mesh = mesh

func _add_human_collision(human: Node3D) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.24
	capsule.height = 1.7
	shape.shape = capsule
	shape.position.y = 0.85
	body.add_child(shape)
	human.add_child(body)

func _animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child: Node in root.get_children():
		var found := _animation_player(child)
		if found != null:
			return found
	return null

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.87
	return material

func _capture_sequence() -> void:
	for view in [0, 1, 2, 3, 4, 5]:
		_set_mode(view)
		if view == 3:
			scent_state_index = 4
			scent_visual.set_state("OWNED")
			label.text = "D5-02/D5-03 / Banyan · OWNED + reward"
		await get_tree().create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		image.save_png("res://assets/art_previews/p04/capture_%d.png" % view)
	get_tree().quit()
