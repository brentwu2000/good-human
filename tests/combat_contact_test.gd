extends "res://tests/test_case.gd"
## P04-03, without scenes: an attack runs WINDUP → STRIKE → CONTACT →
## FOLLOW_THROUGH → RECOVERY; it can only land inside its contact window, only
## on a body within reach, and only once; a swing that touches nobody is a
## whiff that leaves the attacker open for longer.

const PLAYER: FighterData = preload("res://data/combat/fighters/player_human.tres")
const JOGGER: FighterData = preload("res://data/combat/fighters/opp01_jogger.tres")
const JAB: CombatSkillData = preload("res://data/combat/skills/skill_jab.tres")
const KICK: CombatSkillData = preload("res://data/combat/skills/skill_kick.tres")
const BLOCK: CombatSkillData = preload("res://data/combat/skills/skill_block.tres")
const HOOK: CombatSkillData = preload("res://data/combat/skills/skill_heavy_hook.tres")
const DODGE: CombatSkillData = preload("res://data/combat/skills/skill_dodge.tres")
const STEP: float = 1.0 / 60.0


func _ready() -> void:
	_test_jab_data()
	_test_phases_and_contact_timing()
	_test_lands_only_once()
	_test_whiff()
	_test_contact_waits_for_reach()
	_test_block_in_window()
	_test_pull_covers_contact()
	_test_real_fights_order()
	_test_motion_states()
	_test_hook()
	_test_kick()
	_test_dodge_is_spatial()
	_test_hit_stop_ranges()
	_test_opening_gets_the_heavy_blow()
	finish()


func _test_jab_data() -> void:
	check_eq(JAB.id, &"skill_jab", "the quick attack is the Jab")
	check(JAB.windup < KICK.windup and JAB.recovery < KICK.recovery, "a jab is quicker in and out than a kick")
	check(JAB.strike_time > 0.0 and JAB.contact_time > 0.0 and JAB.follow_through > 0.0, "a jab has all five phases")
	check(JAB.whiff_recovery > 0.0, "a missed jab costs something")
	var total := JAB.windup + JAB.strike_time + JAB.contact_time + JAB.follow_through + JAB.recovery
	check(total < 1.0, "a jab is compact (%.2f s from start to ready)" % total)


func _test_phases_and_contact_timing() -> void:
	var sim := _duel(60.0)
	var me := sim.fighters[CombatSimulation.PLAYER]
	var them := sim.fighters[CombatSimulation.OPPONENT]
	var log := _log(sim)
	_start_attack(me, JAB)
	var phases: Array[int] = [me.phase]
	var hp_at_release := -1.0
	var landed_at := -1.0
	for i in 120:
		sim.step(STEP)
		if phases.back() != me.phase:
			phases.append(me.phase)
		if hp_at_release < 0.0 and me.phase == CombatFighter.Phase.STRIKE:
			hp_at_release = them.hp
		if landed_at < 0.0 and log.any(func(e: Array) -> bool: return e[0] == &"hit"):
			landed_at = sim.time
		if me.is_idle():
			break
	var P := CombatFighter.Phase
	check_eq(phases, [P.WINDUP, P.STRIKE, P.CONTACT, P.FOLLOW_THROUGH, P.RECOVERY, P.IDLE], "a jab runs all five phases in order")
	check_eq(hp_at_release, them.max_hp, "nothing lands during the wind-up")
	var opens := JAB.windup + JAB.strike_time
	check(landed_at >= opens - STEP * 0.5 and landed_at <= opens + JAB.contact_time + STEP, "it lands inside the contact window (%.3f s, window %.3f–%.3f)" % [landed_at, opens, opens + JAB.contact_time])
	var strike_index := log.find_custom(func(e: Array) -> bool: return e[0] == &"strike")
	var hit_index := log.find_custom(func(e: Array) -> bool: return e[0] == &"hit")
	check(strike_index >= 0 and hit_index > strike_index, "the strike is released before it lands")


func _test_lands_only_once() -> void:
	var long_window := JAB.duplicate() as CombatSkillData
	long_window.contact_time = 0.5
	var sim := _duel(60.0)
	var log := _log(sim)
	_start_attack(sim.fighters[CombatSimulation.PLAYER], long_window)
	_run_until_idle(sim, CombatSimulation.PLAYER)
	check_eq(log.filter(func(e: Array) -> bool: return e[0] == &"hit").size(), 1, "an attack lands once however long its window")


