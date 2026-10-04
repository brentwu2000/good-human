class_name AdoptionScene
extends Node3D
## Sprint 06 (S06-03, D6-03; owner direction 2026-10-05: the dog at the
## window, people walking past, now and then someone stopping to look). After
## being chosen the pup is put in the pen by the clinic's front window, and the
## player IS that pup, at pup height, looking out at the street. People go by.
## Most do not stop. Now and then someone does, and looks in through the glass
## for a moment; the pup can only be itself at them — wag, sit, bark, bring a
## toy — and they answer the way they are (S06-05), then walk on. No score.
## In the end one of them comes back, through the door: the human chooses the
## dog, not the other way round.

signal visitor_ready(index: int)
signal reacted(index: int, reaction: int)
signal decided(human: HumanCandidate)
## S06-06: the naming panel is up.
signal naming_ready

const Behavior := DogTraitData.Behavior
const Reaction := HumanBackgroundData.Reaction
## People who stop to look in (the possible adopters).
const VISITORS: int = 3
const ACTIONS_PER_VISIT: int = 3
## People who only walk past.
const PASSERS_BY: int = 5
## How long someone stands at the glass if the pup gives them nothing (s).
const LOOK_SECONDS: float = 9.0

## The glass is at z = WINDOW_Z; the pup sits at the origin inside.
const WINDOW_Z: float = -1.3
## The pavement outside: where people walk, and where someone stops to look.
const LANE_Z: float = -2.7
const STOP := Vector3(0.0, 0.0, -1.95)
const STREET_END: float = 8.0
## The clinic door, outside and in, and where the adopter crouches.
const DOOR_OUT := Vector3(3.3, 0.0, -2.0)
const DOOR_IN := Vector3(3.0, 0.0, -0.8)
const KNEEL := Vector3(0.25, 0.0, -0.75)
const EYE_HEIGHT: float = 0.36

const BEHAVIOR_TEXT := {
	Behavior.WAG: "搖尾巴", Behavior.SIT: "坐好", Behavior.APPROACH: "走到窗邊",
	Behavior.BARK: "汪一聲", Behavior.FETCH: "叼玩具", Behavior.LICK_HAND: "舔玻璃",
	Behavior.LIE_DOWN: "趴下", Behavior.STARE: "盯著看", Behavior.IGNORE: "不理他",
}
## S06-06: how the moment that counted is remembered.
const DID_TEXT := {
	Behavior.WAG: "搖了尾巴", Behavior.SIT: "乖乖坐好", Behavior.APPROACH: "走到了窗邊",
	Behavior.BARK: "汪了一聲", Behavior.FETCH: "叼起了玩具", Behavior.LICK_HAND: "舔了玻璃",
	Behavior.LIE_DOWN: "趴了下來", Behavior.STARE: "一直盯著他", Behavior.IGNORE: "假裝不理他",
}
const FELT_TEXT := {
	Reaction.INTERESTED: "他看了你好久", Reaction.AMUSED: "他笑了出來", Reaction.CAUTIOUS: "他退了一步",
	Reaction.STARTLED: "他嚇了一跳", Reaction.AFFECTIONATE: "他蹲下來隔著玻璃看你", Reaction.INDIFFERENT: "他好像沒什麼反應",
}
const EMOTE := {
	Reaction.INTERESTED: "👀", Reaction.AMUSED: "😄", Reaction.CAUTIOUS: "😬",
	Reaction.STARTLED: "😨", Reaction.AFFECTIONATE: "🥰", Reaction.INDIFFERENT: "😐",
}

## Seconds per beat; tests make it small.
@export var pace: float = 1.0
## Seed for who walks by (0 = new).
@export var seed_value: int = 0

var dog: DogCandidate
var humans: Array[HumanCandidate] = []
var adoption: AdoptionMatch
var visit_index: int = -1
var actions_left: int = 0
var accepting: bool = false
var adopter: HumanCandidate
## S06-06: per visitor, the moment that moved them most: [gain, behavior, reaction].
var best_moments: Dictionary[int, Array] = {}
var name_suggestions: Array[String] = []

