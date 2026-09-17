class_name CombatCoordinator3D
extends Node
## Live fights in the 3D Run World (ADR-007 seamless real-time combat).
## Same rules and API as CombatCoordinator: nothing pauses, the dog stays
## free, the humans fight where they stand along the line between them, and
## the dog running far enough away disengages. Reuses CombatSimulation.

signal engagement_started(engagement: Engagement3D)
signal engagement_ended(engagement: Engagement3D, result: CombatSimulation.Result)

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
## Ordinary pairs shuffled over spots without a fixed encounter each walk.
@export var ordinary_pool: Array[EncounterData] = []
## Tests speed fights up; 1.0 in the game.
@export var time_scale: float = 1.0

var last_result: CombatSimulation.Result = CombatSimulation.Result.NONE
## Active fight or null.
var engagement: Engagement3D

var _pairs: Array[OpponentPair3D] = []
var _origin: Vector3
var _axis: Vector3
var _accumulator: float = 0.0
var _defeat_left: float = -1.0
var _defeated_by: String = ""
var _base_fighter: FighterData


func _ready() -> void:
	_base_fighter = human.fighter
	run_manager.run_started.connect(_on_run_started)


func get_pairs() -> Array[OpponentPair3D]:
	return _pairs


func is_fighting() -> bool:
	return engagement != null


func is_human_engaged() -> bool:
	return not human.is_following()


## The pair currently fighting (camera framing), or null.
var pair: OpponentPair3D:
	get:
		return engagement.pair if engagement != null else null


func can_provoke(_pair: OpponentPair3D) -> bool:
	return run_manager.is_running() and human.is_following() and _defeat_left < 0.0 and engagement == null


func _on_run_started(_seed: int) -> void:
	engagement = null
	_defeat_left = -1.0
	last_result = CombatSimulation.Result.NONE
	human.set_state(HumanFollower3D.State.FOLLOW)
	if _base_fighter != null:
		human.fighter = GrowthResolver.apply_to_fighter(_base_fighter, Game.human_growth, DataRegistry.training)
	_pairs.clear()
	for node in get_tree().get_nodes_in_group(OpponentPair3D.GROUP):
		var p := node as OpponentPair3D
		if owner == null or owner.is_ancestor_of(p):
			_pairs.append(p)
	_pairs.sort_custom(func(a: OpponentPair3D, b: OpponentPair3D) -> bool: return String(a.spot_id) < String(b.spot_id))
	# After loot rolls (run_started), so encounters don't change loot seeds.
	var pool := ordinary_pool.duplicate()
	for i in range(pool.size() - 1, 0, -1):
		var j := run_manager.run_rng.randi_range(0, i)
		var swap: EncounterData = pool[i]
		pool[i] = pool[j]
		pool[j] = swap
	for p in _pairs:
		var data := p.fixed_encounter
		if data == null and not pool.is_empty():
			data = pool.pop_back()
		p.coordinator = self
		p.setup(data)
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
	var sim := CombatSimulation.new(human.fighter, opponent.encounter.human, run_manager.run_rng.randi(), null, gap.length() * UNITS_PER_METER)
	engagement = Engagement3D.new(sim, opponent)
	_accumulator = 0.0
	last_result = CombatSimulation.Result.NONE
	human.set_state(HumanFollower3D.State.COMBAT)
	human.puppet.show_hp(true)
	human.puppet.set_hp_ratio(1.0)
	opponent.begin_combat()
	opponent.human_puppet.shout("你家的狗在叫什麼？！", Color(1.0, 0.8, 0.5))
	human.say("欸欸欸，不是我…", Color(1.0, 0.9, 0.6))
	sim.combat_event.connect(_on_combat_event)
	sim.finished.connect(_on_finished)
	_sync()
	engagement_started.emit(engagement)


func _process(delta: float) -> void:
	if _defeat_left >= 0.0:
		_defeat_left -= delta * time_scale
		if _defeat_left < 0.0:
			run_manager.defeat_run(_defeated_by)
	if engagement == null:
		return
	var sim := engagement.simulation
	if dog.global_position.distance_to(human.global_position) > DISENGAGE_DISTANCE:
		sim.disengage()
		return
	_accumulator += delta * time_scale
	while _accumulator >= STEP and engagement != null and not sim.is_finished():
		_accumulator -= STEP
		sim.step(STEP)
	if engagement != null:
		_sync()


func _world_position(side: int) -> Vector3:
	var p := _origin + _axis * (engagement.simulation.fighters[side].position / UNITS_PER_METER)
	var y := human.global_position.y if side == CombatSimulation.PLAYER else engagement.pair.human_global_position().y
	return Vector3(p.x, y, p.z)


func _sync() -> void:
	var sim := engagement.simulation
	var opponent := engagement.pair
	var player_fighter := sim.fighters[CombatSimulation.PLAYER]
	var opponent_fighter := sim.fighters[CombatSimulation.OPPONENT]
	human.global_position = _world_position(CombatSimulation.PLAYER)
	opponent.set_human_global_position(_world_position(CombatSimulation.OPPONENT))
	human.puppet.face_towards(opponent.human_global_position())
	opponent.human_puppet.face_towards(human.global_position)
	human.puppet.set_hp_ratio(player_fighter.hp_ratio())
	opponent.human_puppet.set_hp_ratio(opponent_fighter.hp_ratio())
	human.puppet.set_guard(player_fighter.is_guarding())
	opponent.human_puppet.set_guard(opponent_fighter.is_guarding())


func _on_combat_event(kind: StringName, side: int, skill: CombatSkillData, _amount: float) -> void:
	var own := human.puppet
	var theirs := engagement.pair.human_puppet
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
	var ended := engagement
	var opponent := ended.pair
	var encounter := opponent.encounter
	engagement = null
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
	engagement_ended.emit(ended, result)


# --- Debug (Debug Panel / tests only) --------------------------------------------

func debug_force_result(result: CombatSimulation.Result) -> void:
	if engagement != null:
		engagement.simulation.force_result(result)


## Puts the dog (and owner) next to the nearest pair that can be provoked.
func debug_goto_next_pair() -> void:
	if is_human_engaged():
		return
	var best: OpponentPair3D = null
	for p in _pairs:
		if p.is_idle() and p.is_present():
			if best == null or dog.global_position.distance_to(p.global_position) < dog.global_position.distance_to(best.global_position):
				best = p
	if best != null:
		dog.global_position = best.global_position + Vector3(0.7, 0.2, 0.9)
		dog.velocity = Vector3.ZERO
		human.global_position = best.global_position + Vector3(1.6, 0.2, 2.0)
