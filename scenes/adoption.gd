class_name AdoptionScene
extends Node3D
## Sprint 06 (S06-03, D6-03; owner direction 2026-10-05: the dog at the
## window, people walking past, now and then someone stopping to look). The
## pup picked from the street (ShelterScene) is in the pen by the clinic's front
## window, and now the player IS that pup, at pup height, looking out at the
## street the player just looked in from (ClinicWindow). People go by.
## Most do not stop. Now and then someone does, and looks in through the glass
## for a moment; the pup can only be itself at them — wag, sit, bark, bring a
## toy — and they answer the way they are (S06-05). The rest of the litter is
## in the pen too, being themselves, and a visitor may fall for one of them
## instead: they come in and carry that pup away, and the player's pup waits
## on (owner direction 2026-10-05). No score. In the end someone comes in for
## the player's pup: the human chooses the dog, not the other way round.

signal visitor_ready(index: int)
signal reacted(index: int, reaction: int)
signal decided(human: HumanCandidate)
## S06-06: the naming panel is up.
signal naming_ready
## A visitor took one of the other pups home instead.
signal pup_taken(litter_index: int, human: HumanCandidate)

const Behavior := DogTraitData.Behavior
const Reaction := HumanBackgroundData.Reaction
## At most this many people stop to look in (the possible adopters). If
## nobody has come in for the player's pup by then, the one who cared most
## comes back for it.
const VISITORS: int = 6
const ACTIONS_PER_VISIT: int = 3
## People who only walk past.
const PASSERS_BY: int = 5
## How long someone stands at the glass if the pup gives them nothing (s).
const LOOK_SECONDS: float = 9.0

## The glass is at z = WINDOW_Z; the pup sits at the origin inside.
const WINDOW_Z: float = ClinicWindow.WINDOW_Z
## The pavement outside: where people walk, and where someone stops to look.
const LANE_Z: float = -2.7
const STOP := Vector3(0.0, 0.0, -1.95)
const STREET_END: float = 8.0
## The clinic door, outside and in, and where the adopter crouches.
const DOOR_OUT := Vector3(3.3, 0.0, -2.0)
const DOOR_IN := Vector3(3.0, 0.0, -0.8)
const EYE_HEIGHT: float = 0.36
## Where the litter starts in the pen (they wander from there).
const LITTER_SPOTS: Array[Vector3] = [Vector3(-0.6, 0, -0.85), Vector3(0.55, 0, -1.0), Vector3(-0.15, 0, -0.5), Vector3(0.75, 0, -0.35)]
const PUPPY_SCALE: float = ClinicWindow.PUPPY_SCALE
## The pen by the window (owner direction 2026-10-05: the pups run about in
## it, the player's own included). x and z limits; the glass is just beyond.
const PEN_MIN := ClinicWindow.PEN_MIN
const PEN_MAX := ClinicWindow.PEN_MAX
const PUP_SPEED: float = 1.7
const WANDER_SPEED: float = 1.1
## Pups keep at least this far apart (centre to centre, m).
const PUP_SPACING: float = 0.32
## Right at the glass in front of whoever is looking, a pup is seen fully;
## from further back its moments count for less, down to this.
const FAR_WEIGHT: float = 0.35
const SEEN_RANGE: float = 1.4

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
## How each visitor feels about the player's pup…
var adoption: AdoptionMatch
## …and about each other pup in the pen (same order as `litter`).
var litter: Array[DogCandidate] = []
var litter_matches: Array[AdoptionMatch] = []
var taken: Array[bool] = []
## Visitor index -> litter index of the pup they took home.
var took_home: Dictionary[int, int] = {}
var visit_index: int = -1
var actions_left: int = 0
var accepting: bool = false
var adopter: HumanCandidate
## S06-06: per visitor, the moment that moved them most: [gain, behavior, reaction].
var best_moments: Dictionary[int, Array] = {}
var name_suggestions: Array[String] = []