var _rng := RandomNumberGenerator.new()
var _puppet: FighterPuppet3D
var _emote: Label3D
## Passers-by: [puppet, direction (+1/-1), speed, lane z].
var _passers: Array[Array] = []
var _camera: Camera3D
var _camera_rest := Vector3(0, EYE_HEIGHT, 0.1)
var _camera_basis: Basis
var _toy: Node3D
var _line: Label
var _hint: Label
var _buttons: Array[Button] = []
var _naming: Control
var _name_edit: LineEdit
var _suggestion: int = 0


func _ready() -> void:
	dog = Game.chosen_dog
	if dog == null:
		var fallback := RandomNumberGenerator.new()
		fallback.seed = 1
		dog = DogCandidateGenerator.generate(fallback, 1, DataRegistry.dog_breeds, DataRegistry.dog_traits)[0]
	if seed_value == 0:
		_rng.randomize()
	else:
		_rng.seed = seed_value
	humans = HumanCandidateGenerator.generate(_rng, VISITORS, DataRegistry.human_backgrounds)
	adoption = AdoptionMatch.new(dog, humans, _rng)
	_build_room()
	_build_street()
	_build_ui()
	for i in PASSERS_BY:
		_add_passer(i)
	_say("（被放進了窗邊的小圍欄。外面的人來來去去。）")
	_watch_the_street.call_deferred()


func _process(delta: float) -> void:
	for passer in _passers:
		var body := passer[0] as FighterPuppet3D
		body.position.x += float(passer[1]) * float(passer[2]) * delta / pace
		if absf(body.position.x) > STREET_END:
			_reset_passer(passer)


## The dog does `behavior` at whoever is at the glass. Returns their reaction,
## or -1 when nobody is looking.
func perform(behavior: int) -> int:
	if not accepting or actions_left <= 0:
		return -1
	actions_left -= 1
	var before := adoption.interest[visit_index]
	var reaction := adoption.perform(behavior, visit_index)
	var gain := adoption.interest[visit_index] - before
	if not best_moments.has(visit_index) or gain > float(best_moments[visit_index][0]):
		best_moments[visit_index] = [gain, behavior, reaction]
	_play_dog(behavior)
	_play_reaction(reaction)
	reacted.emit(visit_index, reaction)
	_update_buttons()
	if actions_left <= 0:
		accepting = false
	return reaction


## The day at the window: now and then someone stops, looks, walks on.
func _watch_the_street() -> void:
	for i in humans.size():
		await _wait(_rng.randf_range(2.5, 4.5))
		visit_index = i
		await _stop_and_look(humans[i], 1 if i % 2 == 0 else -1)
	await _wait(2.0)
	_decide()


func _stop_and_look(human: HumanCandidate, from_side: int) -> void:
	_puppet = _person(human)
	_puppet.position = Vector3(-from_side * STREET_END, 0, LANE_Z)
	_emote = Greybox.label("", 2.15, 64)
	_puppet.add_child(_emote)
	await _walk(_puppet, Vector3(0, 0, LANE_Z), 3.0)
	await _walk(_puppet, STOP, 0.6)
	_puppet.rotation.y = PI
	_puppet.set_ambient(false)
	actions_left = ACTIONS_PER_VISIT
	accepting = true
	_say("（有人停下來，隔著玻璃看你。）")
	_update_buttons()
	visitor_ready.emit(visit_index)
	var looked := 0.0
	while accepting and looked < LOOK_SECONDS * pace:
		await get_tree().process_frame
		looked += get_process_delta_time()
	accepting = false
	_update_buttons()
	await _wait(1.2)
	_say("（他看了一會兒，又走了。）")
	_emote.text = ""
	await _walk(_puppet, Vector3(0, 0, LANE_Z), 0.6)
	await _walk(_puppet, Vector3(from_side * STREET_END, 0, LANE_Z), 3.0)
	_puppet.queue_free()
	_puppet = null


