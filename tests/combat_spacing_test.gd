extends "res://tests/test_case.gd"
## P04-02, without scenes: fighters hold a spacing band, never stand inside
## each other, circle and sidestep round each other (so the line they fight on
## turns), back out when too close, and never simply stand trading blows.

const PLAYER: FighterData = preload("res://data/combat/fighters/player_human.tres")
const OPPONENTS: Array[FighterData] = [
	preload("res://data/combat/fighters/opp01_jogger.tres"),
	preload("res://data/combat/fighters/opp02_delivery.tres"),
	preload("res://data/combat/fighters/opp03_gym.tres"),
]
const STEP: float = 1.0 / 60.0
const RUNS: int = 12

var spacing: SpacingData


func _ready() -> void:
	spacing = DataRegistry.spacing
	check(spacing != null, "spacing is data (data/combat/spacing.tres)")
	check(spacing.hard_min_separation >= 2.0 * DataRegistry.presence.human_radius * 100.0, "the closest two people get is wider than two bodies")
	check(spacing.ideal_min >= spacing.hard_min_separation and spacing.ideal_max > spacing.ideal_min, "the ideal band sits outside touching distance")
	_test_circling_keeps_distance()
	_test_backstep_when_too_close()
	_test_real_fights()
	_test_deterministic()
	_test_walls()
	finish()


## Circling moves someone round the other person: the gap between them stays
## the same and only the line turns.
func _test_circling_keeps_distance() -> void:
	var sim := CombatSimulation.new(PLAYER, OPPONENTS[0], 7, null, DataRegistry.spacing.ideal_min)
	for fighter in sim.fighters:
		fighter.ready_at = 99.0  # nobody attacks
	var before := sim.distance()
	var opponent_before := sim.world_position(CombatSimulation.OPPONENT)
	for i in 60:
		sim.step(STEP)
	check(absf(sim.distance() - before) < 0.01, "circling keeps the distance (%.2f -> %.2f)" % [before, sim.distance()])
	check(absf(sim.line_angle) > 0.2, "and turns the line they fight on (%.2f rad)" % sim.line_angle)
	var gap := sim.world_position(CombatSimulation.OPPONENT).distance_to(sim.world_position(CombatSimulation.PLAYER))
	check(absf(gap - sim.distance()) < 0.01, "ground positions agree with the distance")
	check(sim.world_position(CombatSimulation.OPPONENT).distance_to(opponent_before) > 5.0, "they actually moved on the ground")
	check(sim.fighters[0].footwork != CombatFighter.Footwork.APPROACH, "in range nobody closes")


## Too close, a fighter steps back out rather than standing on top of the
## other person.
func _test_backstep_when_too_close() -> void:
	var sim := CombatSimulation.new(PLAYER, OPPONENTS[0], 3, null, spacing.hard_min_separation + 1.0)
	for fighter in sim.fighters:
		fighter.ready_at = 99.0
	sim.step(STEP)
	check(sim.fighters.any(func(f: CombatFighter) -> bool: return f.footwork == CombatFighter.Footwork.BACKSTEP), "too close: someone backsteps")
	for i in 30:
		sim.step(STEP)
	check(sim.distance() >= spacing.ideal_min, "and the distance is back in the band (%.1f)" % sim.distance())


