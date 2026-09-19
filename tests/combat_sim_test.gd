extends "res://tests/test_case.gd"
## P1-001..P1-008: stats, skill data, Punch/Kick/Block/Dodge and the
## condition + priority AI, all without scenes.

const PLAYER: FighterData = preload("res://data/combat/fighters/player_human.tres")
const JOGGER: FighterData = preload("res://data/combat/fighters/opp01_jogger.tres")
const DELIVERY: FighterData = preload("res://data/combat/fighters/opp02_delivery.tres")
const GYM: FighterData = preload("res://data/combat/fighters/opp03_gym.tres")
const OLD_MASTER: FighterData = preload("res://data/combat/fighters/oppx01_old_master.tres")
const PUNCH: CombatSkillData = preload("res://data/combat/skills/skill_punch.tres")
const KICK: CombatSkillData = preload("res://data/combat/skills/skill_kick.tres")
const BLOCK: CombatSkillData = preload("res://data/combat/skills/skill_block.tres")
const DODGE: CombatSkillData = preload("res://data/combat/skills/skill_dodge.tres")

var balance: GameBalance


func _ready() -> void:
	balance = DataRegistry.balance
	_test_stats()
	_test_skill_data()
	_test_ai_choices()
	_test_block_reduces_damage()
	_test_dodge_avoids_hit()
	_test_kick_staggers_low_will()
	_test_deterministic()
	_test_fights_complete()
	_test_force_result()
	_test_dog_agency_hooks()
	finish()


func _test_stats() -> void:
	var stats := CombatStats.new()
	stats.strength = 4
	stats.endurance = 10
	stats.agility = 50
	stats.will = 3
	check_eq(stats.max_hp(balance), balance.hp_base + 10 * balance.hp_per_endurance, "END drives max HP")
	check_eq(stats.attack(balance), balance.attack_base + 4 * balance.attack_per_strength, "STR drives attack")
	check_eq(stats.action_interval(balance), balance.action_interval_min, "AGI interval clamps at minimum")
	check_eq(stats.stability(balance), 3 * balance.stability_per_will, "WIL drives stability")
	var fast := CombatStats.new()
	fast.agility = 9
	check(fast.action_interval(balance) < CombatStats.new().action_interval(balance), "higher AGI acts sooner")


func _test_skill_data() -> void:
	for skill: CombatSkillData in [PUNCH, KICK, BLOCK, DODGE]:
		check(not String(skill.id).is_empty() and not skill.display_name.is_empty(), "%s has id and name" % skill.resource_path)
		check(not String(skill.animation_key).is_empty(), "%s has animation key" % skill.id)
	check_eq(PLAYER.skills.size(), 4, "player human has four skills")
	check(KICK.power > PUNCH.power and KICK.windup > PUNCH.windup, "kick is stronger and slower than punch")
	check(KICK.cooldown > PUNCH.cooldown, "kick has a cooldown")
	check_eq(BLOCK.effect, CombatSkillData.Effect.BLOCK, "block effect")
	check_eq(DODGE.effect, CombatSkillData.Effect.DODGE, "dodge effect")


func _test_ai_choices() -> void:
	var sim := CombatSimulation.new(PLAYER, JOGGER, 1)
	var me := sim.fighters[CombatSimulation.PLAYER]
	var them := sim.fighters[CombatSimulation.OPPONENT]
	check(sim.choose_skill(me) == null, "out of range: no skill (walk closer)")

	_place(sim, 60.0)
	check(sim.choose_skill(me) == KICK, "in range: kick outranks punch")
	me.cooldowns[KICK.id] = 1.0
	check(sim.choose_skill(me) == PUNCH, "kick on cooldown: punch")
	me.cooldowns[KICK.id] = 0.0
	_place(sim, 90.0)
	check(sim.choose_skill(me) == KICK, "beyond punch reach: only kick is valid")

	_place(sim, 60.0)
	me.ready_at = sim.time + 5.0
	check(sim.choose_skill(me) == null, "attacks wait for action interval")
	# A telegraph that began a moment ago: a reaction exists from the instant
	# after it starts, never in the same one. (Stepping the whole fight here
	# would let this fighter actually block, and then there is no choice left
	# to observe.)
	_start_attack(them, PUNCH, sim.time - 0.05)
	check(sim.choose_skill(me) == BLOCK, "incoming attack: block even while waiting")
	me.cooldowns[BLOCK.id] = 1.0
	check(sim.choose_skill(me) == DODGE, "block on cooldown: dodge")
	me.cooldowns[DODGE.id] = 1.0
	check(sim.choose_skill(me) == null, "no defence available: nothing")


