class_name OpponentPair3D
extends Interactable3D
## 3D dog + human pair. The dog provokes it by interacting; the fight happens
## right here while the dog stays free. Mirrors OpponentPair (2D).

signal provoked(pair: OpponentPair3D)

enum State { IDLE, COMBAT, RETURNING, BEATEN }

const GROUP: StringName = &"opponent_pairs_3d"
const RETURN_SPEED: float = 1.6

@export var spot_id: StringName
## Fixed pair for this spot. Empty = assigned from the ordinary pool each walk.
@export var fixed_encounter: EncounterData
## Only present once the dog has discovered this goal flag (empty = always).
@export var required_flag: StringName
## Gone once this flag is set, so the same dog is never in two places at once
## (Sprint 05: 阿黑 stops loitering in the alley once he is back at his tree).
@export var retired_by_flag: StringName

var encounter: EncounterData

var state: State = State.IDLE
var coordinator: CombatCoordinator3D
var human_puppet: FighterPuppet3D
var presentation: EncounterPresentation3D

var _dog: Node3D
## ADR-016: bodies the player's dog cannot walk through.
var _human_presence: PhysicalPresence3D
var _dog_presence: PhysicalPresence3D
var _name_label: Label3D
var _dog_label: Label3D
var _dog_label_left: float = 0.0
var _dog_lunge: Vector3 = Vector3.ZERO
var _time: float = 0.0

## Opponent dog reactions (Sprint 04 basic hooks).
const WATCH_DISTANCE: float = 6.0
const SNIFF_DISTANCE: float = 1.3


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	prompt = "😤 挑釁"
	human_puppet = FighterPuppet3D.new()
	add_child(human_puppet)
	_name_label = Greybox.label("", 2.0, 30)
	add_child(_name_label)
	_dog_label = Greybox.label("", 1.0, 36, Color(1.0, 0.9, 0.5))
	add_child(_dog_label)
	presentation = EncounterPresentation3D.new()
	add_child(presentation)
	add_interaction_area(1.2)
	setup(fixed_encounter)


func setup(data: EncounterData) -> void:
	encounter = data
	state = State.IDLE
	if presentation != null:
		presentation.set_visual_state(EncounterPresentation3D.VisualState.IDLE)
	visible = is_present()
	if encounter == null:
		return
	_name_label.modulate = Color.WHITE
	human_puppet.apply(encounter.human)
	_fit_human_presence()
	human_puppet.position = Vector3.ZERO
	human_puppet.show_hp(false)
	if _dog != null:
		_dog.queue_free()
	_dog = Greybox.dog(encounter.dog_color, encounter.dog_scale, encounter.dog_breed)
	add_child(_dog)
	_dog_presence = PhysicalPresence3D.for_dog(DataRegistry.presence, encounter.dog_scale)
	_dog.add_child(_dog_presence)
	_dog_presence.dog_contact.connect(_on_dog_bumped)
	if encounter.id == &"enc_rival":
		BanyanRivalPair3D.decorate(human_puppet, _dog)
	_name_label.text = "%s和%s" % [encounter.human.display_name, encounter.dog_name]
	_place_dog()


## In the world this walk (has a pair and any required discovery).
func is_present() -> bool:
	if encounter == null or not Game.goal_progress.has_flag(required_flag):
		return false
	return retired_by_flag.is_empty() or not Game.goal_progress.flags.has(retired_by_flag)


func refresh_presence() -> void:
	visible = is_present()


## Marks the pair as what the dog currently wants.
func set_hinted(value: bool) -> void:
	if encounter == null:
		return
	var label := "%s和%s" % [encounter.human.display_name, encounter.dog_name]
	_name_label.text = "❗ " + label if value else label
	if value:
		_name_label.modulate = Color(1.0, 0.85, 0.4)
	else:
		_name_label.modulate = Color(0.6, 0.6, 0.6) if state == State.BEATEN else Color.WHITE
	if presentation != null and state == State.IDLE:
		presentation.set_visual_state(EncounterPresentation3D.VisualState.HINTED if value else EncounterPresentation3D.VisualState.IDLE)


func is_idle() -> bool:
	return state == State.IDLE


func can_interact(context: Object) -> bool:
	var run := context as RunManager
	if not enabled or not is_present() or state != State.IDLE or run == null or not run.is_running():
		return false
	return coordinator == null or coordinator.can_provoke(self)


