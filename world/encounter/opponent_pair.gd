class_name OpponentPair
extends Interactable
## A dog + human pair standing in the Run World. The dog provokes it by
## interacting; the fight then happens right here while the dog stays free.
## States: IDLE (can be provoked) → COMBAT → BEATEN, or RETURNING → IDLE.

signal provoked(pair: OpponentPair)

enum State { IDLE, COMBAT, RETURNING, BEATEN }

const GROUP: StringName = &"opponent_pairs"
const RETURN_SPEED: float = 160.0
const DOG_OFFSET: float = 50.0

@export var spot_id: StringName
## Fixed pair for this spot. Empty = assigned from the ordinary pool each run.
@export var fixed_encounter: EncounterData
## Direction the pair faces while idle (-1 = left).
@export var facing: float = -1.0

var encounter: EncounterData
var state: State = State.IDLE
## Set by CombatCoordinator; decides whether a provoke is allowed right now.
var coordinator: CombatCoordinator

@onready var human_puppet: FighterPuppet = %Human
@onready var _dog_puppet: DogPuppet = %DogPuppet
@onready var _name_label: Label = %NameLabel


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	prompt = "😤 挑釁"
	if spot_id.is_empty():
		push_error("OpponentPair %s has no spot_id" % get_path())
	setup(fixed_encounter)


## Called by CombatCoordinator at run start.
func setup(data: EncounterData) -> void:
	encounter = data
	state = State.IDLE
	if not is_node_ready():
		return
	visible = encounter != null
	if encounter == null:
		return
	human_puppet.apply(encounter.human)
	human_puppet.revive()
	human_puppet.show_hp(false)
	human_puppet.position = Vector2.ZERO
	human_puppet.set_facing(facing)
	_dog_puppet.apply(encounter.dog_color, encounter.dog_scale, facing)
	_dog_puppet.set_excited(false)
	_name_label.text = "%s和%s" % [encounter.human.display_name, encounter.dog_name]
	_name_label.modulate = Color.WHITE
	_place_dog()


func can_interact(context: Object) -> bool:
	var run := context as RunManager
	if not enabled or encounter == null or state != State.IDLE or run == null or not run.is_running():
		return false
	return coordinator == null or coordinator.can_provoke(self)


func interact(context: Object) -> void:
	if can_interact(context):
		provoked.emit(self)


func human_global_position() -> Vector2:
	return human_puppet.global_position


func set_human_global_position(value: Vector2) -> void:
	human_puppet.global_position = value
	_place_dog()


func begin_combat() -> void:
	state = State.COMBAT
	_dog_puppet.set_excited(true)
	human_puppet.show_hp(true)


## `result` is from the player's side.
func end_combat(result: CombatSimulation.Result) -> void:
	_dog_puppet.set_excited(false)
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
	if state != State.RETURNING:
		return
	var to_home := -human_puppet.position
	if to_home.length() <= RETURN_SPEED * delta:
		human_puppet.position = Vector2.ZERO
		human_puppet.set_facing(facing)
		state = State.IDLE
	else:
		human_puppet.position += to_home.normalized() * RETURN_SPEED * delta
		human_puppet.set_facing(to_home.x)
	_place_dog()


func _place_dog() -> void:
	_dog_puppet.position = human_puppet.position + Vector2(-DOG_OFFSET * human_puppet.facing, -2.0)
