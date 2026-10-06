extends "res://tests/test_case.gd"
## P-05: weapons. P05-02 the archetype interface, P05-03 the Unarmed baseline.

const PLAYER: FighterData = preload("res://data/combat/fighters/player_human.tres")
const JOGGER: FighterData = preload("res://data/combat/fighters/opp01_jogger.tres")
const DELIVERY: FighterData = preload("res://data/combat/fighters/opp02_delivery.tres")


func _ready() -> void:
	_test_interface()
	_test_unarmed_baseline()
	_test_umbrella()
	_test_long_object()
	_test_heavy_blunt()
	_test_styles()
	await _test_contact()
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
	check_eq(me.ideal_min(sim.spacing) - me.style_shift, 90.0, "the weapon sets where they want to stand")
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


## P05-05: a long object controls the distance and is weak when crowded:
## its real moves cannot start inside their minimum range, and up close all
## it has is a shove that makes room.
func _test_long_object() -> void:
	var broom := DataRegistry.get_weapon(&"broom")
	check(broom != null and broom.archetype == WeaponData.Archetype.LONG_OBJECT, "P05-05: the broom is a long object")
	check(broom.item.size_class == ItemData.SizeClass.LARGE and not broom.item.is_safe_eligible(), "too big for the dog's backpack")
	var thrust: CombatSkillData = load("res://data/combat/skills/skill_long_thrust.tres")
	var shove: CombatSkillData = load("res://data/combat/skills/skill_long_butt.tres")
	var poke: CombatSkillData = load("res://data/combat/skills/skill_umbrella_poke.tres")
	check(thrust.preferred_range > poke.preferred_range, "it reaches further than the umbrella")
	check(broom.moveset.ideal_min > DataRegistry.spacing.ideal_max + 30.0, "and wants the fight well out")
	var held := PLAYER.armed(broom)
	var sim := CombatSimulation.new(held, JOGGER, 8)
	var me := sim.fighters[CombatSimulation.PLAYER]
	sim.fighters[CombatSimulation.OPPONENT].position = me.position + 60.0
	check(not sim._condition_met(me, thrust), "crowded at 0.6 m: no thrust")
	check(sim._condition_met(me, shove), "only the shove")
	check(shove.displacement > thrust.displacement and shove.power < thrust.power, "which makes room rather than hurting")
	check(sim._approach_at(me) > 90.0, "closing in, they stop where the pole works, not at shove range (%.0f)" % sim._approach_at(me))
	sim.fighters[CombatSimulation.OPPONENT].position = me.position + 120.0
	check(sim._condition_met(me, thrust), "at 1.2 m the thrust lands")
	var gaps := {"umbrella": 0.0, "broom": 0.0}
	for i in 20:
		for key: String in ["umbrella", "broom"]:
			var fight := CombatSimulation.new(PLAYER.armed(DataRegistry.get_weapon(StringName(key))), JOGGER, 600 + i)
			var total := 0.0
			var steps := 0
			while not fight.is_finished() and steps < 6000:
				fight.step(1.0 / 60.0)
				total += fight.distance()
				steps += 1
			gaps[key] += total / maxf(steps, 1)
	check(gaps["broom"] > gaps["umbrella"] + 5.0, "a broom fight is held further out than an umbrella fight (%.0f vs %.0f)" % [gaps["broom"] / 20.0, gaps["umbrella"] / 20.0])


