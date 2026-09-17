class_name CombatArena
extends Node2D
## Shows one CombatSimulation in the world: both humans fight in the middle,
## both dogs watch from their sides. Steps the simulation and plays events;
## the player has no input here (humans fight autonomously).

signal finished(result: CombatSimulation.Result)

const STEP: float = 1.0 / 60.0
## Pause on the knockout before reporting the result.
const OUTRO_SECONDS: float = 1.4
const DOG_OFFSET: float = 60.0

## Tests speed fights up; 1.0 in the game.
@export var time_scale: float = 1.0

var simulation: CombatSimulation

var _accumulator: float = 0.0
var _outro_left: float = -1.0

@onready var _player: FighterPuppet = %PlayerHuman
@onready var _opponent: FighterPuppet = %OpponentHuman
@onready var _opponent_dog: DogPuppet = %OpponentDog


func start(sim: CombatSimulation, encounter: EncounterData) -> void:
	simulation = sim
	_player.apply(sim.fighters[CombatSimulation.PLAYER].data)
	_player.set_facing(1.0)
	_opponent.apply(encounter.human)
	_opponent.set_facing(-1.0)
	_opponent_dog.apply(encounter.dog_color, encounter.dog_scale, -1.0)
	_opponent_dog.set_excited(true)
	for puppet in [_player, _opponent]:
		puppet.show_hp(true)
		puppet.set_hp_ratio(1.0)
	sim.combat_event.connect(_on_combat_event)
	sim.finished.connect(_on_finished)
	_sync()


## Where the player's dog should stand to watch.
func player_dog_global_position() -> Vector2:
	return to_global(Vector2(-CombatSimulation.START_DISTANCE / 2.0 - DOG_OFFSET, 10.0))


func _process(delta: float) -> void:
	if simulation == null:
		return
	if _outro_left >= 0.0:
		_outro_left -= delta * time_scale
		if _outro_left < 0.0:
			var result := simulation.result
			simulation = null
			finished.emit(result)
		return
	_accumulator += delta * time_scale
	while _accumulator >= STEP and not simulation.is_finished():
		_accumulator -= STEP
		simulation.step(STEP)
	_sync()


func _sync() -> void:
	var puppets: Array[FighterPuppet] = [_player, _opponent]
	for side in 2:
		var fighter := simulation.fighters[side]
		puppets[side].position.x = fighter.position
		puppets[side].set_hp_ratio(fighter.hp_ratio())
		puppets[side].set_guard(fighter.is_guarding())
	_opponent_dog.position.x = simulation.fighters[CombatSimulation.OPPONENT].position + DOG_OFFSET


func _on_combat_event(kind: StringName, side: int, skill: CombatSkillData, _amount: float) -> void:
	var actor := _player if side == CombatSimulation.PLAYER else _opponent
	var other := _opponent if side == CombatSimulation.PLAYER else _player
	match kind:
		&"skill_started":
			actor.play_windup(skill)
		&"hit":
			actor.play_strike(skill)
			other.play_hurt(false)
		&"blocked":
			actor.play_strike(skill)
			other.play_hurt(true)
		&"dodged":
			actor.play_strike(skill)
			other.play_evade()
		&"missed":
			actor.play_strike(skill)
			actor.play_miss()
		&"staggered":
			actor.play_stagger()
		&"defeated":
			actor.play_down()
			other.play_victory()


func _on_finished(_result: CombatSimulation.Result) -> void:
	_sync()
	_opponent_dog.set_excited(false)
	_outro_left = OUTRO_SECONDS
