class_name CombatCoordinator
extends Node
## Scene-scoped coordinator of live fights in the Run World (ADR: seamless
## real-time combat). Not a battle mode: nothing is paused, the dog stays free
## and the camera stays with the dog. Tracks a list of engagements so more
## than one conflict can exist later; Sprint 02 only starts fights for the
## player's human.

signal engagement_started(engagement: Engagement)
signal engagement_ended(engagement: Engagement, result: CombatSimulation.Result)

const STEP: float = 1.0 / 60.0
## Time the knocked-out owner lies there before the walk ends.
const DEFEAT_SECONDS: float = 1.6

@export var run_manager: RunManager
@export var human: HumanFollower
## Ordinary pairs shuffled over spots without a fixed encounter each run.
@export var ordinary_pool: Array[EncounterData] = []
## Tests speed fights up; 1.0 in the game.
@export var time_scale: float = 1.0

var engagements: Array[Engagement] = []
var last_result: CombatSimulation.Result = CombatSimulation.Result.NONE

var _pairs: Array[OpponentPair] = []
var _defeat_left: float = -1.0
var _defeated_by: String = ""


func _ready() -> void:
	run_manager.run_started.connect(_on_run_started)


func get_pairs() -> Array[OpponentPair]:
	return _pairs


func is_human_engaged() -> bool:
	return human.state != HumanFollower.State.FOLLOW


func can_provoke(_pair: OpponentPair) -> bool:
	return run_manager.is_running() and human.is_following() and _defeat_left < 0.0


# --- Run setup ----------------------------------------------------------------

func _on_run_started(_seed: int) -> void:
	engagements.clear()
	_defeat_left = -1.0
	last_result = CombatSimulation.Result.NONE
	human.set_state(HumanFollower.State.FOLLOW)
	_pairs.clear()
	for node in get_tree().get_nodes_in_group(OpponentPair.GROUP):
		var pair := node as OpponentPair
		if pair != null and (owner == null or owner.is_ancestor_of(pair)):
			_pairs.append(pair)
	_pairs.sort_custom(func(a: OpponentPair, b: OpponentPair) -> bool: return String(a.spot_id) < String(b.spot_id))

	# Runs after loot rolls, so adding encounters does not change loot seeds.
	var pool := ordinary_pool.duplicate()
	for i in range(pool.size() - 1, 0, -1):
		var j := run_manager.run_rng.randi_range(0, i)
		var swap: EncounterData = pool[i]
		pool[i] = pool[j]
		pool[j] = swap
	for pair in _pairs:
		var data := pair.fixed_encounter
		if data == null and not pool.is_empty():
			data = pool.pop_back()
		pair.coordinator = self
		pair.setup(data)
		if not pair.provoked.is_connected(start_engagement):
			pair.provoked.connect(start_engagement)


# --- Engagements ----------------------------------------------------------------

func start_engagement(pair: OpponentPair) -> void:
	if not can_provoke(pair) or pair.state != OpponentPair.State.IDLE:
		return
	var player_position := human.global_position
	var opponent_position := pair.human_global_position()
	var sim := CombatSimulation.new(human.fighter, pair.encounter.human, run_manager.run_rng.randi(), null, player_position.distance_to(opponent_position))
	var engagement := Engagement.new(sim, pair, player_position, opponent_position)
	engagements.append(engagement)
	last_result = CombatSimulation.Result.NONE

	human.set_state(HumanFollower.State.COMBAT)
	human.puppet.show_hp(true)
	human.puppet.set_hp_ratio(1.0)
	pair.begin_combat()
	pair.human_puppet.shout("你家的狗在叫什麼？！", Color(1.0, 0.8, 0.5))
	human.say("欸欸欸，不是我…", Color(1.0, 0.9, 0.6))
	sim.combat_event.connect(_on_combat_event.bind(engagement))
	sim.finished.connect(_on_finished.bind(engagement))
	_sync(engagement)
	engagement_started.emit(engagement)


