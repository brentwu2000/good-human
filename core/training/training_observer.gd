class_name TrainingObserver
extends Node
## Watches the Run World for meaningful dog-caused moments and reports them
## as TrainingEvents to RunManager. The only place that turns world
## behaviour into training; interactables and actors stay unaware of it.

## Continuous dragging needed for one "dragged" moment.
const DRAG_SECONDS: float = 3.0
## A brief slowdown (stumble, breather, corner) does not break a drag.
const DRAG_GRACE: float = 0.4
## Owner distance walked with a heavy bag for one moment.
const HEAVY_BAG_DISTANCE: float = 700.0
## Owner held in place while the dog keeps pulling.
const TUG_SECONDS: float = 0.6
## Owner distance per long-walk moment.
const LONG_WALK_DISTANCE: float = 3000.0
## Dog staying near a pair counts as lingering.
const LINGER_DISTANCE: float = 200.0
const LINGER_SECONDS: float = 3.0
const ESCAPE_HURT_RATIO: float = 0.6
const HARD_FIGHT_HP_RATIO: float = 0.4
const HARD_FIGHT_SECONDS: float = 20.0
## Minimum gap between owner remarks about training.
const LINE_GAP: float = 6.0

@export var run_manager: RunManager
@export var human: HumanFollower
@export var coordinator: CombatCoordinator
@export var behavior: OwnerBehavior

var _drag_time: float = 0.0
var _drag_pause: float = 0.0
var _heavy_distance: float = 0.0
var _tug_time: float = 0.0
var _walk_distance: float = 0.0
var _linger: Dictionary[StringName, float] = {}
var _last_position: Vector2
var _last_line_time: float = -INF


func _ready() -> void:
	run_manager.run_started.connect(_on_run_started)
	run_manager.training.event_recorded.connect(_on_event_recorded)
	coordinator.engagement_started.connect(_on_engagement_started)
	coordinator.engagement_ended.connect(_on_engagement_ended)
	if behavior != null:
		behavior.exhausted.connect(func() -> void: _record(&"endure_exhausted"))


func _on_run_started(_seed: int) -> void:
	_drag_time = 0.0
	_heavy_distance = 0.0
	_tug_time = 0.0
	_walk_distance = 0.0
	_linger.clear()
	_last_position = human.global_position
	_last_line_time = -INF


func _physics_process(delta: float) -> void:
	if not run_manager.is_running():
		return
	var moved := human.global_position.distance_to(_last_position)
	_last_position = human.global_position
	if not human.is_following():
		_drag_time = 0.0
		_tug_time = 0.0
		return
	# Ignore catch-up snaps.
	if moved < human.walk_speed:
		_walk_distance += moved
	if _walk_distance >= LONG_WALK_DISTANCE:
		_walk_distance -= LONG_WALK_DISTANCE
		_record(&"endure_long_walk")

	# RUN: dragged along at speed (a stumble or breather mid-drag still counts).
	if human.velocity.length() > human.walk_speed * OwnerBehavior.DRAGGED_SPEED_RATIO:
		_drag_pause = 0.0
		_drag_time += delta
		if _drag_time >= DRAG_SECONDS:
			_drag_time = 0.0
			_record(&"run_dragged")
	elif human.hold_time <= 0.0:
		_drag_pause += delta
		if _drag_pause > DRAG_GRACE:
			_drag_time = 0.0

	# STRAIN: walking with a heavy bag, or the dog pulling while the owner is stuck.
	if run_manager.human_run_inventory.used_slot_count() >= DataRegistry.training.heavy_bag_slots:
		_heavy_distance += moved if moved < human.walk_speed else 0.0
		if _heavy_distance >= HEAVY_BAG_DISTANCE:
			_heavy_distance = 0.0
			_record(&"strain_heavy_bag")
	var dog := run_manager.dog
	if dog != null and human.hold_time > 0.0 and dog.global_position.distance_to(human.global_position) > human.max_length:
		_tug_time += delta
		if _tug_time >= TUG_SECONDS:
			_tug_time = 0.0
			_record(&"strain_tug")
	else:
		_tug_time = 0.0

	_check_lingering(delta)


## SOCIAL: hanging around a pair without starting a fight. COURAGE when the
## pair is secretly dangerous.
func _check_lingering(delta: float) -> void:
	var dog := run_manager.dog
	if dog == null:
		return
	for pair in coordinator.get_pairs():
		if pair.encounter == null or pair.state != OpponentPair.State.IDLE:
			continue
		if dog.global_position.distance_to(pair.global_position) > LINGER_DISTANCE:
			_linger.erase(pair.spot_id)
			continue
		var before: float = _linger.get(pair.spot_id, 0.0)
		var now := before + delta
		_linger[pair.spot_id] = now
		if before < LINGER_SECONDS and now >= LINGER_SECONDS:
			var context := {"name": pair.encounter.human.display_name}
			_record(&"social_linger", pair.spot_id, context)
			if pair.encounter.tier == EncounterData.Tier.OVERPOWERED:
				_record(&"courage_linger_danger", pair.spot_id, context)


func _on_engagement_started(engagement: Engagement) -> void:
	var pair := engagement.pair
	var scale := 2.0 if pair.encounter.tier == EncounterData.Tier.OVERPOWERED else 1.0
	_linger.erase(pair.spot_id)
	_record(&"courage_provoke", pair.spot_id, {"name": pair.encounter.human.display_name}, scale)


func _on_engagement_ended(engagement: Engagement, result: CombatSimulation.Result) -> void:
	var sim := engagement.simulation
	var hp := sim.fighters[CombatSimulation.PLAYER].hp_ratio()
	match result:
		CombatSimulation.Result.DISENGAGED:
			_record(&"run_escape")
			if hp < ESCAPE_HURT_RATIO:
				_record(&"courage_escape")
		CombatSimulation.Result.VICTORY:
			if hp < HARD_FIGHT_HP_RATIO or sim.time > HARD_FIGHT_SECONDS:
				_record(&"endure_hard_fight")
		CombatSimulation.Result.DEFEAT:
			_record(&"endure_defeat")


func _record(event_id: StringName, key: StringName = &"", context: Dictionary = {}, scale: float = 1.0) -> void:
	run_manager.record_training(DataRegistry.get_training_event(event_id), key, "TrainingObserver", context, scale)


func _on_event_recorded(event: TrainingEvent) -> void:
	var line := event.data.owner_line
	if line.is_empty() or not human.is_following() or human.hold_time > 0.0:
		return
	if event.run_time - _last_line_time < LINE_GAP:
		return
	_last_line_time = event.run_time
	human.say(line, Color(0.95, 0.9, 0.75), 1.8)
