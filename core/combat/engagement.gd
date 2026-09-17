class_name Engagement
extends RefCounted
## One active fight in the Run World: the player's human vs one pair.
## The simulation's 1D line is laid along the axis between the two humans
## where the fight started, so nobody is teleported.

var simulation: CombatSimulation
var pair: OpponentPair
var origin: Vector2
## Unit vector from the player's human towards the opponent.
var axis: Vector2
var accumulator: float = 0.0


func _init(sim: CombatSimulation, opponent: OpponentPair, player_position: Vector2, opponent_position: Vector2) -> void:
	simulation = sim
	pair = opponent
	origin = (player_position + opponent_position) / 2.0
	axis = (opponent_position - player_position).normalized()
	if axis == Vector2.ZERO:
		axis = Vector2.RIGHT


func world_position(side: int) -> Vector2:
	return origin + axis * simulation.fighters[side].position


## Horizontal facing for a side (-1 / 1).
func facing(side: int) -> float:
	var x := axis.x if side == CombatSimulation.PLAYER else -axis.x
	return -1.0 if x < 0.0 else 1.0