var _rng := RandomNumberGenerator.new()
var _litter_pups: Array[Node3D] = []
## Where each litter pup is heading and how long it rests first.
var _wander_to: Array[Vector3] = []
var _wander_rest: Array[float] = []
## The player's own pup, in the pen with the rest.
var pup: Node3D
var _pup_target: Variant = null
var _pup_busy: float = 0.0
var _puppet: FighterPuppet3D
var _emote: Label3D
## Passers-by: [puppet, direction (+1/-1), speed, lane z].
var _passers: Array[Array] = []
var _camera: Camera3D
var _camera_rest := Vector3(0, 0.62, 1.15)
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
	litter.assign(Game.window_litter.slice(0, LITTER_SPOTS.size()))
	if litter.is_empty() and Game.window_litter.is_empty() and Game.chosen_dog == null:
		litter = DogCandidateGenerator.generate(_rng, 3, DataRegistry.dog_breeds, DataRegistry.dog_traits)
	for other in litter:
		litter_matches.append(AdoptionMatch.new(other, humans, _rng))
		taken.append(false)
	_build_room()
	_build_pup()
	_build_litter()
	_build_street()
	_build_ui()
	for i in PASSERS_BY:
		_add_passer(i)
	_say("（現在，你就是圍欄裡的那隻小狗。外面的人來來去去。）")
	_watch_the_street.call_deferred()


func _process(delta: float) -> void:
	_move_pup(delta)
	_process_litter(delta)
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
	if behavior in [Behavior.APPROACH, Behavior.LICK_HAND]:
		# Up to the glass in front of them first.
		pup.position = _clamp_to_pen(Vector3(STOP.x, 0, PEN_MIN.y))
	var before := adoption.interest[visit_index]
	var reaction := adoption.perform(behavior, visit_index, seen_weight(pup.position))
	var gain := adoption.interest[visit_index] - before
	if not best_moments.has(visit_index) or gain > float(best_moments[visit_index][0]):
		best_moments[visit_index] = [gain, behavior, reaction]
	# The others in the pen do their own thing at the same moment.
	for k in litter.size():
		if not taken[k]:
			litter_matches[k].perform(litter_matches[k].natural_behavior(), visit_index, seen_weight(_litter_pups[k].position))
	_play_dog(behavior)
	_play_reaction(reaction)
	reacted.emit(visit_index, reaction)
	_update_buttons()
	if actions_left <= 0:
		accepting = false
	return reaction


## How well whoever is at the window can see a pup at `at` (1 right in front
## of them at the glass, FAR_WEIGHT at the back of the pen).
func seen_weight(at: Vector3) -> float:
	var front := Vector3(STOP.x, 0, PEN_MIN.y)
	var d := Vector2(at.x - front.x, at.z - front.z).length()
	return lerpf(1.0, FAR_WEIGHT, clampf(d / SEEN_RANGE, 0.0, 1.0))


## The player's pup runs about the pen: move actions, or a tap on the floor.
func _move_pup(delta: float) -> void:
	if pup == null:
		return
	_pup_busy = maxf(_pup_busy - delta, 0.0)
	var input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var velocity := Vector3(input.x, 0, input.y) * PUP_SPEED
	if input.length() > 0.05:
		_pup_target = null
	elif _pup_target != null:
		var to: Vector3 = _pup_target - pup.position
		to.y = 0.0
		if to.length() < 0.05:
			_pup_target = null
		else:
			velocity = to.normalized() * minf(PUP_SPEED, to.length() / maxf(delta, 0.001))
	if _naming != null and _naming.visible:
		velocity = Vector3.ZERO
	var motion := pup.get_node("Motion") as DogModelMotion3D
	if velocity.length() > 0.05 and _pup_busy <= 0.0:
		pup.position = _clamp_to_pen(_keep_apart(pup.position + velocity * delta, -1))
		pup.rotation.y = lerp_angle(pup.rotation.y, atan2(-velocity.x, -velocity.z), minf(delta * 12.0, 1.0))
		motion.update_motion(delta, velocity.length(), velocity.length() > 1.2)
	else:
		motion.update_motion(delta, 0.0, false)