## P05-06: heavy blunt is commitment — slow to start, slow to recover, heavy
## on the feet, and it goes through a guard.
func _test_heavy_blunt() -> void:
	var dumbbell := DataRegistry.get_weapon(&"old_dumbbell")
	check(dumbbell != null and dumbbell.archetype == WeaponData.Archetype.HEAVY_BLUNT, "P05-06: the old dumbbell is heavy blunt")
	check(not dumbbell.item.is_safe_eligible(), "and not something for the dog's backpack")
	var kick: CombatSkillData = load("res://data/combat/skills/skill_kick.tres")
	for skill in dumbbell.moveset.attacks:
		check(skill.is_heavy(), "%s is a heavy blow" % skill.id)
		check(skill.windup >= 0.6 and skill.recovery > kick.recovery, "%s commits: long wind-up, longer recovery than a kick" % skill.id)
		check(skill.guard_break >= 0.7, "%s goes through a guard" % skill.id)
	var held := PLAYER.armed(dumbbell)
	var bare := CombatSimulation.new(PLAYER, JOGGER, 2)
	var heavy := CombatSimulation.new(held, JOGGER, 2)
	check(heavy.fighters[0].move_speed < bare.fighters[0].move_speed * 0.8, "it slows their feet")
	# Through a block: the same blow, blocked by a fist guard, still hurts.
	var block: CombatSkillData = load("res://data/combat/skills/skill_block.tres")
	var smash: CombatSkillData = load("res://data/combat/skills/skill_heavy_smash.tres")
	var through := 1.0 - block.damage_reduction * (1.0 - smash.guard_break)
	check(through > 0.8, "a blocked smash still lands %.0f %% of itself" % (through * 100.0))
	var wins := {"bare": 0, "dumbbell": 0}
	for i in 30:
		for key: String in ["bare", "dumbbell"]:
			var fight := CombatSimulation.new(held if key == "dumbbell" else PLAYER, DELIVERY, 800 + i)
			if fight.run_to_end() == CombatSimulation.Result.VICTORY:
				wins[key] += 1
	check(wins["dumbbell"] >= wins["bare"], "against the tough Delivery Worker it helps (%d vs %d of 30)" % [wins["dumbbell"], wins["bare"]])


## P05-07: the same umbrella in different hands. Untrained misjudges its
## reach, swings from out of range and is left open; calm waits and
## counters; a scrapper gets in closer. Bare hands ignore style entirely.
func _test_styles() -> void:
	var untrained := DataRegistry.combat_style(CombatStyleData.Style.UNTRAINED)
	var calm := DataRegistry.combat_style(CombatStyleData.Style.CALM)
	var scrapper := DataRegistry.combat_style(CombatStyleData.Style.SCRAPPER)
	check(untrained != null and calm != null and scrapper != null, "P05-07: three styles are data")
	# Who the owner grows into.
	var balance := DataRegistry.training
	var fresh := HumanGrowth.new()
	check(GrowthResolver.combat_style(fresh, balance, [&"patient"]) == untrained, "untrained until the dog has trained them")
	var trained := HumanGrowth.new()
	for tag in [TrainingEventData.Tag.RUN, TrainingEventData.Tag.ENDURE, TrainingEventData.Tag.COURAGE]:
		trained.growth[TrainingEventData.tag_name(tag)] = balance.trait_full_growth
	check(GrowthResolver.combat_style(trained, balance, [&"patient", &"gentle"]) == calm, "then a patient, gentle human fights calm")
	check(GrowthResolver.combat_style(trained, balance, [&"energetic", &"bold"]) == scrapper, "and an energetic, bold one scraps")
	# Bare hands: the P-04 baseline, whatever their style.
	var styled := PLAYER.duplicate() as FighterData
	styled.style = scrapper
	var a := CombatSimulation.new(PLAYER, JOGGER, 21)
	var b := CombatSimulation.new(styled, JOGGER, 21)
	a.run_to_end()
	b.run_to_end()
	check(a.result == b.result and is_equal_approx(a.time, b.time), "bare-handed, style changes nothing")
	# Armed: the same umbrella fights differently.
	var umbrella := DataRegistry.get_weapon(&"umbrella")
	var stats := {}
	for style: CombatStyleData in [untrained, calm, scrapper]:
		var me := PLAYER.armed(umbrella)
		me.style = style
		var c := {"whiff": 0, "counter": 0, "attacks": 0, "gap": 0.0, "steps": 0}
		for i in 30:
			var fight := CombatSimulation.new(me, DELIVERY, 1200 + i)
			fight.combat_event.connect(func(kind: StringName, side: int, skill: CombatSkillData, _v: float) -> void:
				if side != CombatSimulation.PLAYER or skill == null:
					return
				if kind == &"missed":
					c["whiff"] += 1
				elif kind == &"skill_started" and skill.effect == CombatSkillData.Effect.ATTACK:
					c["attacks"] += 1
					if skill.condition == CombatSkillData.Condition.TARGET_OPEN:
						c["counter"] += 1)
			while not fight.is_finished() and c["steps"] < 400000:
				fight.step(1.0 / 60.0)
				c["gap"] += fight.distance()
				c["steps"] += 1
		stats[style.style] = c
	var u: Dictionary = stats[CombatStyleData.Style.UNTRAINED]
	var k: Dictionary = stats[CombatStyleData.Style.CALM]
	var sc: Dictionary = stats[CombatStyleData.Style.SCRAPPER]
	check(u["whiff"] > k["whiff"] * 5 + 10, "untrained swings from out of reach and misses (%d whiffs vs calm %d)" % [u["whiff"], k["whiff"]])
	check(float(k["counter"]) / k["attacks"] > float(u["counter"]) / u["attacks"] + 0.05, "calm counters more of the time (%.0f %% vs %.0f %%)" % [100.0 * k["counter"] / k["attacks"], 100.0 * u["counter"] / u["attacks"]])
	check(scrapper.ideal_shift < calm.ideal_shift and scrapper.quick_weight > calm.quick_weight, "a scrapper wants in closer and goes for the quick move")


