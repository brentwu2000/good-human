class_name RestSpot3D
extends Node3D
## S05-02: somewhere the owner can catch their breath (a bench, a bus stop).
## When the dog lets them stop here they get some of their condition back —
## a limited amount per spot per walk, so resting is a choice of where to go,
## not a refill.

const GROUP: StringName = &"rest_spots"

@export var run_manager: RunManager
@export var human: HumanFollower3D
## How close (m) the owner has to stand.
@export var radius: float = 2.2

## What this spot can still give on this walk.
var budget_left: float = 0.0
var _resting: bool = false


func _ready() -> void:
	add_to_group(GROUP)
	if run_manager != null:
		run_manager.run_started.connect(_on_run_started)
		budget_left = DataRegistry.balance.rest_recovery_budget


func _on_run_started(_seed: int) -> void:
	budget_left = DataRegistry.balance.rest_recovery_budget
	_resting = false


func is_owner_resting() -> bool:
	return _resting


func _physics_process(delta: float) -> void:
	if run_manager == null or human == null or not run_manager.is_running():
		return
	var at := human.global_position - global_position
	var close := Vector2(at.x, at.z).length() <= radius
	var can_rest := close and human.is_following() and human.planar_speed() < 0.5 \
		and budget_left > 0.0 and run_manager.owner_condition < 1.0
	if not can_rest:
		_resting = false
		return
	if not _resting:
		_resting = true
		human.say("坐一下……喘口氣。", Color(0.8, 0.95, 0.85))
	var gained := run_manager.recover_owner(minf(DataRegistry.balance.rest_recovery_per_second * delta, budget_left))
	budget_left -= gained
