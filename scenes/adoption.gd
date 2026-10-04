class_name AdoptionScene
extends Node3D
## Sprint 06 (S06-03, D6-03): after choosing at the shelter the player IS the
## dog, waiting in the visiting room. People come in one at a time; the dog
## can only be itself at them — wag, sit, bark, bring a toy — and each answers
## the way they are (S06-05). Nobody shows a score. In the end one of them
## comes back for the dog: the human chooses the dog, not the other way round.

signal visitor_ready(index: int)
signal reacted(index: int, reaction: int)
signal decided(human: HumanCandidate)
## S06-06: the naming panel is up.
signal naming_ready

const Behavior := DogTraitData.Behavior
const Reaction := HumanBackgroundData.Reaction
const VISITORS: int = 3
const ACTIONS_PER_VISIT: int = 3
## Where a visitor stands, in front of the dog (the dog is at the origin).
const STAND := Vector3(0, 0, -2.3)
const DOOR := Vector3(3.2, 0, -2.4)
const EYE_HEIGHT: float = 0.45

const BEHAVIOR_TEXT := {
	Behavior.WAG: "搖尾巴", Behavior.SIT: "坐好", Behavior.APPROACH: "靠過去",
	Behavior.BARK: "汪一聲", Behavior.FETCH: "叼玩具", Behavior.LICK_HAND: "舔手",
	Behavior.LIE_DOWN: "趴下", Behavior.STARE: "盯著看", Behavior.IGNORE: "不理他",
}
## S06-06: how the moment that counted is remembered.
const DID_TEXT := {
	Behavior.WAG: "搖了尾巴", Behavior.SIT: "乖乖坐好", Behavior.APPROACH: "靠了過去",
	Behavior.BARK: "汪了一聲", Behavior.FETCH: "叼來了玩具", Behavior.LICK_HAND: "舔了他的手",
	Behavior.LIE_DOWN: "趴了下來", Behavior.STARE: "一直盯著他", Behavior.IGNORE: "假裝不理他",
}
const FELT_TEXT := {
	Reaction.INTERESTED: "他看了你好久", Reaction.AMUSED: "他笑了出來", Reaction.CAUTIOUS: "他退了一步",
	Reaction.STARTLED: "他嚇了一跳", Reaction.AFFECTIONATE: "他蹲下來摸了摸你", Reaction.INDIFFERENT: "他好像沒什麼反應",
}
const EMOTE := {
	Reaction.INTERESTED: "👀", Reaction.AMUSED: "😄", Reaction.CAUTIOUS: "😬",
	Reaction.STARTLED: "😨", Reaction.AFFECTIONATE: "🥰", Reaction.INDIFFERENT: "😐",
}

## Seconds per beat; tests make it small.
@export var pace: float = 1.0
## Seed for who visits (0 = new).
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

var _puppet: FighterPuppet3D
var _emote: Label3D
var _camera: Camera3D
var _camera_rest := Vector3(0, EYE_HEIGHT, 0.15)
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
	var rng := RandomNumberGenerator.new()
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value
	humans = HumanCandidateGenerator.generate(rng, VISITORS, DataRegistry.human_backgrounds)
	adoption = AdoptionMatch.new(dog, humans, rng)
	_build_room()
	_build_ui()
	_say("（被帶進了會客室。門外有腳步聲。）")
	_next_visitor.call_deferred()


## The dog does `behavior` at whoever is visiting. Returns their reaction, or
## -1 when nobody is there to see it.
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
		_leave.call_deferred()
	return reaction


func _next_visitor() -> void:
	visit_index += 1
	if visit_index >= humans.size():
		_decide()
		return
	var human := humans[visit_index]
	_puppet = FighterPuppet3D.new()
	add_child(_puppet)
	_puppet.apply(human.to_fighter_data(""))
	_puppet.position = DOOR
	_puppet.face_towards(STAND)
	_emote = Greybox.label("", 2.15, 64)
	_puppet.add_child(_emote)
	_puppet.set_ambient(true)
	var walk := create_tween()
	walk.tween_property(_puppet, "position", STAND, 1.2 * pace)
	await walk.finished
	_puppet.set_ambient(false)
	_puppet.rotation.y = PI
	actions_left = ACTIONS_PER_VISIT
	accepting = true
	_say("（有人來看你了。）")
	_update_buttons()
	visitor_ready.emit(visit_index)


func _leave() -> void:
	await get_tree().create_timer(1.0 * pace).timeout
	_say("（他起身走了出去。）")
	_puppet.set_ambient(true)
	_puppet.face_towards(DOOR)
	var walk := create_tween()
	walk.tween_property(_puppet, "position", DOOR, 1.0 * pace)
	await walk.finished
	_puppet.queue_free()
	_puppet = null
	_next_visitor()


## One of them comes back for the dog (S06-05 decides who).
func _decide() -> void:
	adopter = humans[adoption.decide()]
	_say("（門又開了。是剛剛來過的人。）")
	_puppet = FighterPuppet3D.new()
	add_child(_puppet)
	_puppet.apply(adopter.to_fighter_data(""))
	_puppet.position = DOOR
	_puppet.set_ambient(true)
	var walk := create_tween()
	walk.tween_property(_puppet, "position", STAND, 1.0 * pace)
	await walk.finished
	_puppet.set_ambient(false)
	_puppet.rotation.y = PI
	_puppet.play_acknowledge(_camera.global_position)
	_say("「就是你了。從今天起，我們是一家人。」")
	decided.emit(adopter)
	await get_tree().create_timer(1.6 * pace).timeout
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
		return "在收容所的會客室，他看了你一眼，就決定帶你回家。"
	var moment: Array = best_moments[index]
	return "在收容所的會客室，你%s，%s。後來，他回來帶你回家。" % [DID_TEXT.get(int(moment[1]), ""), FELT_TEXT.get(int(moment[2]), "")]