func _test_whiff() -> void:
	var sim := _duel(JAB.preferred_range + 60.0)
	var me := sim.fighters[CombatSimulation.PLAYER]
	var them := sim.fighters[CombatSimulation.OPPONENT]
	them.ready_at = 99.0
	var log := _log(sim)
	_start_attack(me, JAB)
	var recovery_seen := 0.0
	for i in 120:
		sim.step(STEP)
		if me.phase == CombatFighter.Phase.RECOVERY:
			recovery_seen += STEP
		if me.is_idle():
			break
	check(log.any(func(e: Array) -> bool: return e[0] == &"missed"), "out of reach: a whiff")
	check_eq(them.hp, them.max_hp, "and no damage")
	check(recovery_seen >= JAB.recovery + JAB.whiff_recovery - STEP * 1.5, "a whiff leaves them open longer (%.2f s)" % recovery_seen)


## A target who steps into reach while the window is still open is hit; the
## check is made through the window, not once.
func _test_contact_waits_for_reach() -> void:
	var slow := JAB.duplicate() as CombatSkillData
	slow.contact_time = 0.3
	var sim := _duel(JAB.preferred_range + 20.0)
	var me := sim.fighters[CombatSimulation.PLAYER]
	var them := sim.fighters[CombatSimulation.OPPONENT]
	them.ready_at = 99.0
	var log := _log(sim)
	_start_attack(me, slow)
	for i in 120:
		sim.step(STEP)
		if me.phase == CombatFighter.Phase.CONTACT:
			them.position = me.position + 60.0
		if me.is_idle():
			break
	check(log.any(func(e: Array) -> bool: return e[0] == &"hit"), "stepping into an open window gets you hit")
	check(not log.any(func(e: Array) -> bool: return e[0] == &"missed"), "and it is not also a miss")


func _test_block_in_window() -> void:
	var sim := _duel(60.0)
	var me := sim.fighters[CombatSimulation.PLAYER]
	var them := sim.fighters[CombatSimulation.OPPONENT]
	var log := _log(sim)
	_start_attack(me, JAB)
	them.action = BLOCK
	them.phase = CombatFighter.Phase.ACTIVE
	them.phase_time_left = 5.0
	_run_until_idle(sim, CombatSimulation.PLAYER)
	check(log.any(func(e: Array) -> bool: return e[0] == &"blocked"), "a guard up during the window blocks it")


## The leash saves the owner from the whole attack, not just its wind-up.
func _test_pull_covers_contact() -> void:
	var sim := _duel(60.0)
	var me := sim.fighters[CombatSimulation.PLAYER]
	var them := sim.fighters[CombatSimulation.OPPONENT]
	_start_attack(them, JAB)
	sim.step(STEP)
	check(sim.pull(CombatSimulation.PLAYER, 20.0), "pulled during the wind-up")
	var contact_end := sim.time + them.phase_time_left + JAB.strike_time + JAB.contact_time
	check(me.pulled_until >= contact_end, "and protected until the window closes (%.2f ≥ %.2f)" % [me.pulled_until, contact_end])


## In real fights every outcome of an attack comes after its release.
func _test_real_fights_order() -> void:
	# [outcomes, landed before release] — lambdas capture plain ints by value.
	var counts := [0, 0]
	for i in 20:
		var sim := CombatSimulation.new(PLAYER, JOGGER, 7000 + i)
		var released := [false, false]
		sim.combat_event.connect(func(kind: StringName, side: int, skill: CombatSkillData, _amount: float) -> void:
			if skill == null or skill.effect != CombatSkillData.Effect.ATTACK:
				return
			if kind == &"strike":
				released[side] = true
			elif kind in [&"hit", &"blocked", &"dodged", &"missed"]:
				counts[0] += 1
				if not released[side]:
					counts[1] += 1
				released[side] = false)
		sim.run_to_end(STEP)
	check(counts[0] > 100, "plenty of attacks resolved (%d)" % counts[0])
	check_eq(counts[1], 0, "no attack lands, misses or is blocked before it is released")


func _test_motion_states() -> void:
	var motion := CombatMotion3D.new()
	var fighter := CombatFighter.new(PLAYER, 0, DataRegistry.balance)
	fighter.action = JAB
	for pair: Array in [[CombatFighter.Phase.STRIKE, CombatMotion3D.State.ATTACK], [CombatFighter.Phase.CONTACT, CombatMotion3D.State.ATTACK], [CombatFighter.Phase.FOLLOW_THROUGH, CombatMotion3D.State.FOLLOW_THROUGH]]:
		fighter.phase = pair[0]
		motion.update(0.01, fighter, false, false)
		check_eq(motion.state, pair[1], "phase %s shows as %s" % [CombatFighter.Phase.keys()[pair[0]], CombatMotion3D.State.keys()[pair[1]]])
		check(motion.is_committed(), "and the body is committed to it")


