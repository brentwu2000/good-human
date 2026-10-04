class_name ShelterScene
extends Node3D
## Sprint 06 (S06-02, D6-01; owner direction 2026-10-05: 「真實一點的動物醫院
## 感覺」): a new game starts in a small animal hospital, in front of the stacked
## cages where a few puppies are waiting. Each cage has its card — breed, boy
## or girl, how old — and the staff can tell you a couple of things about each
## pup; something about it nobody can tell yet. No stats, no rarity, no reroll
## (ADR-020).

signal dog_chosen(dog: DogCandidate)

const DOG_COUNT: int = 5
## Cages on the wall: two rows of three, one of them empty.
const COLUMNS: int = 3
const CAGE_SIZE := Vector3(0.95, 0.72, 0.75)
const CAGE_GAP: float = 0.08
const ROW_HEIGHTS: Array[float] = [0.12, 0.92]
## Puppies, not grown dogs.
const PUPPY_SCALE: float = 0.62
const STAFF_LINE := "這幾隻都是最近送來的，慢慢看沒關係。"

## Seed for who is waiting today (0 = a new one).
@export var seed_value: int = 0

var dogs: Array[DogCandidate] = []
var selected: int = 0

var _pivots: Array[Node3D] = []
var _camera: Camera3D
var _camera_target := Vector3.ZERO
var _look_target := Vector3.ZERO
var _name_label: Label
var _traits_label: Label


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value
	dogs = DogCandidateGenerator.generate(rng, DOG_COUNT, DataRegistry.dog_breeds, DataRegistry.dog_traits)
	_build_room()
	for i in COLUMNS * ROW_HEIGHTS.size():
		_build_cage(i)
	_build_camera()
	_build_ui()
	select(0)
	_camera.global_position = _camera_target
	_camera.look_at(_look_target)