# --- Presentation ---------------------------------------------------------------

## What it looks like from inside the dog when it does something.
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
			tween.tween_property(_camera, "position", rest + Vector3(0, -0.12, 0), 0.25 * pace)
		Behavior.LIE_DOWN:
			tween.tween_property(_camera, "position", rest + Vector3(0, -0.27, 0), 0.4 * pace)
		Behavior.APPROACH, Behavior.LICK_HAND:
			tween.tween_property(_camera, "position", rest + Vector3(0, 0.02, -0.6), 0.35 * pace)
		Behavior.BARK:
			_say("汪！")
			for i in 3:
				tween.tween_property(_camera, "position", rest + Vector3(0.03, 0.02, 0), 0.04 * pace)
				tween.tween_property(_camera, "position", rest, 0.04 * pace)
		Behavior.FETCH:
			_toy.visible = true
			tween.tween_property(_camera, "position", rest + Vector3(0, 0, -0.35), 0.3 * pace)
		Behavior.STARE:
			tween.tween_property(_camera, "fov", 52.0, 0.5 * pace)
		Behavior.IGNORE:
			tween.tween_property(_camera, "rotation:y", 1.1, 0.35 * pace)
	tween.tween_interval(0.5 * pace)
	tween.tween_property(_camera, "position", rest, 0.3 * pace)
	tween.parallel().tween_property(_camera, "rotation:y", 0.0, 0.3 * pace)
	tween.parallel().tween_property(_camera, "fov", 62.0, 0.3 * pace)
	tween.tween_callback(func() -> void: _toy.visible = false)


## How they take it: in their body first, then a word or two of their own.
func _play_reaction(reaction: int) -> void:
	var human := humans[visit_index]
	var bg := human.background()
	_emote.text = EMOTE.get(reaction, "")
	var line: String = bg.reaction_lines.get(reaction, "") if bg != null else ""
	if not line.is_empty():
		_say("「%s」" % line)
	var tween := create_tween()
	match reaction:
		Reaction.AFFECTIONATE:
			_puppet.play_acknowledge(_camera.global_position)
		Reaction.INTERESTED:
			tween.tween_property(_puppet, "position", STAND + Vector3(0, 0, 0.15), 0.3 * pace)
		Reaction.AMUSED:
			tween.tween_property(_puppet, "position:y", 0.08, 0.1 * pace)
			tween.tween_property(_puppet, "position:y", 0.0, 0.1 * pace)
		Reaction.CAUTIOUS:
			tween.tween_property(_puppet, "position", STAND + Vector3(0, 0, -0.3), 0.3 * pace)
		Reaction.STARTLED:
			_puppet.play_bumped(_camera.global_position)
			tween.tween_property(_puppet, "position", STAND + Vector3(0, 0, -0.5), 0.2 * pace)
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
		_hint.text = "你想讓他看到什麼樣的你？（還可以做 %s 件事）" % ["", "一", "兩", "三"][clampi(actions_left, 0, 3)] if accepting else ""


func _build_room() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.9, 0.87, 0.8)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.88, 0.84, 0.78)
	env.environment.ambient_light_energy = 0.75
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -30, 0)
	sun.shadow_enabled = true
	add_child(sun)
	add_child(Greybox.box(Vector3(8, 0.05, 8), Color(0.66, 0.58, 0.48), Vector3(0, -0.025, -1.5)))
	add_child(Greybox.box(Vector3(8, 3.0, 0.1), Color(0.92, 0.89, 0.8), Vector3(0, 1.5, -4.0)))
	add_child(Greybox.box(Vector3(0.1, 3.0, 8), Color(0.88, 0.85, 0.77), Vector3(-3.2, 1.5, -1.5)))
	add_child(Greybox.box(Vector3(1.0, 2.1, 0.12), Color(0.55, 0.42, 0.3), Vector3(3.2, 1.05, -2.6), Vector3(0, PI / 2.0, 0)))
	add_child(Greybox.box(Vector3(1.6, 0.45, 0.45), Color(0.45, 0.5, 0.52), Vector3(-1.8, 0.225, -3.4)))
	_camera = Camera3D.new()
	_camera.fov = 62.0
	_camera.position = _camera_rest
	add_child(_camera)
	_camera.look_at_from_position(_camera_rest, STAND + Vector3(0, 0.75, 0))
	_camera_rest = _camera.position
	_toy = Greybox.sphere(0.06, Color(0.9, 0.85, 0.2), Vector3(0.05, 0.32, -0.25))
	_toy.visible = false
	add_child(_toy)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_line = Label.new()
	_line.name = "Line"
	_line.add_theme_font_size_override("font_size", 30)
	_line.add_theme_color_override("font_color", Color(0.18, 0.2, 0.2))
	_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_line.offset_top = 40
	_line.offset_left = 24
	_line.offset_right = -24
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