func _test_block_reduces_damage() -> void:
	var sim := _duel(60.0)
	var me := sim.fighters[CombatSimulation.PLAYER]
	var them := sim.fighters[CombatSimulation.OPPONENT]
	_start_attack(them, PUNCH)
	_hold(me, BLOCK)
	var kinds := _collect(sim)
	_step_until(sim, func() -> bool: return not kinds.is_empty())
	check(kinds.has(&"blocked"), "blocked event")
	var max_blocked := them.attack * PUNCH.power * (1.0 + balance.damage_variance) * (1.0 - BLOCK.damage_reduction)
	check(me.max_hp - me.hp <= max_blocked + 0.01, "block reduces damage")


func _test_dodge_avoids_hit() -> void:
	var sim := _duel(60.0)
	var me := sim.fighters[CombatSimulation.PLAYER]
	var them := sim.fighters[CombatSimulation.OPPONENT]
	_start_attack(them, KICK)
	_hold(me, DODGE)
	var start_position := me.position
	var kinds := _collect(sim)
	_step_until(sim, func() -> bool: return not kinds.is_empty())
	check(kinds.has(&"dodged") or kinds.has(&"missed"), "dodge avoids the kick")
	check_eq(me.hp, me.max_hp, "no damage while dodging")
	check(me.position < start_position, "dodge repositions away")


func _test_kick_staggers_low_will() -> void:
	for pair: Array in [[GYM, true], [OLD_MASTER, false]]:
		var opponent := pair[0] as FighterData
		var sim := CombatSimulation.new(_attacks_only(PLAYER), _attacks_only(opponent), 3, balance)
		_place(sim, 60.0)
		var me := sim.fighters[CombatSimulation.PLAYER]
		var them := sim.fighters[CombatSimulation.OPPONENT]
		_start_attack(me, KICK)
		_start_attack(them, PUNCH)
		them.phase_time_left = 10.0
		var kinds := _collect(sim)
		_step_until(sim, func() -> bool: return kinds.has(&"hit"))
		check_eq(kinds.has(&"staggered"), pair[1], "kick stagger vs %s" % opponent.id)


func _test_deterministic() -> void:
	var a := CombatSimulation.new(PLAYER, DELIVERY, 42)
	var b := CombatSimulation.new(PLAYER, DELIVERY, 42)
	a.run_to_end()
	b.run_to_end()
	check_eq(a.result, b.result, "same seed, same result")
	check_eq(a.time, b.time, "same seed, same duration")
	check_eq(a.fighters[0].uses, b.fighters[0].uses, "same seed, same skill usage")


func _test_fights_complete() -> void:
	const RUNS: int = 40
	var used: Dictionary[StringName, int] = {}
	for opponent: FighterData in [JOGGER, DELIVERY, GYM]:
		var wins := 0
		var all_decided := true
		for i in RUNS:
			var sim := CombatSimulation.new(PLAYER, opponent, 1000 + i)
			var result := sim.run_to_end()
			all_decided = all_decided and (result == CombatSimulation.Result.VICTORY or result == CombatSimulation.Result.DEFEAT)
			if result == CombatSimulation.Result.VICTORY:
				wins += 1
			for fighter in sim.fighters:
				for id in fighter.uses:
					used[id] = used.get(id, 0) + fighter.uses[id]
		check(all_decided, "%s fights all end with a winner" % opponent.id)
		check(wins >= RUNS / 2 and wins < RUNS, "%s is beatable but not free (%d/%d)" % [opponent.id, wins, RUNS])
	for skill: CombatSkillData in [PUNCH, KICK, BLOCK, DODGE]:
		check(used.get(skill.id, 0) > 0, "%s used in real fights" % skill.id)

	var master_wins := 0
	for i in RUNS:
		if CombatSimulation.new(PLAYER, OLD_MASTER, 2000 + i).run_to_end() == CombatSimulation.Result.DEFEAT:
			master_wins += 1
	check(master_wins >= RUNS - 1, "old master beats the current player (%d/%d)" % [master_wins, RUNS])


