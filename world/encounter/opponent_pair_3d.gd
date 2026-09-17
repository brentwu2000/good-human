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

var encounter: EncounterData

var state: State = State.IDLE
var coordinator: CombatCoordinator3D
var human_puppet: FighterPuppet3D

var _dog: Node3D
var _name_label: Label3D
var _time: float = 0.0


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	prompt = "😤 挑釁"
	human_puppet = FighterPuppet3D.new()
	add_child(human_puppet)
	_name_label = Greybox.label("", 2.0, 30)
	add_child(_name_label)
	add_interaction_area(1.2)
	setup(fixed_encounter)


func setup(data: EncounterData) -> void:
	encounter = data
	state = State.IDLE
	visible = is_present()
	if encounter == null:
		return
	_name_label.modulate = Color.WHITE
	human_puppet.apply(encounter.human)
	human_puppet.position = Vector3.ZERO
	human_puppet.show_hp(false)
	if _dog != null:
		_dog.queue_free()
	_dog = Greybox.dog(encounter.dog_color, encounter.dog_scale)
	add_child(_dog)
	_name_label.text = "%s和%s" % [encounter.human.display_name, encounter.dog_name]
	_place_dog()


## In the world this walk (has a pair and any required discovery).
func is_present() -> bool:
	return encounter != null and Game.goal_progress.has_flag(required_flag)


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
	human_puppet.show_hp(true)


func end_combat(result: CombatSimulation.Result) -> void:
	human_puppet.show_hp(false)
	if result == CombatSimulation.Result.VICTORY:
		state = State.BEATEN
		human_puppet.set_beaten(true)
		_name_label.modulate = Color(0.6, 0.6, 0.6)
	else:
		state = State.RETURNING


func is_beaten() -> bool:
	return state == State.BEATEN


func _process(delta: float) -> void:
	_time += delta
	if state == State.COMBAT and _dog != null:
		_dog.position.y = absf(sin(_time * 12.0)) * 0.08
	if state != State.RETURNING:
		return
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
	_dog.position = human_puppet.position + Vector3(0.8, 0, 0.3)
	_dog.rotation.y = human_puppet.rotation.y