func _duel(gap: float) -> CombatSimulation:
	var sim := CombatSimulation.new(PLAYER, JOGGER, 5)
	sim.fighters[0].position = -gap / 2.0
	sim.fighters[1].position = gap / 2.0
	# Nobody decides anything or moves their feet on their own: the test
	# drives the attack. (A plain field, not a bark: no opening is made.)
	for fighter in sim.fighters:
		fighter.ready_at = 99.0
		fighter.distracted_until = 99.0
		fighter.cooldowns[&"skill_block"] = 99.0
		fighter.cooldowns[&"skill_dodge"] = 99.0
	return sim


func _start_attack(fighter: CombatFighter, skill: CombatSkillData) -> void:
	fighter.action = skill
	fighter.phase = CombatFighter.Phase.WINDUP
	fighter.phase_time_left = skill.windup
	fighter.windup_started_at = 0.0


func _log(sim: CombatSimulation) -> Array[Array]:
	var events: Array[Array] = []
	sim.combat_event.connect(func(kind: StringName, side: int, _skill: CombatSkillData, amount: float) -> void:
		events.append([kind, side, amount]))
	return events


func _run_until_idle(sim: CombatSimulation, side: int) -> void:
	for i in 180:
		sim.step(STEP)
		if sim.fighters[side].is_idle():
			return


## P04-04: the heavy hook sits between the jab and the kick, carries the
## body with it, and only the fighters built for it throw it (owner, option A).
func _test_hook() -> void:
	check(HOOK.windup > JAB.windup and HOOK.windup < KICK.windup, "a hook telegraphs longer than a jab, shorter than a kick")
	check(HOOK.power > JAB.power and HOOK.whiff_recovery > JAB.whiff_recovery, "it hits harder than a jab and costs more to miss")
	check(HOOK.strike_time > 0.0 and HOOK.contact_time > 0.0 and HOOK.follow_through > 0.0, "it has all five phases")
	for path: String in ["player_human", "opp03_gym", "oppx01_old_master"]:
		var data: FighterData = load("res://data/combat/fighters/%s.tres" % path)
		check(data.skills.has(HOOK), "%s throws hooks" % path)
	for path: String in ["opp01_jogger", "opp02_delivery", "opp04_student"]:
		var data: FighterData = load("res://data/combat/fighters/%s.tres" % path)
		check(not data.skills.has(HOOK), "%s does not" % path)

	var sim := _duel(60.0)
	_start_attack(sim.fighters[CombatSimulation.PLAYER], HOOK)
	var log := _log(sim)
	_run_until_idle(sim, CombatSimulation.PLAYER)
	check(log.any(func(e: Array) -> bool: return e[0] == &"hit"), "a hook in reach lands")
	check(sim.distance() >= 60.0 + HOOK.displacement - 0.01, "and moves them back (%.1f from 60)" % sim.distance())

	sim = _duel(60.0)
	var them := sim.fighters[CombatSimulation.OPPONENT]
	_start_attack(sim.fighters[CombatSimulation.PLAYER], HOOK)
	them.action = BLOCK
	them.phase = CombatFighter.Phase.ACTIVE
	them.phase_time_left = 5.0
	_run_until_idle(sim, CombatSimulation.PLAYER)
	var moved := sim.distance() - 60.0
	check(moved > 0.0 and moved < HOOK.displacement, "blocked, it still moves them, less (%.1f)" % moved)


## An opening is not the moment for a jab: someone looking at the dog or
## recovering from a swing gets the heaviest blow available.
func _test_opening_gets_the_heavy_blow() -> void:
	var sim := CombatSimulation.new(PLAYER, JOGGER, 11)
	sim.fighters[0].position = -30.0
	sim.fighters[1].position = 30.0
	var me := sim.fighters[CombatSimulation.PLAYER]
	var them := sim.fighters[CombatSimulation.OPPONENT]
	var picks := {}
	for i in 100:
		var skill := sim.choose_skill(me)
		picks[skill] = picks.get(skill, 0) + 1
	check(picks.size() > 1, "normally the choice varies (%d different)" % picks.size())
	them.exposed_until = sim.time + 1.0
	picks.clear()
	for i in 100:
		var skill := sim.choose_skill(me)
		picks[skill] = picks.get(skill, 0) + 1
	check(picks.size() == 1 and picks.has(KICK), "into a bark's opening: always the heaviest (kick)")
	them.exposed_until = -1.0
	them.action = JAB
	them.phase = CombatFighter.Phase.RECOVERY
	check(sim.choose_skill(me) == KICK, "into someone recovering from a swing: the heaviest too")