## One of them comes back for the dog (S06-05 decides who): along the street,
## to the door, and in.
func _decide() -> void:
	adopter = humans[adoption.decide()]
	_say("（過了一陣子……門口的鈴響了。）")
	_puppet = _person(adopter)
	_puppet.position = Vector3(STREET_END, 0, LANE_Z)
	await _walk(_puppet, Vector3(DOOR_OUT.x, 0, LANE_Z), 2.0)
	await _walk(_puppet, DOOR_OUT, 0.5)
	_puppet.position = DOOR_IN
	await _walk(_puppet, KNEEL, 1.2)
	_puppet.set_ambient(false)
	_puppet.face_towards(_camera.global_position)
	_puppet.rotation.y = atan2(-(_camera.global_position.x - KNEEL.x), -(_camera.global_position.z - KNEEL.z))
	_puppet.play_acknowledge(_camera.global_position)
	_say("「是剛剛窗邊那隻……就是你了。從今天起，我們是一家人。」")
	decided.emit(adopter)
	await _wait(1.6)
	_open_naming()


# --- Naming (S06-06) ----------------------------------------------------------------

## The dog's family names their human: the one thing about them the player
## decides. Suggestions fit who they are; anything can be typed.
func _open_naming() -> void:
	var bg := adopter.background()
	name_suggestions.assign(bg.name_suggestions if bg != null and not bg.name_suggestions.is_empty() else ["主人"])
	_suggestion = 0
	_name_edit.text = name_suggestions[0]
	for button in _buttons:
		button.disabled = true
	_hint.text = ""
	_say("（這個人，以後就是你的人了。）")
	_naming.visible = true
	naming_ready.emit()


func next_suggestion() -> void:
	_suggestion = (_suggestion + 1) % name_suggestions.size()
	_name_edit.text = name_suggestions[_suggestion]


## The pair begins (Game.adopt saves it and goes Home).
func confirm_name(typed: String = "") -> void:
	if not typed.is_empty():
		_name_edit.text = typed
	var human_name := _name_edit.text.strip_edges().left(12)
	Game.adopt(dog, adopter, human_name, summary())


## How they met, in words: the moment that moved the human who came back.
func summary() -> String:
	var index := humans.find(adopter)
	if not best_moments.has(index):
		return "在動物醫院的窗邊，他看了你一眼，後來就回來帶你回家。"
	var moment: Array = best_moments[index]
	return "在動物醫院的窗邊，你%s，%s。後來，他回來帶你回家。" % [DID_TEXT.get(int(moment[1]), ""), FELT_TEXT.get(int(moment[2]), "")]


# --- People on the street --------------------------------------------------------

func _person(human: HumanCandidate) -> FighterPuppet3D:
	var body := FighterPuppet3D.new()
	add_child(body)
	body.apply(human.to_fighter_data(""))
	return body


func _walk(body: Node3D, to: Vector3, seconds: float) -> void:
	var puppet := body as FighterPuppet3D
	puppet.set_ambient(true)
	var d := to - body.position
	if Vector2(d.x, d.z).length() > 0.01:
		body.rotation.y = atan2(-d.x, -d.z)
	var tween := create_tween()
	tween.tween_property(body, "position", to, seconds * pace)
	await tween.finished


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds * pace).timeout


## Someone who is only going somewhere: never stops at the window.
func _add_passer(index: int) -> void:
	var looks := HumanCandidateGenerator.generate(_rng, 1, DataRegistry.human_backgrounds)[0]
	var body := _person(looks)
	var passer: Array = [body, 1, 1.2, LANE_Z]
	_passers.append(passer)
	_reset_passer(passer)
	body.position.x = lerpf(-STREET_END, STREET_END, (index + 0.5) / PASSERS_BY)


func _reset_passer(passer: Array) -> void:
	var body := passer[0] as FighterPuppet3D
	var direction := 1 if _rng.randf() < 0.5 else -1
	passer[1] = direction
	passer[2] = _rng.randf_range(1.0, 1.6)
	# Two loose lanes, the far one by the kerb.
	passer[3] = LANE_Z - (0.0 if _rng.randf() < 0.5 else 0.8)
	body.position = Vector3(-direction * STREET_END, 0, float(passer[3]))
	body.rotation.y = atan2(-direction, 0.0)
	body.set_ambient(true)


