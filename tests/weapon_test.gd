extends "res://tests/test_case.gd"
## P-05: weapons. P05-02 the archetype interface, P05-03 the Unarmed baseline.

const PLAYER: FighterData = preload("res://data/combat/fighters/player_human.tres")
const JOGGER: FighterData = preload("res://data/combat/fighters/opp01_jogger.tres")
const DELIVERY: FighterData = preload("res://data/combat/fighters/opp02_delivery.tres")


func _ready() -> void:
	_test_interface()
	_test_unarmed_baseline()
	_test_umbrella()
	finish()


func _test_interface() -> void:
	var unarmed := DataRegistry.get_weapon(&"unarmed")
	check(unarmed != null and unarmed.archetype == WeaponData.Archetype.UNARMED, "P05-02: the unarmed archetype is data")
	check(unarmed.is_unarmed(), "and it is bare hands")
	# A weapon replaces the moveset and moves where they want to stand.
	var poke := (load("res://data/combat/skills/skill_jab.tres") as CombatSkillData).duplicate() as CombatSkillData
	poke.id = &"test_poke"
	poke.preferred_range = 110.0
	var moves := WeaponMoveSet.new()
	moves.attacks = [poke]
	moves.defenses = [load("res://data/combat/skills/skill_block.tres")]
	moves.ideal_min = 90.0
	moves.ideal_max = 100.0
	var stick := WeaponData.new()
	stick.id = &"test_stick"
	stick.archetype = WeaponData.Archetype.LONG_OBJECT
	stick.moveset = moves
	var held := PLAYER.armed(stick)
	check(held != PLAYER and held.weapon == stick, "holding something is a copy of the fighter, holding it")
	check_eq(held.skills.size(), 2, "with the weapon's moves in place of their own")
	check(held.skills.has(poke) and not held.skills.has(load("res://data/combat/skills/skill_kick.tres")), "the poke, not the kick")
	check_eq(PLAYER.skills.size(), 5, "the fighter themselves is untouched")
	check(PLAYER.weapon == null, "and still empty-handed")
	var sim := CombatSimulation.new(held, JOGGER, 3)
	var me := sim.fighters[CombatSimulation.PLAYER]
	var them := sim.fighters[CombatSimulation.OPPONENT]
	check_eq(me.ideal_min(sim.spacing), 90.0, "the weapon sets where they want to stand")
	check_eq(them.ideal_max(sim.spacing), sim.spacing.ideal_max, "the other fighter keeps hand-to-hand spacing")


## P05-03: bare hands is exactly the P-04 fighter — same object, same fights.
func _test_unarmed_baseline() -> void:
	var unarmed := DataRegistry.get_weapon(&"unarmed")
	check(PLAYER.armed(null) == PLAYER and PLAYER.armed(unarmed) == PLAYER, "P05-03: unarmed is the fighter as they are")
	for opponent: FighterData in [JOGGER, DELIVERY]:
		for seed_value in [11, 12, 13]:
			var a := CombatSimulation.new(PLAYER, opponent, seed_value)
			var b := CombatSimulation.new(PLAYER.armed(unarmed), opponent, seed_value)
			a.run_to_end()
			b.run_to_end()
			check(a.result == b.result and is_equal_approx(a.time, b.time) and a.fighters[0].uses == b.fighters[0].uses, "an unarmed fight plays out exactly as before (%s, seed %d)" % [opponent.id, seed_value])


## P05-04: the umbrella is a different way of fighting, not a damage bonus —
## longer reach, a fight held further out, a guard and a counter that only
## exists as an answer.
func _test_umbrella() -> void:
	var umbrella := DataRegistry.get_weapon(&"umbrella")
	check(umbrella != null and umbrella.archetype == WeaponData.Archetype.UMBRELLA, "P05-04: the umbrella is data")
	check(umbrella.item == DataRegistry.get_item(&"umbrella") and DataRegistry.weapon_for_item(&"umbrella") == umbrella, "and it is the umbrella found in the street")
	var ids := umbrella.moveset.skills().map(func(k: CombatSkillData) -> StringName: return k.id)
	for id in [&"skill_umbrella_poke", &"skill_umbrella_swing", &"skill_umbrella_counter", &"skill_umbrella_guard"]:
		check(ids.has(id), "it can %s" % id)
	var jab: CombatSkillData = load("res://data/combat/skills/skill_jab.tres")
	var poke: CombatSkillData = load("res://data/combat/skills/skill_umbrella_poke.tres")
	check(poke.preferred_range > jab.preferred_range + 25.0, "the poke reaches well past a fist (%d vs %d)" % [poke.preferred_range, jab.preferred_range])
	check(umbrella.moveset.ideal_min > DataRegistry.spacing.ideal_max, "and the umbrella wants the fight further out than fists do")
	# The counter only exists as an answer.
	var counter: CombatSkillData = load("res://data/combat/skills/skill_umbrella_counter.tres")
	var held := PLAYER.armed(umbrella)
	var sim := CombatSimulation.new(held, JOGGER, 5)
	var me := sim.fighters[CombatSimulation.PLAYER]
	var them := sim.fighters[CombatSimulation.OPPONENT]
	sim.fighters[CombatSimulation.OPPONENT].position = me.position + 90.0
	check(not sim._condition_met(me, counter), "no counter into someone who is ready")
	them.phase = CombatFighter.Phase.RECOVERY
	check(sim._condition_met(me, counter), "a counter into someone recovering from a swing")
	# In real fights: held further out, and counters thrown.
	var gaps := {"bare": 0.0, "umbrella": 0.0}
	var counters := {"n": 0}
	var wins := {"bare": 0, "umbrella": 0}
	for i in 30:
		for armed: bool in [false, true]:
			var key := "umbrella" if armed else "bare"
			var fight := CombatSimulation.new(held if armed else PLAYER, JOGGER, 400 + i)
			var total := 0.0
			var steps := 0
			fight.combat_event.connect(func(kind: StringName, side: int, skill: CombatSkillData, _v: float) -> void:
				if kind == &"skill_started" and side == 0 and skill == counter:
					counters["n"] += 1)
			while not fight.is_finished() and steps < 6000:
				fight.step(1.0 / 60.0)
				total += fight.distance()
				steps += 1
			gaps[key] += total / maxf(steps, 1)
			if fight.result == CombatSimulation.Result.VICTORY:
				wins[key] += 1
	check(gaps["umbrella"] > gaps["bare"] + 8.0, "with the umbrella the fight is held further out (%.0f vs %.0f units)" % [gaps["umbrella"] / 30.0, gaps["bare"] / 30.0])
	check(counters["n"] > 30, "counter pokes are thrown into openings (%d in 30 fights)" % counters["n"])
	check(wins["umbrella"] >= wins["bare"], "against a quick, light fighter it helps (%d vs %d of 30)" % [wins["umbrella"], wins["bare"]])
	# Seen, not only simulated: the puppet holds it in the lead hand.
	var puppet := FighterPuppet3D.new()
	add_child(puppet)
	puppet.apply(PLAYER)
	puppet.hold(umbrella)
	check(puppet._prop != null and puppet._prop.is_inside_tree(), "the human is seen holding the umbrella")
	puppet.hold(null)
	check(puppet._prop == null, "and empty-handed again without it")
	puppet.queue_free()