## P04-05: the kick is the long, committed option — furthest reach, longest
## wind-up, heaviest recovery — and it lands about when it always did.
func _test_kick() -> void:
	check(KICK.preferred_range > JAB.preferred_range and KICK.preferred_range > HOOK.preferred_range, "a kick reaches furthest")
	check(KICK.windup > HOOK.windup and KICK.windup > JAB.windup, "and telegraphs longest")
	check(KICK.recovery > HOOK.recovery and KICK.recovery > JAB.recovery, "and takes longest to recover from")
	check(KICK.whiff_recovery > JAB.whiff_recovery, "a missed kick costs more than a missed jab")
	check(KICK.strike_time > 0.0 and KICK.contact_time > 0.0 and KICK.follow_through > 0.0, "it has all five phases")
	var lands_at := KICK.windup + KICK.strike_time
	check(lands_at >= 0.7 and lands_at <= 0.85, "it lands about 0.8 s after the telegraph starts (%.2f)" % lands_at)
	var total := KICK.windup + KICK.strike_time + KICK.contact_time + KICK.follow_through + KICK.recovery
	var hook_total := HOOK.windup + HOOK.strike_time + HOOK.contact_time + HOOK.follow_through + HOOK.recovery
	check(total > hook_total, "start to ready, the kick is the biggest commitment (%.2f s)" % total)

	var sim := _duel(KICK.preferred_range - 5.0)
	var log := _log(sim)
	_start_attack(sim.fighters[CombatSimulation.PLAYER], KICK)
	_run_until_idle(sim, CombatSimulation.PLAYER)
	check(log.any(func(e: Array) -> bool: return e[0] == &"hit"), "it lands from where a jab cannot")


## P04-06: a dodge is getting out of reach, not a shield. Too late and still
## in reach, you are hit however hard you are trying to get away.
func _test_dodge_is_spatial() -> void:
	# In time: moving back clears the kick's reach before its window opens.
	var sim := _duel(60.0)
	var me := sim.fighters[CombatSimulation.PLAYER]
	var them := sim.fighters[CombatSimulation.OPPONENT]
	var log := _log(sim)
	_start_attack(them, KICK)
	me.action = DODGE
	me.phase = CombatFighter.Phase.ACTIVE
	me.phase_time_left = DODGE.active_time
	var at_contact := -1.0
	for i in 120:
		sim.step(STEP)
		if at_contact < 0.0 and them.phase == CombatFighter.Phase.CONTACT:
			at_contact = sim.distance()
		if them.is_idle():
			break
	check(log.any(func(e: Array) -> bool: return e[0] == &"dodged"), "a dodge in time is reported as a dodge")
	check_eq(me.hp, me.max_hp, "and costs nothing")
	check(at_contact > KICK.preferred_range + CombatSimulation.REACH_TOLERANCE, "because they were out of reach when the window opened (%.0f)" % at_contact)

	# Too late: still dodging, still in reach when the window opens — hit.
	sim = _duel(60.0)
	me = sim.fighters[CombatSimulation.PLAYER]
	them = sim.fighters[CombatSimulation.OPPONENT]
	log = _log(sim)
	_start_attack(them, JAB)
	them.phase_time_left = 0.02
	me.action = DODGE
	me.phase = CombatFighter.Phase.ACTIVE
	me.phase_time_left = DODGE.active_time
	_run_until_idle(sim, CombatSimulation.OPPONENT)
	check(log.any(func(e: Array) -> bool: return e[0] == &"hit"), "a dodge that has not got them out of reach does not save them")
	check(me.hp < me.max_hp, "and it hurts")


## P04-07: every attack holds the fight for its own short beat, inside the
## spec's ranges — light 0.04–0.07 s, heavy 0.06–0.10 s.
func _test_hit_stop_ranges() -> void:
	check(JAB.hit_stop >= 0.04 and JAB.hit_stop <= 0.07, "a jab's hit-stop is light (%.2f)" % JAB.hit_stop)
	for skill: CombatSkillData in [HOOK, KICK]:
		check(skill.hit_stop >= 0.06 and skill.hit_stop <= 0.10, "%s's hit-stop is heavy (%.2f)" % [skill.id, skill.hit_stop])
	check(JAB.hit_stop < HOOK.hit_stop and HOOK.hit_stop <= KICK.hit_stop, "and it grows with the blow")
	check(CombatCoordinator3D.HITSTOP_MAX <= 0.10, "nothing holds longer than the heavy range")