func _process(delta: float) -> void:
	if _defeat_left >= 0.0:
		_defeat_left -= delta * time_scale
		if _defeat_left < 0.0:
			run_manager.defeat_run(_defeated_by)
	var disengage_distance := DataRegistry.balance.disengage_distance
	for engagement: Engagement in engagements.duplicate():
		var sim := engagement.simulation
		# Spatial disengagement: the dog ran off, so the owner goes after it.
		if run_manager.dog != null and run_manager.dog.global_position.distance_to(human.global_position) > disengage_distance:
			sim.disengage()
			continue
		engagement.accumulator += delta * time_scale
		while engagement.accumulator >= STEP and not sim.is_finished():
			engagement.accumulator -= STEP
			sim.step(STEP)
		if not sim.is_finished():
			_sync(engagement)


func _sync(engagement: Engagement) -> void:
	var sim := engagement.simulation
	var player := sim.fighters[CombatSimulation.PLAYER]
	var opponent := sim.fighters[CombatSimulation.OPPONENT]
	human.global_position = engagement.world_position(CombatSimulation.PLAYER)
	human.puppet.set_facing(engagement.facing(CombatSimulation.PLAYER))
	human.puppet.set_hp_ratio(player.hp_ratio())
	human.puppet.set_guard(player.is_guarding())
	engagement.pair.set_human_global_position(engagement.world_position(CombatSimulation.OPPONENT))
	engagement.pair.human_puppet.set_facing(engagement.facing(CombatSimulation.OPPONENT))
	engagement.pair.human_puppet.set_hp_ratio(opponent.hp_ratio())
	engagement.pair.human_puppet.set_guard(opponent.is_guarding())


func _on_combat_event(kind: StringName, side: int, skill: CombatSkillData, _amount: float, engagement: Engagement) -> void:
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


func _on_finished(result: CombatSimulation.Result, engagement: Engagement) -> void:
	engagements.erase(engagement)
	last_result = result
	var pair := engagement.pair
	var encounter := pair.encounter
	pair.end_combat(result)
	match result:
		CombatSimulation.Result.VICTORY:
			human.set_state(HumanFollower.State.FOLLOW)
			var reward := run_manager.grant_reward(encounter.reward_table)
			human.say("贏了！%s" % ("撿到%s" % reward.item.display_name if reward != null else "好狗狗！"), Color(0.6, 1.0, 0.6), 2.0)
		CombatSimulation.Result.DEFEAT:
			human.set_state(HumanFollower.State.DOWN)
			human.puppet.show_hp(false)
			pair.human_puppet.shout("哼。", Color(0.9, 0.9, 0.9))
			_defeated_by = encounter.human.display_name
			_defeat_left = DEFEAT_SECONDS
		CombatSimulation.Result.DISENGAGED:
			human.set_state(HumanFollower.State.FOLLOW)
			human.say("等等我啊！", Color(0.85, 0.85, 0.85))
		_:
			human.set_state(HumanFollower.State.FOLLOW)
			human.say("打不動了…走吧", Color(0.85, 0.85, 0.85))
	engagement_ended.emit(engagement, result)


# --- Debug (Debug Panel / tests only) -----------------------------------------

func debug_force_result(result: CombatSimulation.Result) -> void:
	if not engagements.is_empty():
		engagements[0].simulation.force_result(result)


## Puts the dog (and owner) next to the nearest pair that can be provoked.
func debug_goto_next_pair() -> void:
	var dog := run_manager.dog
	if dog == null or is_human_engaged():
		return
	var best: OpponentPair = null
	for pair in _pairs:
		if pair.state == OpponentPair.State.IDLE and pair.encounter != null:
			if best == null or dog.global_position.distance_to(pair.global_position) < dog.global_position.distance_to(best.global_position):
				best = pair
	if best != null:
		dog.global_position = best.global_position + Vector2(-100.0, 70.0)
		dog.velocity = Vector2.ZERO
		human.global_position = best.global_position + Vector2(-150.0, 0.0)