func _clamp_to_pen(at: Vector3) -> Vector3:
	return Vector3(clampf(at.x, PEN_MIN.x, PEN_MAX.x), 0.0, clampf(at.z, PEN_MIN.y, PEN_MAX.y))


## Pups bump and go round each other rather than through.
func _keep_apart(at: Vector3, self_index: int) -> Vector3:
	var bodies: Array[Node3D] = []
	if self_index >= 0 and pup != null:
		bodies.append(pup)
	for k in _litter_pups.size():
		if k != self_index and is_instance_valid(_litter_pups[k]) and not taken[k]:
			bodies.append(_litter_pups[k])
	for other in bodies:
		var away := at - other.position
		away.y = 0.0
		if away.length() < PUP_SPACING:
			at = other.position + (away.normalized() if away.length() > 0.001 else Vector3.RIGHT) * PUP_SPACING
	return at


func _unhandled_input(event: InputEvent) -> void:
	var tap: Variant = null
	if event is InputEventScreenTouch and event.pressed:
		tap = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tap = event.position
	if tap == null or pup == null:
		return
	var from := _camera.project_ray_origin(tap)
	var direction := _camera.project_ray_normal(tap)
	if direction.y >= -0.001:
		return
	_pup_target = _clamp_to_pen(from + direction * (-from.y / direction.y))


## The day at the window: now and then someone stops, looks, and walks on —
## or comes in for one of the pups.
func _watch_the_street() -> void:
	for i in humans.size():
		await _wait(_rng.randf_range(2.5, 4.5))
		visit_index = i
		await _stop_and_look(humans[i], 1 if i % 2 == 0 else -1)
		if adopter != null:
			return
	await _wait(2.0)
	_decide()


## How much visitor `index` cares for each pup: the player's first, then the
## litter (a pup already gone counts for nothing).
func interest_by_pup(index: int) -> Array[float]:
	var values: Array[float] = [adoption.interest[index]]
	for k in litter.size():
		values.append(-INF if taken[k] else litter_matches[k].interest[index])
	return values


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
	var choice := AdoptionMatch.who_goes_home(interest_by_pup(visit_index))
	if choice == 0:
		adopter = human
		await _come_in_for_player()
		return
	if choice > 0:
		await _come_in_for_other(choice - 1)
		return
	_say("（他看了一會兒，又走了。）")
	_emote.text = ""
	await _walk(_puppet, Vector3(0, 0, LANE_Z), 0.6)
	await _walk(_puppet, Vector3(from_side * STREET_END, 0, LANE_Z), 3.0)
	_puppet.queue_free()
	_puppet = null


## Nobody came in for the player's pup on the spot: the one who cared most
## (and did not already take another pup home) comes back for it.
func _decide() -> void:
	var best := -1
	for i in humans.size():
		if took_home.has(i):
			continue
		if best < 0 or adoption.interest[i] > adoption.interest[best]:
			best = i
	adopter = humans[best]
	_say("（過了一陣子……門口的鈴響了。）")
	_puppet = _person(adopter)
	_puppet.position = Vector3(STREET_END, 0, LANE_Z)
	await _walk(_puppet, Vector3(DOOR_OUT.x, 0, LANE_Z), 2.0)
	await _come_in_for_player()


