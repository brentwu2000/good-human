class_name EncounterPoint
extends Node2D
## A spot where a dog + human pair waits. Triggers when the dog walks close;
## EncounterController decides what happens. Holds only local presentation
## state; which pair stands here comes from data (fixed or assigned per run).

signal triggered(point: EncounterPoint)

const GROUP: StringName = &"encounter_points"

@export var spot_id: StringName
## Fixed pair for this spot. Empty = assigned from the ordinary pool each run.
@export var fixed_encounter: EncounterData
@export var trigger_radius: float = 170.0
## The dog must walk this far away before the pair can stop it again.
@export var rearm_distance: float = 260.0
## Direction the pair faces (-1 = left).
@export var facing: float = -1.0

var encounter: EncounterData
var defeated: bool = false
var dog: Node2D

var _armed: bool = true

@onready var _human: FighterPuppet = %Human
@onready var _dog_puppet: DogPuppet = %DogPuppet
@onready var _name_label: Label = %NameLabel


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	if spot_id.is_empty():
		push_error("EncounterPoint %s has no spot_id" % get_path())
	setup(fixed_encounter)


## Called by EncounterController at run start.
func setup(data: EncounterData) -> void:
	encounter = data
	defeated = false
	_armed = true
	if not is_node_ready():
		return
	visible = encounter != null
	if encounter == null:
		return
	_human.apply(encounter.human)
	_human.set_facing(facing)
	_human.set_beaten(false)
	_dog_puppet.apply(encounter.dog_color, encounter.dog_scale, facing)
	_dog_puppet.set_excited(false)
	_name_label.text = "%s和%s" % [encounter.human.display_name, encounter.dog_name]
	_name_label.modulate = Color.WHITE


func is_available() -> bool:
	return encounter != null and not defeated


func set_defeated() -> void:
	defeated = true
	_human.set_beaten(true)
	_name_label.modulate = Color(0.6, 0.6, 0.6)


## Hidden while CombatArena shows the fight in its place.
func set_pair_visible(value: bool) -> void:
	_human.visible = value
	_dog_puppet.visible = value
	_name_label.visible = value


func _process(_delta: float) -> void:
	if dog == null or not is_available():
		return
	var distance := dog.global_position.distance_to(global_position)
	if not _armed:
		_armed = distance > rearm_distance
	elif distance <= trigger_radius:
		_armed = false
		triggered.emit(self)