func _test_force_result() -> void:
	var sim := CombatSimulation.new(PLAYER, JOGGER, 9)
	var results: Array[int] = []
	sim.finished.connect(func(r: CombatSimulation.Result) -> void: results.append(r))
	sim.force_result(CombatSimulation.Result.VICTORY)
	check_eq(results, [CombatSimulation.Result.VICTORY] as Array[int], "forced victory emits once")
	sim.step(1.0)
	sim.force_result(CombatSimulation.Result.DEFEAT)
	check_eq(results.size(), 1, "finished fight ignores further results")
	var aborted := CombatSimulation.new(PLAYER, JOGGER, 9)
	aborted.abort()
	check_eq(aborted.result, CombatSimulation.Result.ABORTED, "abort result")


func _test_dog_agency_hooks() -> void:
	# Bark: an opponent still winding up drops the attack and decides nothing.
	var sim := _duel(60.0)
	var them := sim.fighters[CombatSimulation.OPPONENT]
	_start_attack(them, KICK)
	var kinds := _collect(sim)
	sim.distract(CombatSimulation.OPPONENT, 0.8)
	check(kinds.has(&"distracted") and them.phase == CombatFighter.Phase.RECOVERY, "bark cancels a fresh wind-up")
	for i in 30:
		sim.step(1.0 / 60.0)
	check(them.uses.is_empty(), "distracted opponent starts nothing")

	# ...but an attack they have already committed to still comes.
	sim = _duel(60.0)
	them = sim.fighters[CombatSimulation.OPPONENT]
	_start_attack(them, KICK)
	them.phase_time_left = KICK.windup * CombatSimulation.COMMIT_SHARE * 0.5
	sim.distract(CombatSimulation.OPPONENT, 0.8)
	check(them.phase == CombatFighter.Phase.WINDUP, "a bark too late cannot call off a committed attack")

	# A worn-out bark only turns their head.
	sim = _duel(60.0)
	them = sim.fighters[CombatSimulation.OPPONENT]
	_start_attack(them, KICK)
	sim.distract(CombatSimulation.OPPONENT, CombatSimulation.DISTRACT_STRONG - 0.05)
	check(them.phase == CombatFighter.Phase.WINDUP, "a weak bark does not cancel anything")

	# The opening is worth extra damage, but the owner is never handed a turn.
	sim = _duel(60.0)
	var opener := sim.fighters[CombatSimulation.PLAYER]
	var exposed := sim.fighters[CombatSimulation.OPPONENT]
	opener.data = _attacks_only(PLAYER)
	exposed.data = _attacks_only(JOGGER)
	opener.ready_at = sim.time + 5.0
	kinds = _collect(sim)
	sim.distract(CombatSimulation.OPPONENT, 0.9)
	check(opener.ready_at > sim.time, "a bark does not hand the owner a free turn")
	opener.ready_at = sim.time
	_step_until(sim, func() -> bool: return kinds.has(&"opening"))
	check(kinds.has(&"opening"), "a hit inside the opening is worth more")

	# Barking at a useful rhythm swings fights; spamming it does not.
	var plain_wins := _bark_wins(0.0)
	var paced_wins := _bark_wins(6.0)
	var spam_wins := _bark_wins(1.0)
	check(paced_wins >= plain_wins + 4, "paced barking helps the owner win (%d -> %d of 40)" % [plain_wins, paced_wins])
	check(paced_wins < 40, "even good barking does not decide every fight (%d of 40)" % paced_wins)
	# A fight is short enough that one strong bark is all anyone gets, whatever
	# the rhythm — so the property worth protecting is that the extra ones are
	# not worth anything, rather than that pacing beats spamming.
	check(spam_wins <= paced_wins + 2, "extra barks add nothing; the first is the whole benefit (%d vs %d of 40)" % [spam_wins, paced_wins])

	# Pull out of an incoming attack: it misses.
	sim = _duel(60.0)
	var me := sim.fighters[CombatSimulation.PLAYER]
	them = sim.fighters[CombatSimulation.OPPONENT]
	me.data = _attacks_only(PLAYER)
	_start_attack(them, KICK)
	kinds = _collect(sim)
	var before := me.position
	check(sim.pull(CombatSimulation.PLAYER, 20.0), "pull during an incoming kick saves the owner")
	check(me.position < before, "pull moves the owner away from the opponent")
	_step_until(sim, func() -> bool: return kinds.has(&"dodged") or kinds.has(&"hit") or kinds.has(&"missed"))
	check_eq(me.hp, me.max_hp, "pulled owner takes no damage")

	# Pull with nothing incoming costs nothing and gains nothing.
	sim = _duel(60.0)
	me = sim.fighters[CombatSimulation.PLAYER]
	var standing := me.position
	check(not sim.pull(CombatSimulation.PLAYER, 20.0), "pull without an attack is only a reposition")
	check_eq(me.position, standing, "a mistimed pull does not cost the owner ground")

	# A pull that saves them does cost tempo: they have to set their feet again.
	sim = _duel(60.0)
	me = sim.fighters[CombatSimulation.PLAYER]
	them = sim.fighters[CombatSimulation.OPPONENT]
	_start_attack(them, KICK)
	check(sim.pull(CombatSimulation.PLAYER, 20.0), "pull during a wind-up saves the owner")
	check(me.ready_at >= sim.time + CombatSimulation.PULL_RECOVERY, "a save costs the owner their own tempo")

	# Bad pull: stumble, no attacks for a while.
	sim = _duel(60.0)
	me = sim.fighters[CombatSimulation.PLAYER]
	_start_attack(me, PUNCH)
	kinds = _collect(sim)
	sim.stumble(CombatSimulation.PLAYER, 0.6)
	check(kinds.has(&"stumbled") and me.phase == CombatFighter.Phase.RECOVERY and me.ready_at >= sim.time + 0.59, "bad pull knocks the owner off balance")