## Straight from the window to the door, and in for the player's pup.
func _come_in_for_player() -> void:
	if _emote != null and is_instance_valid(_emote):
		_emote.text = ""
	_say("（他轉身走向門口……門鈴響了。）")
	await _walk(_puppet, DOOR_OUT, 0.8)
	_puppet.position = DOOR_IN
	var kneel := pup.position + Vector3(0.4, 0, -0.25)
	await _walk(_puppet, kneel, 1.2)
	_puppet.set_ambient(false)
	_puppet.rotation.y = atan2(-(pup.position.x - kneel.x), -(pup.position.z - kneel.z))
	_puppet.play_acknowledge(pup.global_position)
	_say("「是剛剛窗邊那隻……就是你了。從今天起，我們是一家人。」")
	for other in _litter_pups:
		if is_instance_valid(other):
			(other.get_node("Motion") as DogModelMotion3D).play_sniff(0.6)
	decided.emit(adopter)
	await _wait(1.6)
	_open_naming()


## Someone fell for another pup: they come in, pick it up and take it home.
## The pen has one less in it, and the player's pup waits on.
func _come_in_for_other(k: int) -> void:
	took_home[visit_index] = k
	var breed := DataRegistry.get_dog_breed(litter[k].breed_id)
	var name := breed.display_name if breed != null else "小狗"
	_emote.text = ""
	_say("（他看著旁邊的%s，往門口走去……）" % name)
	await _walk(_puppet, DOOR_OUT, 0.8)
	_puppet.position = DOOR_IN
	var chosen_pup := _litter_pups[k]
	_wander_rest[k] = 99.0
	await _walk(_puppet, chosen_pup.position + Vector3(0.35, 0, 0.3), 1.0)
	_puppet.set_ambient(false)
	_puppet.play_acknowledge(chosen_pup.global_position)
	await _wait(0.9)
	taken[k] = true
	chosen_pup.queue_free()
	_say("（%s被抱走了。圍欄裡空了一角。）" % name)
	pup_taken.emit(k, humans[visit_index])
	await _walk(_puppet, DOOR_IN, 1.0)
	_puppet.position = DOOR_OUT
	await _walk(_puppet, Vector3(STREET_END, 0, LANE_Z), 2.5)
	_puppet.queue_free()
	_puppet = null


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

## The player's pup does the thing, in its body, where everyone can see it.
func _play_dog(behavior: int) -> void:
	var motion := pup.get_node("Motion") as DogModelMotion3D
	var model := pup.get_node("Model") as Node3D
	var tween := create_tween()
	_pup_busy = 0.8 * pace
	match behavior:
		Behavior.WAG:
			for i in 3:
				tween.tween_property(model, "rotation:z", 0.12, 0.08 * pace)
				tween.tween_property(model, "rotation:z", -0.12, 0.08 * pace)
			tween.tween_property(model, "rotation:z", 0.0, 0.08 * pace)
		Behavior.SIT, Behavior.LIE_DOWN:
			motion.play_sit()
			if behavior == Behavior.LIE_DOWN:
				tween.tween_property(model, "position:y", -0.04, 0.3 * pace)
				tween.tween_interval(0.6 * pace)
				tween.tween_property(model, "position:y", 0.0, 0.2 * pace)
		Behavior.APPROACH, Behavior.LICK_HAND, Behavior.STARE:
			pup.rotation.y = 0.0
			motion.play_sniff(0.6)
		Behavior.BARK:
			_say("汪！")
			tween.tween_property(model, "position:y", 0.06, 0.06 * pace)
			tween.tween_property(model, "position:y", 0.0, 0.08 * pace)
		Behavior.FETCH:
			_toy.visible = true
			_toy.position = pup.position + Vector3(0, 0.12, -0.2)
			tween.tween_interval(0.9 * pace)
		Behavior.IGNORE:
			pup.rotation.y = PI
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
			_puppet.play_acknowledge(pup.global_position)
		Reaction.INTERESTED:
			tween.tween_property(_puppet, "position", STOP + Vector3(0, 0, 0.12), 0.3 * pace)
		Reaction.AMUSED:
			tween.tween_property(_puppet, "position:y", 0.08, 0.1 * pace)
			tween.tween_property(_puppet, "position:y", 0.0, 0.1 * pace)
		Reaction.CAUTIOUS:
			tween.tween_property(_puppet, "position", STOP + Vector3(0, 0, -0.35), 0.3 * pace)
		Reaction.STARTLED:
			_puppet.play_bumped(pup.global_position)
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
		_hint.text = "有人在看。跑到窗前，讓他看看你。" if accepting and actions_left > 0 else "（在圍欄裡跑跑看。點地板或用方向鍵移動。）"