# --- Presentation ---------------------------------------------------------------

## What it looks like from inside the pup when it does something.
func _play_dog(behavior: int) -> void:
	var tween := create_tween()
	var rest := _camera_rest
	match behavior:
		Behavior.WAG:
			for i in 3:
				tween.tween_property(_camera, "rotation:z", 0.05, 0.08 * pace)
				tween.tween_property(_camera, "rotation:z", -0.05, 0.08 * pace)
			tween.tween_property(_camera, "rotation:z", 0.0, 0.08 * pace)
		Behavior.SIT:
			tween.tween_property(_camera, "position", rest + Vector3(0, -0.1, 0), 0.25 * pace)
		Behavior.LIE_DOWN:
			tween.tween_property(_camera, "position", rest + Vector3(0, -0.22, 0), 0.4 * pace)
		Behavior.APPROACH, Behavior.LICK_HAND:
			# Right up to the glass.
			tween.tween_property(_camera, "position", rest + Vector3(0, 0.03, WINDOW_Z + 0.25), 0.45 * pace)
		Behavior.BARK:
			_say("汪！")
			for i in 3:
				tween.tween_property(_camera, "position", rest + Vector3(0.03, 0.02, 0), 0.04 * pace)
				tween.tween_property(_camera, "position", rest, 0.04 * pace)
		Behavior.FETCH:
			_toy.visible = true
			tween.tween_property(_camera, "position", rest + Vector3(0, 0, -0.35), 0.3 * pace)
		Behavior.STARE:
			tween.tween_property(_camera, "fov", 56.0, 0.5 * pace)
		Behavior.IGNORE:
			tween.tween_property(_camera, "rotation:y", 1.1, 0.35 * pace)
	tween.tween_interval(0.5 * pace)
	tween.tween_property(_camera, "position", rest, 0.3 * pace)
	tween.parallel().tween_property(_camera, "basis", _camera_basis, 0.3 * pace)
	tween.parallel().tween_property(_camera, "fov", 68.0, 0.3 * pace)
	tween.tween_callback(func() -> void: _toy.visible = false)


## How they take it: in their body first, then — muffled by the glass — a
## word or two of their own.
func _play_reaction(reaction: int) -> void:
	var human := humans[visit_index]
	var bg := human.background()
	_emote.text = EMOTE.get(reaction, "")
	var line: String = bg.reaction_lines.get(reaction, "") if bg != null else ""
	if not line.is_empty():
		_say("（隔著玻璃）「%s」" % line)
	var tween := create_tween()
	match reaction:
		Reaction.AFFECTIONATE:
			_puppet.play_acknowledge(_camera.global_position)
		Reaction.INTERESTED:
			tween.tween_property(_puppet, "position", STOP + Vector3(0, 0, 0.12), 0.3 * pace)
		Reaction.AMUSED:
			tween.tween_property(_puppet, "position:y", 0.08, 0.1 * pace)
			tween.tween_property(_puppet, "position:y", 0.0, 0.1 * pace)
		Reaction.CAUTIOUS:
			tween.tween_property(_puppet, "position", STOP + Vector3(0, 0, -0.35), 0.3 * pace)
		Reaction.STARTLED:
			_puppet.play_bumped(_camera.global_position)
			tween.tween_property(_puppet, "position", STOP + Vector3(0, 0, -0.55), 0.2 * pace)
		Reaction.INDIFFERENT:
			tween.tween_property(_puppet, "rotation:y", PI + 0.6, 0.3 * pace)
			tween.tween_interval(0.4 * pace)
			tween.tween_property(_puppet, "rotation:y", PI, 0.3 * pace)


func _say(text: String) -> void:
	if _line != null:
		_line.text = text


func _update_buttons() -> void:
	for button in _buttons:
		button.disabled = not accepting or actions_left <= 0
	if _hint != null:
		_hint.text = "他在看你。你想讓他看到什麼樣的你？" if accepting and actions_left > 0 else "（看著窗外的人。）"


# --- The clinic and the street ------------------------------------------------------

