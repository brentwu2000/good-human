class_name ShelterScene
extends Node3D
## Sprint 06 (S06-02, D6-01; owner direction 2026-10-05: 「不要像賣寵物的場景，
## 應該是像選主人畫面一樣，只是從外面往內看」「狗狗一樣會在場景中移動，左右切換
## 也可以」): a new game starts on the pavement outside a small animal hospital,
## looking in through its front window at the pen where a few puppies run
## about. The same pen the pup will later look out from (ClinicWindow). The
## pups wander, sniff, come to the glass; ◀ ▶ (or a tap on a pup) picks which
## one to watch, and that one shows what it is like in how it meets your look.
## What can be seen of it is said in words, plus something nobody can tell yet.
## No stats, no rarity, no reroll (ADR-020).

signal dog_chosen(dog: DogCandidate)

const DOG_COUNT: int = 5
const PUPPY_SCALE: float = ClinicWindow.PUPPY_SCALE
const PEN_MIN := ClinicWindow.PEN_MIN
const PEN_MAX := ClinicWindow.PEN_MAX
const WANDER_SPEED: float = 1.0
## The one being watched trots a little quicker to (or away from) the glass.
const WATCHED_SPEED: float = 1.4
const PUP_SPACING: float = 0.32
const START_SPOTS: Array[Vector3] = [Vector3(0.0, 0, -0.75), Vector3(-0.75, 0, -0.45), Vector3(0.7, 0, -0.9), Vector3(-0.3, 0, -0.05), Vector3(0.9, 0, -0.15)]
## The player, crouched on the pavement a step from the glass.
const VIEW_HEIGHT: float = 1.2
const VIEW_Z: float = -3.35
## Where the view rests: the middle of the pen, leaning towards the one watched.
const PEN_CENTRE := Vector3(0, 0.75, -0.55)
const OPENING_LINE := "（路過動物醫院的窗前。玻璃後面，幾隻小狗跑來跑去。）"

## Seed for who is in the window today (0 = a new one).
@export var seed_value: int = 0

var dogs: Array[DogCandidate] = []
var selected: int = 0

## One per dog, in the same order: the pups in the pen.
var _pivots: Array[Node3D] = []
var _wander_to: Array[Vector3] = []
var _wander_rest: Array[float] = []
var _rng := RandomNumberGenerator.new()
var _ring: MeshInstance3D
var _camera: Camera3D
var _look := Vector3(0, 0.15, -0.6)
var _line: Label
var _name_label: Label
var _traits_label: Label


func _ready() -> void:
	if seed_value == 0:
		_rng.randomize()
	else:
		_rng.seed = seed_value
	dogs = DogCandidateGenerator.generate(_rng, DOG_COUNT, DataRegistry.dog_breeds, DataRegistry.dog_traits)
	ClinicWindow.build_light(self)
	ClinicWindow.build_inside(self)
	ClinicWindow.build_front(self)
	ClinicWindow.build_street(self)
	for i in dogs.size():
		_build_pup(i)
	_camera = Camera3D.new()
	_camera.fov = 60.0
	add_child(_camera)
	_build_ui()
	select(0)
	_line.text = OPENING_LINE
	_camera.position = _camera_spot()
	_camera.look_at(_look)


