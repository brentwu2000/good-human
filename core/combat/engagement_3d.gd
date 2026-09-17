class_name Engagement3D
extends RefCounted
## One active 3D fight: the simulation and the opponent pair. Same fields as
## Engagement, so training and goal observers handle both.

var simulation: CombatSimulation
var pair: OpponentPair3D


func _init(sim: CombatSimulation, opponent: OpponentPair3D) -> void:
	simulation = sim
	pair = opponent