func _build_room() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.74, 0.84, 0.92)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.86, 0.9, 0.92)
	env.environment.ambient_light_energy = 0.8
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 150, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)
	# Inside: the clinic's tiled floor and the low pen the pup sits in.
	add_child(Greybox.box(Vector3(8, 0.04, 3.0), Color(0.84, 0.86, 0.85), Vector3(0, -0.02, 0.2)))
	var pen := Color(0.92, 0.92, 0.9)
	for x in [-0.55, 0.55]:
		for z in [-0.2, 0.25]:
			add_child(Greybox.cylinder(0.015, 0.55, pen, Vector3(x, 0.275, z)))
	add_child(Greybox.box(Vector3(0.9, 0.04, 0.6), Color(0.78, 0.86, 0.92), Vector3(0, 0.02, 0.05)))
	# The shop front: a low wall, a big pane of glass, frames, the door.
	var frame := Color(0.32, 0.34, 0.36)
	add_child(Greybox.box(Vector3(8, 0.35, 0.12), Color(0.9, 0.9, 0.88), Vector3(0, 0.175, WINDOW_Z)))
	add_child(Greybox.box(Vector3(8, 0.5, 0.12), Color(0.9, 0.9, 0.88), Vector3(0, 2.65, WINDOW_Z)))
	for x in [-3.0, -0.95, 0.95, 2.75, 3.85]:
		add_child(Greybox.box(Vector3(0.07, 2.4, 0.1), frame, Vector3(x, 1.2, WINDOW_Z)))
	add_child(Greybox.box(Vector3(8, 0.06, 0.1), frame, Vector3(0, 2.4, WINDOW_Z)))
	add_child(Greybox.box(Vector3(8, 0.06, 0.1), frame, Vector3(0, 0.35, WINDOW_Z)))
	var glass := MeshInstance3D.new()
	var pane := BoxMesh.new()
	pane.size = Vector3(8, 2.05, 0.02)
	glass.mesh = pane
	var glass_mat := StandardMaterial3D.new()
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.albedo_color = Color(0.82, 0.92, 0.95, 0.16)
	glass_mat.metallic = 0.2
	glass_mat.roughness = 0.05
	glass.material_override = glass_mat
	glass.position = Vector3(0, 1.375, WINDOW_Z)
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(glass)
	# Light on the glass, so it reads as a pane between the pup and the street.
	var shine := StandardMaterial3D.new()
	shine.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shine.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shine.albedo_color = Color(1, 1, 1, 0.18)
	for streak: Array in [[-0.55, 1.5, 0.09], [-0.38, 1.6, 0.04], [0.45, 1.1, 0.07]]:
		var bar := MeshInstance3D.new()
		var quad := BoxMesh.new()
		quad.size = Vector3(float(streak[2]), 1.6, 0.005)
		bar.mesh = quad
		bar.material_override = shine
		bar.position = Vector3(float(streak[0]), float(streak[1]), WINDOW_Z + 0.02)
		bar.rotation.z = 0.5
		bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(bar)
	# The clinic's name on the glass, read backwards from inside.
	var sign := Greybox.label("毛毛動物醫院", 0.0, 64, Color(0.2, 0.45, 0.42, 0.85), 30.0)
	sign.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	sign.pixel_size = 0.004
	sign.position = Vector3(0.0, 2.15, WINDOW_Z - 0.02)
	sign.rotation.y = PI
	add_child(sign)
	_camera = Camera3D.new()
	_camera.fov = 68.0
	add_child(_camera)
	_camera.look_at_from_position(_camera_rest, Vector3(0, 0.95, -3.2))
	_camera_rest = _camera.position
	_camera_basis = _camera.basis
	_toy = Greybox.sphere(0.05, Color(0.9, 0.85, 0.2), Vector3(0.05, 0.25, -0.2))
	_toy.visible = false
	add_child(_toy)