func _process(delta: float) -> void:
	_camera.global_position = _camera.global_position.lerp(_camera_target, minf(delta * 4.0, 1.0))
	var facing := _camera.global_transform.looking_at(_look_target).basis
	_camera.global_basis = _camera.global_basis.slerp(facing, minf(delta * 4.0, 1.0))
	for pivot in _pivots:
		(pivot.get_node("Motion") as DogModelMotion3D).update_motion(delta, 0.0, false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"move_left"):
		select(selected - 1)
	elif event.is_action_pressed(&"move_right"):
		select(selected + 1)
	elif event.is_action_pressed(&"interact"):
		choose()
	elif event is InputEventScreenTouch and event.pressed:
		_pick_at(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_pick_at(event.position)


## Leans in to cage `index`: the view comes to the pup's eye level and the
## clipboard shows its card.
func select(index: int) -> void:
	selected = wrapi(index, 0, dogs.size())
	var cage := _cage_centre(selected)
	_look_target = cage + Vector3(0, -0.45, 0)
	_camera_target = cage + Vector3(0.0, 0.1, 2.3)
	var dog := dogs[selected]
	_name_label.text = card_title(dog)
	_traits_label.text = describe(dog)
	(_pivots[selected].get_node("Motion") as DogModelMotion3D).play_sniff(0.6)


## The cage card: breed, boy or girl, age — what is written on a real one.
static func card_title(dog: DogCandidate) -> String:
	var breed := DataRegistry.get_dog_breed(dog.breed_id)
	var sex := "♂" if absi(dog.appearance_seed) % 2 == 0 else "♀"
	var months := 2 + absi(dog.appearance_seed / 7) % 4
	return "%s　%s　%d 個月" % [breed.display_name if breed != null else "米克斯", sex, months]


## What the staff can tell you. The hidden trait is a feeling, not a blank.
static func describe(dog: DogCandidate) -> String:
	var lines: Array[String] = []
	for id in dog.visible_trait_ids:
		var t := DataRegistry.get_dog_trait(id)
		if t != null:
			lines.append("・" + t.text)
	lines.append("・還有一點看不出來……要一起生活才知道。")
	return "\n".join(lines)


## This one. It is lifted out of its cage; the adoption is the next step.
func choose() -> void:
	var dog := dogs[selected]
	dog_chosen.emit(dog)
	# The rest of the litter goes to the window too: anyone stopping there
	# might fall for one of them instead.
	Game.choose_dog(dog, dogs.filter(func(d: DogCandidate) -> bool: return d != dog))


## Cage slot `slot` (0..5): left to right along the bottom row, then the top.
## The pups take the first DOG_COUNT slots in a shuffled-looking order; the
## remaining one stays empty, a towel and a water bowl.
func _cage_slot(index: int) -> int:
	return [0, 4, 2, 3, 1, 5][index]


func _slot_centre(slot: int) -> Vector3:
	var column := slot % COLUMNS
	var row := slot / COLUMNS
	var x := (column - (COLUMNS - 1) / 2.0) * (CAGE_SIZE.x + CAGE_GAP)
	return Vector3(x, ROW_HEIGHTS[row] + CAGE_SIZE.y * 0.5, -1.0)


func _cage_centre(index: int) -> Vector3:
	return _slot_centre(_cage_slot(index))


func _pick_at(screen_position: Vector2) -> void:
	var from := _camera.project_ray_origin(screen_position)
	var direction := _camera.project_ray_normal(screen_position)
	if absf(direction.z) < 0.001:
		return
	var hit := from + direction * ((-1.0 + CAGE_SIZE.z * 0.5 - from.z) / direction.z)
	for i in dogs.size():
		var centre := _cage_centre(i)
		if i != selected and absf(hit.x - centre.x) < CAGE_SIZE.x * 0.5 and absf(hit.y - centre.y) < CAGE_SIZE.y * 0.5:
			select(i)
			return


func _build_room() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.9, 0.93, 0.93)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	# Fluorescent: cool, even, a little flat.
	env.environment.ambient_light_color = Color(0.86, 0.92, 0.94)
	env.environment.ambient_light_energy = 0.85
	add_child(env)
	var tube := DirectionalLight3D.new()
	tube.rotation_degrees = Vector3(-70, 10, 0)
	tube.light_color = Color(0.93, 0.98, 1.0)
	tube.light_energy = 0.8
	tube.shadow_enabled = true
	add_child(tube)
	# Pale tiles, a mint wainscot under white walls, a strip light.
	add_child(Greybox.box(Vector3(6, 0.04, 5), Color(0.82, 0.84, 0.83), Vector3(0, -0.02, 0.5)))
	for x in range(-3, 4):
		add_child(Greybox.box(Vector3(0.012, 0.045, 5), Color(0.72, 0.75, 0.74), Vector3(x * 0.5, -0.015, 0.5)))
	add_child(Greybox.box(Vector3(6, 3.0, 0.1), Color(0.95, 0.96, 0.95), Vector3(0, 1.5, -1.5)))
	add_child(Greybox.box(Vector3(6, 1.0, 0.02), Color(0.72, 0.86, 0.82), Vector3(0, 0.5, -1.44)))
	add_child(Greybox.box(Vector3(1.6, 0.05, 0.2), Color(1.0, 1.0, 0.97), Vector3(0, 2.75, -1.0)))
	# A notice board and a scale: the waiting area of an ordinary clinic.
	add_child(Greybox.box(Vector3(0.6, 0.8, 0.02), Color(0.86, 0.74, 0.55), Vector3(-2.0, 1.9, -1.43)))
	add_child(Greybox.box(Vector3(0.22, 0.28, 0.01), Color(0.98, 0.96, 0.9), Vector3(-2.1, 2.0, -1.415)))
	add_child(Greybox.box(Vector3(0.2, 0.16, 0.01), Color(0.95, 0.85, 0.85), Vector3(-1.88, 1.78, -1.415)))
	add_child(Greybox.box(Vector3(0.7, 0.06, 0.5), Color(0.6, 0.62, 0.64), Vector3(2.1, 0.03, -0.8)))