func _process(delta: float) -> void:
	for i in _pivots.size():
		_move(i, delta)
	# Shift along the pavement a little to keep the one being watched in view.
	var pup := _pivots[selected]
	_look = _look.lerp(PEN_CENTRE.lerp(pup.position, 0.4), minf(delta * 3.0, 1.0))
	_camera.position = _camera.position.lerp(_camera_spot(), minf(delta * 2.0, 1.0))
	_camera.look_at(_look)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"move_left"):
		select_step(-1)
	elif event.is_action_pressed(&"move_right"):
		select_step(1)
	elif event.is_action_pressed(&"interact"):
		choose()
	elif event is InputEventScreenTouch and event.pressed:
		_pick_at(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_pick_at(event.position)


## Watch pup `index`: the ring moves to it, the card says what can be seen of
## it, and it meets your look the way it is.
func select(index: int) -> void:
	selected = wrapi(index, 0, dogs.size())
	var dog := dogs[selected]
	_name_label.text = card_title(dog)
	_traits_label.text = describe(dog)
	if _ring != null:
		_ring.queue_free()
	_ring = ClinicWindow.ring(_pivots[selected])
	_line.text = _meets_your_look(selected)


## The pups left to right as seen from the street: ◀ ▶ go along the pen
## rather than in an order nobody can see.
func select_step(step: int) -> void:
	var order: Array[int] = []
	for i in dogs.size():
		order.append(i)
	# From outside the window, +x inside is on the viewer's left.
	order.sort_custom(func(a: int, b: int) -> bool: return _pivots[a].position.x > _pivots[b].position.x)
	select(order[wrapi(order.find(selected) + step, 0, order.size())])


## What is written about a pup: breed, boy or girl, age.
static func card_title(dog: DogCandidate) -> String:
	var breed := DataRegistry.get_dog_breed(dog.breed_id)
	var sex := "♂" if absi(dog.appearance_seed) % 2 == 0 else "♀"
	var months := 2 + absi(dog.appearance_seed / 7) % 4
	return "%s　%s　%d 個月" % [breed.display_name if breed != null else "米克斯", sex, months]


## What can be seen. The hidden trait is a feeling, not a blank.
static func describe(dog: DogCandidate) -> String:
	var lines: Array[String] = []
	for id in dog.visible_trait_ids:
		var t := DataRegistry.get_dog_trait(id)
		if t != null:
			lines.append("・" + t.text)
	lines.append("・還有一點看不出來……要一起生活才知道。")
	return "\n".join(lines)


## How keen a pup is to come to whoever looks in, from what can be seen of it
## only (the hidden trait shows later, living together).
static func forwardness(dog: DogCandidate) -> float:
	var total := 0.0
	for id in dog.visible_trait_ids:
		var t := DataRegistry.get_dog_trait(id)
		if t == null:
			continue
		for behavior: int in [DogTraitData.Behavior.APPROACH, DogTraitData.Behavior.LICK_HAND, DogTraitData.Behavior.WAG]:
			total += t.behavior_affinity.get(behavior, 0.0)
		total -= t.behavior_affinity.get(DogTraitData.Behavior.IGNORE, 0.0)
	return total


## This one. The player becomes it, inside, in the next scene.
func choose() -> void:
	var dog := dogs[selected]
	dog_chosen.emit(dog)
	# The rest of the litter stays in the window too: anyone stopping there
	# might fall for one of them instead.
	Game.choose_dog(dog, dogs.filter(func(d: DogCandidate) -> bool: return d != dog))


## The watched pup comes to the glass in front of you, or keeps its distance
## and peeks; the others go on with their own business.
func _meets_your_look(index: int) -> String:
	var keen := forwardness(dogs[index])
	var front := Vector3(clampf(_camera_spot().x, PEN_MIN.x, PEN_MAX.x), 0, PEN_MIN.y)
	_wander_rest[index] = 0.0
	if keen > 0.25:
		_wander_to[index] = front
		return "（牠一看到你，就跑到玻璃前面來了。）"
	if keen < -0.15:
		_wander_to[index] = Vector3(clampf(-front.x, PEN_MIN.x, PEN_MAX.x), 0, PEN_MAX.y)
		return "（牠往圍欄後面縮了一下，又偷偷看著你。）"
	_wander_to[index] = front.lerp(_pivots[index].position, 0.5)
	return "（牠聞了聞地上，抬頭看了你一眼。）"


## Where the player crouches: in front of the window, drifting a little
## towards the pup being watched.
func _camera_spot() -> Vector3:
	var x := 0.0
	if not _pivots.is_empty():
		x = _pivots[selected].position.x * 0.35
	return Vector3(x, VIEW_HEIGHT, VIEW_Z)


## They trot somewhere, stop, sniff, and go somewhere else; resting at the
## glass, they look out at you.
func _move(i: int, delta: float) -> void:
	var pup := _pivots[i]
	var motion := pup.get_node("Motion") as DogModelMotion3D
	if _wander_rest[i] > 0.0:
		_wander_rest[i] -= delta
		if pup.position.z < PEN_MIN.y + 0.3 or i == selected:
			var to_you := _camera.position - pup.position
			pup.rotation.y = lerp_angle(pup.rotation.y, atan2(-to_you.x, -to_you.z), minf(delta * 4.0, 1.0))
		motion.update_motion(delta, 0.0, false)
		return
	var to: Vector3 = _wander_to[i] - pup.position
	to.y = 0.0
	if to.length() < 0.06:
		# The one being watched lingers where it went; the others move on.
		_wander_rest[i] = _rng.randf_range(2.5, 5.0) if i == selected else _rng.randf_range(0.8, 3.0)
		_wander_to[i] = Vector3(_rng.randf_range(PEN_MIN.x, PEN_MAX.x), 0, _rng.randf_range(PEN_MIN.y, PEN_MAX.y))
		if _rng.randf() < 0.4:
			motion.play_sniff(0.6)
		return
	var speed := WATCHED_SPEED if i == selected else WANDER_SPEED
	var step := to.normalized() * speed * delta
	if step.length() > to.length():
		step = to
	pup.position = _clamp_to_pen(_keep_apart(pup.position + step, i))
	pup.rotation.y = lerp_angle(pup.rotation.y, atan2(-step.x, -step.z), minf(delta * 10.0, 1.0))
	motion.update_motion(delta, speed, false)


func _clamp_to_pen(at: Vector3) -> Vector3:
	return Vector3(clampf(at.x, PEN_MIN.x, PEN_MAX.x), 0.0, clampf(at.z, PEN_MIN.y, PEN_MAX.y))


## Pups bump and go round each other rather than through.
func _keep_apart(at: Vector3, self_index: int) -> Vector3:
	for k in _pivots.size():
		if k == self_index:
			continue
		var away := at - _pivots[k].position
		away.y = 0.0
		if away.length() < PUP_SPACING:
			at = _pivots[k].position + (away.normalized() if away.length() > 0.001 else Vector3.RIGHT) * PUP_SPACING
	return at


## A tap on (or near) a pup watches that one.
func _pick_at(screen_position: Vector2) -> void:
	var best := -1
	var best_distance := 70.0
	for i in _pivots.size():
		var at := _pivots[i].position + Vector3(0, 0.12, 0)
		if _camera.is_position_behind(at):
			continue
		var d := _camera.unproject_position(at).distance_to(screen_position)
		if d < best_distance:
			best_distance = d
			best = i
	if best >= 0 and best != selected:
		select(best)


func _build_pup(i: int) -> void:
	var pup := DogVisual3D.build(dogs[i])
	pup.scale = Vector3.ONE * PUPPY_SCALE
	pup.position = START_SPOTS[i % START_SPOTS.size()]
	pup.rotation.y = PI + _rng.randf_range(-0.8, 0.8)
	add_child(pup)
	_pivots.append(pup)
	_wander_to.append(pup.position)
	_wander_rest.append(_rng.randf_range(0.3, 2.0))


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_line = Label.new()
	_line.name = "Line"
	_line.add_theme_font_size_override("font_size", 26)
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
	# See-through, like the panel inside, so the pen stays in view behind it.
	var panel := PanelContainer.new()
	var clear := StyleBoxFlat.new()
	clear.bg_color = Color(0.12, 0.13, 0.14, 0.45)
	clear.set_corner_radius_all(12)
	clear.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", clear)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -300
	panel.offset_left = 16
	panel.offset_right = -16
	panel.offset_bottom = -16
	layer.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	_name_label = Label.new()
	_name_label.name = "DogName"
	_name_label.add_theme_font_size_override("font_size", 30)
	box.add_child(_name_label)
	_traits_label = Label.new()
	_traits_label.name = "DogTraits"
	_traits_label.add_theme_font_size_override("font_size", 24)
	_traits_label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.9))
	_traits_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_traits_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	row.add_child(_button("◀", func() -> void: select_step(-1), 1.0))
	row.add_child(_button("🐾 就是牠了", choose, 2.0))
	row.add_child(_button("▶", func() -> void: select_step(1), 1.0))


func _button(text: String, action: Callable, stretch: float) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 80)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_stretch_ratio = stretch
	button.modulate = Color(1, 1, 1, 0.9)
	button.add_theme_font_size_override("font_size", 26)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	return button