# --- The clinic and the street ------------------------------------------------------

func _build_room() -> void:
	# The same clinic window the player looked in through, from the inside.
	ClinicWindow.build_light(self)
	ClinicWindow.build_inside(self, false)
	ClinicWindow.build_front(self)
	_camera = Camera3D.new()
	_camera.fov = 70.0
	add_child(_camera)
	_camera.look_at_from_position(_camera_rest, Vector3(0, 0.3, -3.2))
	_camera_rest = _camera.position
	_toy = Greybox.sphere(0.05, Color(0.9, 0.85, 0.2), Vector3(0.05, 0.25, -0.2))
	_toy.visible = false
	add_child(_toy)


## The player's own pup: the one picked from the street, with a soft ring at
## its feet so it can be told from its littermates.
func _build_pup() -> void:
	pup = DogVisual3D.build(dog)
	pup.scale = Vector3.ONE * PUPPY_SCALE
	pup.position = Vector3(0, 0, -0.1)
	add_child(pup)
	ClinicWindow.ring(pup)


## The rest of the litter in the pen, each being itself.
func _build_litter() -> void:
	for k in litter.size():
		var other := DogVisual3D.build(litter[k])
		other.scale = Vector3.ONE * PUPPY_SCALE
		other.position = LITTER_SPOTS[k]
		other.rotation.y = _rng.randf_range(-0.6, 0.6)
		add_child(other)
		_litter_pups.append(other)
		_wander_to.append(LITTER_SPOTS[k])
		_wander_rest.append(_rng.randf_range(0.5, 2.5))


## They trot somewhere, stop, sniff, and go somewhere else — and when someone
## is at the window, they tend to go and look too.
func _process_litter(delta: float) -> void:
	for k in _litter_pups.size():
		var other := _litter_pups[k]
		if not is_instance_valid(other) or taken[k]:
			continue
		var motion := other.get_node("Motion") as DogModelMotion3D
		if _wander_rest[k] > 0.0:
			_wander_rest[k] -= delta / pace
			motion.update_motion(delta, 0.0, false)
			continue
		var to: Vector3 = _wander_to[k] - other.position
		to.y = 0.0
		if to.length() < 0.06:
			_wander_rest[k] = _rng.randf_range(0.8, 3.0)
			var near_window := accepting and _rng.randf() < 0.6
			var x := _rng.randf_range(PEN_MIN.x, PEN_MAX.x)
			var z := _rng.randf_range(PEN_MIN.y, PEN_MIN.y + 0.35) if near_window else _rng.randf_range(PEN_MIN.y, PEN_MAX.y)
			_wander_to[k] = Vector3(x, 0, z)
			if _rng.randf() < 0.4:
				motion.play_sniff(0.6)
			continue
		var step := to.normalized() * WANDER_SPEED * delta / pace
		if step.length() > to.length():
			step = to
		other.position = _clamp_to_pen(_keep_apart(other.position + step, k))
		other.rotation.y = lerp_angle(other.rotation.y, atan2(-step.x, -step.z), minf(delta * 10.0, 1.0))
		motion.update_motion(delta, WANDER_SPEED, false)


func _build_street() -> void:
	ClinicWindow.build_street(self)


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
	# See-through, so the pups at the glass stay in view behind it.
	var clear := StyleBoxFlat.new()
	clear.bg_color = Color(0.12, 0.13, 0.14, 0.45)
	clear.set_corner_radius_all(12)
	clear.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", clear)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -290
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
		button.custom_minimum_size = Vector2(0, 66)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.modulate = Color(1, 1, 1, 0.85)
		button.add_theme_font_size_override("font_size", 24)
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
