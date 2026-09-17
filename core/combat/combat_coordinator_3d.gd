class_name CombatCoordinator3D
extends Node
## Live fights in the 3D Run World (ADR-007 seamless real-time combat).
## Same rules as CombatCoordinator: nothing pauses, the dog stays free, the
## humans fight where they stand along the line between them, and the dog
## running far enough away disengages. Reuses CombatSimulation unchanged.

signal engagement_started(pair: OpponentPair3D)
signal engagement_ended(pair: OpponentPair3D, result: CombatSimulation.Result)

const STEP: float = 1.0 / 60.0
const DEFEAT_SECONDS: float = 1.6
## CombatSimulation works in arena units; 1 m = 100 units keeps its reach and
## speed tuning meaningful at human scale.
const UNITS_PER_METER: float = 100.0
## Dog further than this (m) from its owner breaks the fight off.
const DISENGAGE_DISTANCE: float = 9.0

@export var run_manager: RunManager
@export var human: HumanFollower3D
@export var dog: DogController3D
## Tests speed fights up; 1.0 in the game.
@export var time_scale: float = 1.0

var last_result: CombatSimulation.Result = CombatSimulation.Result.NONE
## Active fight or null (the structure allows more later).
var simulation: CombatSimulation
var pair: OpponentPair3D

var _origin: Vector3
var _axis: Vector3
var _accumulator: float = 0.0
var _defeat_left: float = -1.0
var _defeated_by: String = ""
var _base_fighter: FighterData


func _ready() -> void:
	_base_fighter = human.fighter
	run_manager.run_started.connect(_on_run_started)


func is_fighting() -> bool:
	return simulation != null


func can_provoke(_pair: OpponentPair3D) -> bool:
	return run_manager.is_running() and human.is_following() and _defeat_left < 0.0 and simulation == null


func _on_run_started(_seed: int) -> void:
	simulation = null
	pair = null
	_defeat_left = -1.0
	last_result = CombatSimulation.Result.NONE
	human.set_state(HumanFollower3D.State.FOLLOW)
	if _base_fighter != null:
		human.fighter = GrowthResolver.apply_to_fighter(_base_fighter, Game.human_growth, DataRegistry.training)
	for node in get_tree().get_nodes_in_group(OpponentPair3D.GROUP):
		var p := node as OpponentPair3D
		if owner != null and not owner.is_ancestor_of(p):
			continue
		p.coordinator = self
		p.setup(p.encounter)
		if not p.provoked.is_connected(start_engagement):
			p.provoked.connect(start_engagement)


func start_engagement(opponent: OpponentPair3D) -> void:
	if not can_provoke(opponent) or opponent.state != OpponentPair3D.State.IDLE:
		return
	var a := human.global_position
	var b := opponent.human_global_position()
	var gap := Vector3(b.x - a.x, 0, b.z - a.z)
	_origin = (a + b) / 2.0
	_axis = gap.normalized() if gap.length() > 0.01 else Vector3.FORWARD
	simulation = CombatSimulation.new(human.fighter, opponent.encounter.human, run_manager.run_rng.randi(), null, gap.length() * UNITS_PER_METER)
	pair = opponent
	_accumulator = 0.0
	last_result = CombatSimulation.Result.NONE
	human.set_state(HumanFollower3D.State.COMBAT)
	human.puppet.show_hp(true)
	human.puppet.set_hp_ratio(1.0)
	opponent.begin_combat()
	opponent.human_puppet.shout("你家的狗在叫什麼？！", Color(1.0, 0.8, 0.5))
	human.say("欸欸欸，不是我…", Color(1.0, 0.9, 0.6))
	simulation.combat_event.connect(_on_combat_event)
	simulation.finished.connect(_on_finished)
	_sync()
	engagement_started.emit(opponent)


func _process(delta: float) -> void:
	if _defeat_left >= 0.0:
		_defeat_left -= delta * time_scale
		if _defeat_left < 0.0:
			run_manager.defeat_run(_defeated_by)
	if simulation == null:
		return
	if dog.global_position.distance_to(human.global_position) > DISENGAGE_DISTANCE:
		simulation.disengage()
		return
	_accumulator += delta * time_scale
	while _accumulator >= STEP and simulation != null and not simulation.is_finished():
		_accumulator -= STEP
		simulation.step(STEP)
	if simulation != null:
		_sync()


func _world_position(side: int) -> Vector3:
	var p := _origin + _axis * (simulation.fighters[side].position / UNITS_PER_METER)
	return Vector3(p.x, human.global_position.y if side == CombatSimulation.PLAYER else pair.human_global_position().y, p.z)


func _sync() -> void:
	var player := simulation.fighters[CombatSimulation.PLAYER]
	var opponent := simulation.fighters[CombatSimulation.OPPONENT]
	human.global_position = _world_position(CombatSimulation.PLAYER)
	pair.set_human_global_position(_world_position(CombatSimulation.OPPONENT))
	human.puppet.face_towards(pair.human_global_position())
	pair.human_puppet.face_towards(human.global_position)
	human.puppet.set_hp_ratio(player.hp_ratio())
	pair.human_puppet.set_hp_ratio(opponent.hp_ratio())
	human.puppet.set_guard(player.is_guarding())
	pair.human_puppet.set_guard(opponent.is_guarding())


func _on_combat_event(kind: StringName, side: int, skill: CombatSkillData, _amount: float) -> void:
	var own := human.puppet
	var theirs := pair.human_puppet
	var actor := own if side == CombatSimulation.PLAYER else theirs
	var other := theirs if side == CombatSimulation.PLAYER else own
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


func _on_finished(result: CombatSimulation.Result) -> void:
	var opponent := pair
	var encounter := opponent.encounter
	simulation = null
	pair = null
	last_result = result
	opponent.end_combat(result)
	match result:
		CombatSimulation.Result.VICTORY:
			human.set_state(HumanFollower3D.State.FOLLOW)
			var reward := run_manager.grant_reward(encounter.reward_table)
			human.say("贏了！" + ("撿到%s" % reward.item.display_name if reward != null else ""), Color(0.6, 1.0, 0.6), 2.0)
		CombatSimulation.Result.DEFEAT:
			human.set_state(HumanFollower3D.State.DOWN)
			human.puppet.show_hp(false)
			opponent.human_puppet.shout("哼。")
			_defeated_by = encounter.human.display_name
			_defeat_left = DEFEAT_SECONDS
		CombatSimulation.Result.DISENGAGED:
			human.set_state(HumanFollower3D.State.FOLLOW)
			human.say("等等我啊！", Color(0.85, 0.85, 0.85))
		_:
			human.set_state(HumanFollower3D.State.FOLLOW)
	engagement_ended.emit(opponent, result)


# --- Debug -----------------------------------------------------------------------

func debug_force_result(result: CombatSimulation.Result) -> void:
	if simulation != null:
		simulation.force_result(result)