# --- helpers ---------------------------------------------------------------

## Wins out of 40 seeds with a bark every `interval` seconds (0 = no dog),
## worn down by DogAgency's real resistance and habituation.
func _bark_wins(interval: float) -> int:
	var wins := 0
	for i in 40:
		var sim := CombatSimulation.new(PLAYER, GYM, 3000 + i)
		var next_bark := 1.0
		var recent: Array[float] = []
		var heard := 0
		while not sim.is_finished():
			sim.step(1.0 / 30.0)
			if interval <= 0.0 or sim.time < next_bark:
				continue
			next_bark += interval
			while not recent.is_empty() and sim.time - recent[0] > DogAgency.BARK_RESIST_WINDOW:
				recent.pop_front()
			var effect: float = pow(0.5, recent.size()) * pow(DogAgency.BARK_HABITUATION, heard)
			recent.append(sim.time)
			heard += 1
			if effect >= DogAgency.BARK_MIN_EFFECT:
				sim.distract(CombatSimulation.OPPONENT, DogAgency.BARK_DISTRACT_SECONDS * effect)
		if sim.result == CombatSimulation.Result.VICTORY:
			wins += 1
	return wins

func _duel(gap: float) -> CombatSimulation:
	var sim := CombatSimulation.new(PLAYER, JOGGER, 5, balance)
	_place(sim, gap)
	return sim


func _place(sim: CombatSimulation, gap: float) -> void:
	sim.fighters[0].position = -gap / 2.0
	sim.fighters[1].position = gap / 2.0


## Puts a fighter mid-attack without going through the AI. `at` is the
## simulation time the wind-up began, which is what opponents react to.
func _start_attack(fighter: CombatFighter, skill: CombatSkillData, at: float = 0.0) -> void:
	fighter.action = skill
	fighter.phase = CombatFighter.Phase.WINDUP
	fighter.phase_time_left = skill.windup
	fighter.windup_started_at = at


func _hold(fighter: CombatFighter, skill: CombatSkillData) -> void:
	fighter.action = skill
	fighter.phase = CombatFighter.Phase.ACTIVE
	fighter.phase_time_left = 5.0


## Same fighter without Block/Dodge, so a test controls the defence.
func _attacks_only(data: FighterData) -> FighterData:
	var copy := data.duplicate() as FighterData
	var skills: Array[CombatSkillData] = [PUNCH, KICK]
	copy.skills = skills
	return copy


func _collect(sim: CombatSimulation) -> Array[StringName]:
	var kinds: Array[StringName] = []
	sim.combat_event.connect(func(kind: StringName, _f: int, _s: CombatSkillData, _a: float) -> void:
		if kind != &"skill_started":
			kinds.append(kind))
	return kinds


func _step_until(sim: CombatSimulation, done: Callable) -> void:
	for i in 300:
		if done.call():
			return
		sim.step(1.0 / 60.0)
	check(false, "condition not reached in time")