func _test_real_fights() -> void:
	var seen: Dictionary[int, int] = {}
	var closest := INF
	var idle_frames := 0
	var still_frames := 0
	var turned := 0.0
	var resets := 0
	var fights := 0
	for opponent in OPPONENTS:
		for i in RUNS:
			var sim := CombatSimulation.new(PLAYER, opponent, 5000 + i)
			sim.set_lateral(1.0 if i % 2 == 0 else -1.0)
			var last := [sim.world_position(0), sim.world_position(1)]
			var was_recovering := [false, false]
			var min_angle := 0.0
			var max_angle := 0.0
			while not sim.is_finished():
				sim.step(STEP)
				closest = minf(closest, sim.distance())
				min_angle = minf(min_angle, sim.line_angle)
				max_angle = maxf(max_angle, sim.line_angle)
				for side in 2:
					var fighter := sim.fighters[side]
					seen[fighter.footwork] = seen.get(fighter.footwork, 0) + 1
					var now := sim.world_position(side)
					# Free to move (no action, not looking at a dog): are they?
					if fighter.is_idle() and sim.time >= fighter.distracted_until:
						idle_frames += 1
						if now.distance_to(last[side]) < 0.01:
							still_frames += 1
					if was_recovering[side] and fighter.is_idle() and fighter.footwork == CombatFighter.Footwork.BACKSTEP:
						resets += 1
					was_recovering[side] = fighter.phase == CombatFighter.Phase.RECOVERY
					last[side] = now
			turned += max_angle - min_angle
			fights += 1
	check(closest >= spacing.hard_min_separation - 0.01, "nobody ever stands inside the other (closest %.1f)" % closest)
	for kind in [CombatFighter.Footwork.APPROACH, CombatFighter.Footwork.CIRCLE, CombatFighter.Footwork.SIDESTEP, CombatFighter.Footwork.BACKSTEP]:
		check(seen.get(kind, 0) > 0, "%s happens in real fights" % CombatFighter.Footwork.keys()[kind])
	var still_share := float(still_frames) / maxf(idle_frames, 1.0)
	check(still_share < 0.05, "free to move, they are moving: no standing and trading (%.1f%% still)" % (still_share * 100.0))
	check(turned / fights > 0.6, "the fight turns round on the ground (%.2f rad per fight)" % (turned / fights))
	check(resets > fights, "they come off exchanges to reset the distance (%d in %d fights)" % [resets, fights])


func _test_deterministic() -> void:
	var a := CombatSimulation.new(PLAYER, OPPONENTS[1], 99)
	var b := CombatSimulation.new(PLAYER, OPPONENTS[1], 99)
	a.run_to_end(STEP)
	b.run_to_end(STEP)
	check_eq(a.result, b.result, "same seed, same result")
	check(a.world_position(0).is_equal_approx(b.world_position(0)) and is_equal_approx(a.line_angle, b.line_angle), "same seed, same footwork")


## P04-08: with somewhere they cannot stand, nobody steps, dodges or is
## knocked into it, and nobody is stuck against it: a wall behind one of them
## and a post between them both still end in a winner.
func _test_walls() -> void:
	var wall_x := -80.0
	var post := func(g: Vector2) -> bool: return not (absf(g.x) < 12.0 and absf(g.y) < 12.0)
	for case: Array in [["wall behind the player", func(g: Vector2) -> bool: return g.x > wall_x], ["post between them", post]]:
		var decided := 0
		var inside := 0
		for i in 12:
			var sim := CombatSimulation.new(PLAYER, OPPONENTS[i % 3], 8000 + i, null, 120.0)
			sim.walkable = case[1]
			while not sim.is_finished():
				sim.step(STEP)
				for side in 2:
					if not case[1].call(sim.world_position(side)):
						inside += 1
			if sim.result == CombatSimulation.Result.VICTORY or sim.result == CombatSimulation.Result.DEFEAT:
				decided += 1
		check_eq(inside, 0, "%s: nobody ever stands in it" % case[0])
		check_eq(decided, 12, "%s: every fight still ends in a winner, nobody stuck (%d/12)" % [case[0], decided])

	# Someone who starts inside something may always move out.
	var sim := CombatSimulation.new(PLAYER, OPPONENTS[0], 1, null, 100.0)
	sim.walkable = func(g: Vector2) -> bool: return g.x > -40.0
	var before := sim.fighters[CombatSimulation.PLAYER].position
	sim.fighters[CombatSimulation.OPPONENT].ready_at = 99.0
	sim.fighters[CombatSimulation.PLAYER].ready_at = 99.0
	for i in 30:
		sim.step(STEP)
	check(sim.fighters[CombatSimulation.PLAYER].position > before, "a fighter caught in something is never pinned there")

