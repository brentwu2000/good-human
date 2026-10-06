extends "res://tests/test_case.gd"
## P-05: weapons. P05-02 the archetype interface, P05-03 the Unarmed baseline.

const PLAYER: FighterData = preload("res://data/combat/fighters/player_human.tres")
const JOGGER: FighterData = preload("res://data/combat/fighters/opp01_jogger.tres")
const DELIVERY: FighterData = preload("res://data/combat/fighters/opp02_delivery.tres")


func _ready() -> void:
	_test_interface()
	_test_unarmed_baseline()
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