## A stainless cage with a barred door, a towel and, for a pup, the pup.
func _build_cage(slot: int) -> void:
	var at := _slot_centre(slot)
	var steel := Color(0.74, 0.77, 0.79)
	var dark := Color(0.55, 0.58, 0.6)
	var size := CAGE_SIZE
	add_child(Greybox.box(Vector3(size.x, 0.03, size.z), dark, at + Vector3(0, -size.y * 0.5, 0)))
	add_child(Greybox.box(Vector3(size.x, 0.03, size.z), steel, at + Vector3(0, size.y * 0.5, 0)))
	add_child(Greybox.box(Vector3(0.03, size.y, size.z), steel, at + Vector3(-size.x * 0.5, 0, 0)))
	add_child(Greybox.box(Vector3(0.03, size.y, size.z), steel, at + Vector3(size.x * 0.5, 0, 0)))
	add_child(Greybox.box(Vector3(size.x, size.y, 0.02), Color(0.88, 0.9, 0.9), at + Vector3(0, 0, -size.z * 0.5)))
	var front := size.z * 0.5
	var bars := 11
	for b in bars:
		var x := -size.x * 0.5 + 0.06 + b * (size.x - 0.12) / (bars - 1)
		add_child(Greybox.cylinder(0.008, size.y, steel.lightened(0.15), at + Vector3(x, 0, front)))
	add_child(Greybox.box(Vector3(size.x, 0.03, 0.03), steel, at + Vector3(0, size.y * 0.5 - 0.02, front)))
	add_child(Greybox.box(Vector3(size.x, 0.03, 0.03), steel, at + Vector3(0, -size.y * 0.5 + 0.03, front)))
	var index := [0, 4, 2, 3, 1, 5].find(slot)
	var towel := Color(0.78, 0.86, 0.92) if index < 0 or index >= dogs.size() else dogs[index].collar_color().lerp(Color(0.92, 0.9, 0.86), 0.65)
	add_child(Greybox.box(Vector3(size.x * 0.7, 0.02, size.z * 0.6), towel, at + Vector3(0, -size.y * 0.5 + 0.03, -0.05)))
	if index < 0 or index >= dogs.size():
		# The empty cage: a bowl, as if someone just went home.
		add_child(Greybox.cylinder(0.08, 0.05, Color(0.7, 0.72, 0.75), at + Vector3(0.25, -size.y * 0.5 + 0.05, 0.1)))
		return
	var card := Greybox.label(card_title(dogs[index]).split("　")[0], 0.0, 22, Color(0.25, 0.27, 0.28), 6.0)
	card.position = at + Vector3(0, -size.y * 0.5 - 0.05, front + 0.03)
	card.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	card.pixel_size = 0.0011
	add_child(card)
	add_child(Greybox.box(Vector3(0.3, 0.09, 0.005), Color(0.99, 0.98, 0.94), card.position + Vector3(0, 0, -0.006)))
	var pivot := DogVisual3D.build(dogs[index])
	pivot.scale = Vector3.ONE * PUPPY_SCALE
	pivot.position = at + Vector3(0, -size.y * 0.5 + 0.04, 0.0)
	# Facing whoever is looking in, not the back of the cage.
	pivot.rotation.y = PI
	add_child(pivot)
	if _pivots.size() <= index:
		_pivots.resize(index + 1)
	_pivots[index] = pivot


func _build_camera() -> void:
	_camera = Camera3D.new()
	_camera.fov = 55.0
	add_child(_camera)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var staff := Label.new()
	staff.text = "「%s」" % STAFF_LINE
	staff.add_theme_font_size_override("font_size", 26)
	staff.add_theme_color_override("font_color", Color(0.22, 0.26, 0.27))
	staff.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	staff.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	staff.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	staff.offset_top = 40
	staff.offset_left = 24
	staff.offset_right = -24
	layer.add_child(staff)
	# The clipboard: a paper card, not a stat panel.
	var card := PanelContainer.new()
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color(0.98, 0.97, 0.92)
	paper.border_color = Color(0.55, 0.45, 0.32)
	paper.set_border_width_all(0)
	paper.border_width_top = 14
	paper.set_corner_radius_all(10)
	paper.set_content_margin_all(22)
	card.add_theme_stylebox_override("panel", paper)
	card.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	card.offset_top = -380
	card.offset_left = 24
	card.offset_right = -24
	card.offset_bottom = -24
	layer.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	_name_label = Label.new()
	_name_label.name = "DogName"
	_name_label.add_theme_font_size_override("font_size", 32)
	_name_label.add_theme_color_override("font_color", Color(0.2, 0.22, 0.22))
	box.add_child(_name_label)
	_traits_label = Label.new()
	_traits_label.name = "DogTraits"
	_traits_label.add_theme_font_size_override("font_size", 26)
	_traits_label.add_theme_color_override("font_color", Color(0.3, 0.32, 0.32))
	_traits_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_traits_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	row.add_child(_button("◀", func() -> void: select(selected - 1), 1.0))
	row.add_child(_button("抱出來看看", choose, 2.0))
	row.add_child(_button("▶", func() -> void: select(selected + 1), 1.0))


func _button(text: String, action: Callable, stretch: float) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 88)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_stretch_ratio = stretch
	button.add_theme_font_size_override("font_size", 28)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	return button
