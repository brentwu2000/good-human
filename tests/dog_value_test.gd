extends "res://tests/test_case.gd"
## ADR-L02 / P04-10: the dog changes the exchange, not the result. Against
## every ordinary opponent, a perfectly timed dog — barking at a steady
## rhythm, pulling the owner out of every wind-up it can — helps the owner,
## and never turns a fight into a certainty.

const PLAYER: FighterData = preload("res://data/combat/fighters/player_human.tres")
const OPPONENTS: Array[FighterData] = [
	preload("res://data/combat/fighters/opp01_jogger.tres"),
	preload("res://data/combat/fighters/opp02_delivery.tres"),
	preload("res://data/combat/fighters/opp03_gym.tres"),
]
const FIGHTS: int = 60
const BARK: int = 1
const PULL: int = 2


func _ready() -> void:
	var gains := {BARK: 0, PULL: 0}
	for opponent in OPPONENTS:
		var plain := _wins(opponent, 0)
		var both := _wins(opponent, BARK | PULL)
		for mode: int in [BARK, PULL]:
			var helped := _wins(opponent, mode)
			gains[mode] += helped - plain
		check(both < FIGHTS, "%s: even a perfect dog does not make the fight a certainty (%d -> %d of %d)" % [opponent.id, plain, both, FIGHTS])
		check(both - plain <= FIGHTS * 0.35, "%s: the dog helps within limits (%d -> %d of %d)" % [opponent.id, plain, both, FIGHTS])
	check(gains[BARK] > 0, "barking at the right moments helps the owner overall (%+d over %d fights)" % [gains[BARK], FIGHTS * 3])
	check(gains[PULL] > 0, "and so does the leash (%+d)" % gains[PULL])
	finish()


## A perfect dog: barks every 6 s through DogAgency's own resistance, and
## pulls the owner clear of every wind-up while the leash still can.
func _wins(opponent: FighterData, mode: int) -> int:
	var wins := 0
	for i in FIGHTS:
		var sim := CombatSimulation.new(PLAYER, opponent, 1000 + i)
		var next_bark := 1.0
		var recent: Array[float] = []
		var heard := 0
		var pull_ready := 0.0
		var saves := 0
		while not sim.is_finished():
			sim.step(1.0 / 30.0)
			var them := sim.fighters[CombatSimulation.OPPONENT]
			if mode & BARK and sim.time >= next_bark:
				next_bark += 6.0
				while not recent.is_empty() and sim.time - recent[0] > DogAgency.BARK_RESIST_WINDOW:
					recent.pop_front()
				var effect: float = pow(0.5, recent.size()) * pow(DogAgency.BARK_HABITUATION, heard)
				recent.append(sim.time)
				heard += 1
				if effect >= DogAgency.BARK_MIN_EFFECT:
					sim.distract(CombatSimulation.OPPONENT, DogAgency.BARK_DISTRACT_SECONDS * effect)
			if mode & PULL and saves < DogAgency.PULL_SAVES_PER_FIGHT and sim.time >= pull_ready and them.is_winding_up_attack() and sim.time - them.windup_started_at > 0.15:
				pull_ready = sim.time + DogAgency.PULL_COOLDOWN
				if sim.pull(CombatSimulation.PLAYER, DogAgency.PULL_DISTANCE * CombatCoordinator3D.UNITS_PER_METER):
					saves += 1
		if sim.result == CombatSimulation.Result.VICTORY:
			wins += 1
	return wins