## P05-08: a weapon lands only in its P-04 contact window, and only where it
## is drawn — no invisible range. A thrust's drawn tip is where its reach
## says (the target's body front is 0.17 m from their centre); a swing sweeps
## across, so it is held to the same allowance P-04 gives the hook.
func _test_contact() -> void:
	var outside := {"n": 0, "hits": 0}
	for id in [&"umbrella", &"broom", &"old_dumbbell"]:
		for i in 6:
			var sim := CombatSimulation.new(PLAYER.armed(DataRegistry.get_weapon(id)), JOGGER, 1500 + i)
			sim.combat_event.connect(func(kind: StringName, side: int, _skill: CombatSkillData, _v: float) -> void:
				if side == CombatSimulation.PLAYER and kind in [&"hit", &"blocked"]:
					outside["hits"] += 1
					if sim.fighters[CombatSimulation.PLAYER].phase != CombatFighter.Phase.CONTACT:
						outside["n"] += 1)
			sim.run_to_end(1.0 / 60.0)
	check(outside["hits"] > 50 and outside["n"] == 0, "P05-08: every weapon blow lands inside its contact window (%d of %d outside)" % [outside["n"], outside["hits"]])
	var body_front := 0.17
	var hook_allowance := 0.30
	for id in [&"umbrella", &"broom", &"old_dumbbell"]:
		var weapon := DataRegistry.get_weapon(id)
		for skill in weapon.moveset.attacks:
			if skill.preferred_range < weapon.moveset.ideal_min - 1.0 and weapon.moveset.ideal_min > 0.0:
				continue  # a crowded-only move (the broom's shove) is the hand, not the tip
			var puppet := FighterPuppet3D.new()
			add_child(puppet)
			puppet.apply(PLAYER)
			puppet.hold(weapon)
			await get_tree().process_frame
			var clip: String = FighterPuppet3D.ATTACK_CLIPS.get(skill.animation_key, "Jab")
			var drawn := 0.0
			for t in [0.45, 0.5, 0.55]:
				(puppet._body as P04HumanVisual).pose_clip(clip, t)
				await get_tree().process_frame
				var tip: Vector3 = puppet._prop.global_transform * Vector3(0, WeaponProp3D.TIP[weapon.archetype], 0)
				drawn = maxf(drawn, (tip - puppet.global_position).dot(-puppet.global_basis.z))
			var reach := skill.preferred_range / 100.0 - body_front
			if clip == "Jab":
				check(absf(drawn - reach) < 0.15, "%s: the drawn tip reaches %.2f m, its reach %.2f m" % [skill.id, drawn, reach])
			else:
				check(reach - drawn <= hook_allowance, "%s: a swing reaching %.2f m is drawn to %.2f m (hook allowance)" % [skill.id, reach, drawn])
			puppet.queue_free()