func interact(context: Object) -> void:
	if can_interact(context):
		provoked.emit(self)


func human_global_position() -> Vector3:
	return human_puppet.global_position


func set_human_global_position(value: Vector3) -> void:
	human_puppet.global_position = value
	_place_dog()


func begin_combat() -> void:
	state = State.COMBAT
	human_puppet.set_fighting()
	human_puppet.show_hp(true)
	if presentation != null:
		presentation.set_visual_state(EncounterPresentation3D.VisualState.COMBAT)


func end_combat(result: CombatSimulation.Result) -> void:
	human_puppet.show_hp(false)
	if result == CombatSimulation.Result.VICTORY:
		state = State.BEATEN
		human_puppet.set_beaten(true)
		_name_label.modulate = Color(0.6, 0.6, 0.6)
		if presentation != null:
			presentation.set_visual_state(EncounterPresentation3D.VisualState.BEATEN)
	else:
		state = State.RETURNING
		if presentation != null:
			presentation.set_visual_state(EncounterPresentation3D.VisualState.IDLE)


func show_combat_impact(blocked: bool = false, weight: float = 0.5, contact_world: Vector3 = Vector3.ZERO, dog_opening: bool = false) -> void:
	if presentation != null:
		presentation.pulse_impact(blocked, weight, contact_world, dog_opening)


func is_beaten() -> bool:
	return state == State.BEATEN


## Barks back and lunges towards a barking dog.
func react_to_bark(from: Vector3) -> void:
	if _dog == null:
		return
	_show_dog_text("汪汪！")
	var towards := from - _dog.global_position
	towards.y = 0.0
	_dog_lunge = towards.normalized() * minf(0.8, towards.length() * 0.5) if towards.length() > 0.01 else Vector3.ZERO


## The standing body follows the fighter's build.
func _fit_human_presence() -> void:
	if _human_presence != null:
		_human_presence.queue_free()
	_human_presence = PhysicalPresence3D.for_human(DataRegistry.presence, encounter.human.body_scale)
	human_puppet.add_child(_human_presence)
	_human_presence.dog_contact.connect(func(from: Vector3, _speed: float) -> void: human_puppet.play_bumped(from))


## Their dog got run into: it steps back from the one who did it.
func _on_dog_bumped(from: Vector3, _speed: float) -> void:
	var away := _dog.global_position - from
	away.y = 0.0
	if away.length_squared() > 0.0001:
		_dog_lunge = away.normalized() * 0.25


func _show_dog_text(text: String) -> void:
	_dog_label.text = text
	_dog_label_left = 0.9


func _update_dog_reactions(delta: float) -> void:
	_dog_label_left -= delta
	if _dog_label_left <= 0.0:
		_dog_label.text = ""
	_dog_lunge = _dog_lunge.move_toward(Vector3.ZERO, 1.5 * delta)
	var player_dog: Node3D = coordinator.dog if coordinator != null else null
	if _dog == null or player_dog == null or not visible:
		return
	var to_player := player_dog.global_position - _dog.global_position
	to_player.y = 0.0
	if to_player.length() <= WATCH_DISTANCE:
		_dog.rotation.y = lerp_angle(_dog.rotation.y, atan2(-to_player.x, -to_player.z), minf(delta * 6.0, 1.0))
		if state == State.IDLE and to_player.length() <= SNIFF_DISTANCE and _dog_label_left <= -4.0:
			_show_dog_text("嗅嗅")
	_dog_label.global_position = _dog.global_position + Vector3(0, 1.0, 0)


func _process(delta: float) -> void:
	_time += delta
	_update_dog_reactions(delta)
	if state == State.COMBAT and _dog != null:
		_dog.position.y = absf(sin(_time * 12.0)) * 0.08
	if state == State.IDLE:
		human_puppet.set_ambient(false)
	if state != State.RETURNING:
		_place_dog()
		return
	human_puppet.set_ambient(true)
	var to_home := -human_puppet.position
	to_home.y = 0.0
	if to_home.length() <= RETURN_SPEED * delta:
		human_puppet.position = Vector3.ZERO
		human_puppet.rotation.y = 0.0
		state = State.IDLE
	else:
		human_puppet.position += to_home.normalized() * RETURN_SPEED * delta
		human_puppet.face_towards(global_position)
	_place_dog()


func _place_dog() -> void:
	if _dog == null:
		return
	_dog.position = human_puppet.position + Vector3(0.8, 0, 0.3) + _dog_lunge
