class_name ShelterScene
extends Node3D
## Sprint 06 (S06-02, D6-01): a new game starts at the shelter, looking at the
## dogs waiting there. "Which dog am I?", not a character creator: each dog is
## its breed, a couple of things the staff can tell you, and something you
## cannot see yet. No stats, no rarity, no reroll (ADR-020).

signal dog_chosen(dog: DogCandidate)

const DOG_COUNT: int = 5
const PEN_SPACING: float = 2.2
const STAFF_LINE := "慢慢看，每一隻都在等一個家。"

## Seed for who is waiting today (0 = a new one).
@export var seed_value: int = 0

var dogs: Array[DogCandidate] = []
var selected: int = 0

var _pivots: Array[Node3D] = []
var _camera: Camera3D
var _camera_target := Vector3.ZERO
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
	for i in dogs.size():
		_build_pen(i)
	_build_camera()
	_build_ui()
	select(DOG_COUNT / 2)
	_camera.global_position = _camera_target


func _process(delta: float) -> void:
	_camera.global_position = _camera.global_position.lerp(_camera_target, minf(delta * 5.0, 1.0))
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


## Looks at dog `index`: the camera moves to its pen and the card says what
## the staff can tell about it.
func select(index: int) -> void:
	selected = wrapi(index, 0, dogs.size())
	var dog := dogs[selected]
	_camera_target = _pen_position(selected) + Vector3(0.0, 1.0, 2.6)
	var breed := DataRegistry.get_dog_breed(dog.breed_id)
	_name_label.text = breed.display_name if breed != null else "狗狗"
	_name_label.modulate = dog.collar_color().lightened(0.35)
	_traits_label.text = describe(dog)
	(_pivots[selected].get_node("Motion") as DogModelMotion3D).play_sniff(0.6)


## What you can tell from outside the pen. The hidden trait is a feeling, not
## a blank to be filled in.
static func describe(dog: DogCandidate) -> String:
	var lines: Array[String] = []
	for id in dog.visible_trait_ids:
		var t := DataRegistry.get_dog_trait(id)
		if t != null:
			lines.append("・" + t.text)
	lines.append("・還有一點看不出來……要一起生活才知道。")
	return "\n".join(lines)


## This one. Hands the dog on; the adoption itself is the next step.
func choose() -> void:
	var dog := dogs[selected]
	dog_chosen.emit(dog)
	Game.choose_dog(dog)


func _pen_position(index: int) -> Vector3:
	return Vector3((index - (dogs.size() - 1) / 2.0) * PEN_SPACING, 0.0, 0.0)


func _pick_at(screen_position: Vector2) -> void:
	var from := _camera.project_ray_origin(screen_position)
	var direction := _camera.project_ray_normal(screen_position)
	if absf(direction.y) < 0.001:
		return
	var hit := from + direction * (-from.y / direction.y)
	for i in dogs.size():
		if i != selected and absf(hit.x - _pen_position(i).x) < PEN_SPACING * 0.5 and absf(hit.z) < 1.4:
			select(i)
			return


func _build_room() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.86, 0.84, 0.78)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.85, 0.82, 0.78)
	env.environment.ambient_light_energy = 0.7
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 25, 0)
	sun.shadow_enabled = true
	add_child(sun)
	var width := PEN_SPACING * (DOG_COUNT + 1)
	add_child(Greybox.box(Vector3(width, 0.05, 6.0), Color(0.72, 0.7, 0.64), Vector3(0, -0.025, 0)))
	add_child(Greybox.box(Vector3(width, 3.0, 0.1), Color(0.93, 0.9, 0.82), Vector3(0, 1.5, -1.6)))


## A low pen with a blanket: a dog waiting, not a product on a shelf.
func _build_pen(index: int) -> void:
	var at := _pen_position(index)
	var fence := Color(0.55, 0.62, 0.6)
	add_child(Greybox.box(Vector3(0.05, 0.6, 2.4), fence, at + Vector3(-PEN_SPACING * 0.5, 0.3, -0.3)))
	add_child(Greybox.box(Vector3(PEN_SPACING, 0.6, 0.05), fence, at + Vector3(0, 0.3, -1.5)))
	add_child(Greybox.box(Vector3(1.0, 0.03, 0.8), dogs[index].collar_color().lerp(Color(0.93, 0.88, 0.78), 0.55), at + Vector3(0, 0.015, -0.6)))
	if index == dogs.size() - 1:
		add_child(Greybox.box(Vector3(0.05, 0.6, 2.4), fence, at + Vector3(PEN_SPACING * 0.5, 0.3, -0.3)))
	var pivot := DogVisual3D.build(dogs[index])
	pivot.position = at
	# Facing the visitor, not the back wall.
	pivot.rotation.y = PI
	add_child(pivot)
	_pivots.append(pivot)


func _build_camera() -> void:
	_camera = Camera3D.new()
	_camera.fov = 50.0
	add_child(_camera)
	_camera.rotation_degrees.x = -14.0


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var staff := Label.new()
	staff.text = STAFF_LINE
	staff.add_theme_font_size_override("font_size", 28)
	staff.add_theme_color_override("font_color", Color(0.2, 0.22, 0.22))
	staff.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	staff.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	staff.offset_top = 40
	layer.add_child(staff)
	var card := PanelContainer.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	card.offset_top = -330
	card.offset_left = 24
	card.offset_right = -24
	card.offset_bottom = -24
	layer.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	_name_label = Label.new()
	_name_label.name = "DogName"
	_name_label.add_theme_font_size_override("font_size", 34)
	box.add_child(_name_label)
	_traits_label = Label.new()
	_traits_label.name = "DogTraits"
	_traits_label.add_theme_font_size_override("font_size", 26)
	_traits_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_traits_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	row.add_child(_button("◀", func() -> void: select(selected - 1), 1.0))
	row.add_child(_button("🐾 就是牠了", choose, 2.0))
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