func _build_street() -> void:
	# Pavement, kerb, road, the shops across the street, a tree, a scooter.
	add_child(Greybox.box(Vector3(20, 0.08, 2.6), Color(0.72, 0.7, 0.66), Vector3(0, -0.04, -2.65)))
	add_child(Greybox.box(Vector3(20, 0.12, 0.2), Color(0.6, 0.6, 0.58), Vector3(0, 0.0, -4.0)))
	add_child(Greybox.box(Vector3(20, 0.04, 6), Color(0.33, 0.34, 0.36), Vector3(0, -0.06, -7.0)))
	for x in range(-9, 10, 3):
		add_child(Greybox.box(Vector3(1.2, 0.01, 0.15), Color(0.9, 0.88, 0.8), Vector3(x, -0.03, -7.0)))
	var shop_colors := [Color(0.85, 0.72, 0.6), Color(0.7, 0.78, 0.82), Color(0.88, 0.84, 0.7), Color(0.76, 0.7, 0.78)]
	for i in 6:
		var x := -10.0 + i * 4.0
		add_child(Greybox.box(Vector3(3.8, 4.5, 1.0), shop_colors[i % shop_colors.size()], Vector3(x, 2.25, -11.0)))
		add_child(Greybox.box(Vector3(2.6, 1.6, 0.05), Color(0.45, 0.55, 0.6), Vector3(x, 1.2, -10.48)))
		add_child(Greybox.box(Vector3(3.0, 0.12, 0.9), Color(0.8, 0.35, 0.3) if i % 2 == 0 else Color(0.3, 0.55, 0.5), Vector3(x, 2.3, -10.1)))
	add_child(Greybox.cylinder(0.12, 2.4, Color(0.45, 0.35, 0.25), Vector3(-4.5, 1.2, -3.7)))
	add_child(Greybox.sphere(1.1, Color(0.35, 0.55, 0.32), Vector3(-4.5, 2.9, -3.7)))
	add_child(Greybox.box(Vector3(0.5, 0.7, 1.4), Color(0.85, 0.85, 0.82), Vector3(5.5, 0.4, -3.5)))


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_line = Label.new()
	_line.name = "Line"
	_line.add_theme_font_size_override("font_size", 28)
	_line.add_theme_color_override("font_color", Color(0.15, 0.17, 0.18))
	_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_line.offset_top = 40
	_line.offset_left = 24
	_line.offset_right = -24
	var backing := StyleBoxFlat.new()
	backing.bg_color = Color(1, 1, 1, 0.72)
	backing.set_corner_radius_all(10)
	backing.set_content_margin_all(10)
	_line.add_theme_stylebox_override("normal", backing)
	layer.add_child(_line)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -360
	panel.offset_left = 16
	panel.offset_right = -16
	panel.offset_bottom = -16
	layer.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 22)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_hint)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	box.add_child(grid)
	for behavior: int in BEHAVIOR_TEXT:
		var button := Button.new()
		button.name = "Behavior%d" % behavior
		button.text = BEHAVIOR_TEXT[behavior]
		button.custom_minimum_size = Vector2(0, 84)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 26)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func() -> void: perform(behavior))
		grid.add_child(button)
		_buttons.append(button)
	_update_buttons()
	_build_naming(layer)


func _build_naming(layer: CanvasLayer) -> void:
	_naming = PanelContainer.new()
	_naming.name = "Naming"
	_naming.visible = false
	_naming.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_naming.offset_top = -360
	_naming.offset_left = 16
	_naming.offset_right = -16
	_naming.offset_bottom = -16
	layer.add_child(_naming)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_naming.add_child(box)
	var ask := Label.new()
	ask.text = "你想怎麼叫他？"
	ask.add_theme_font_size_override("font_size", 30)
	box.add_child(ask)
	_name_edit = LineEdit.new()
	_name_edit.name = "NameEdit"
	_name_edit.max_length = 12
	_name_edit.custom_minimum_size = Vector2(0, 84)
	_name_edit.add_theme_font_size_override("font_size", 34)
	_name_edit.text_submitted.connect(func(_t: String) -> void: confirm_name())
	box.add_child(_name_edit)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	for spec: Array in [["換一個", next_suggestion], ["🏠 就叫這個", func() -> void: confirm_name()]]:
		var button := Button.new()
		button.text = spec[0]
		button.custom_minimum_size = Vector2(0, 88)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 28)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(spec[1])
		row.add_child(button)
