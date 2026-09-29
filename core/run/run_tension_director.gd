class_name RunTensionDirector
extends Node
## Sprint 05 S05-03: how tense the walk is, once going home has become
## possible, read from what is actually at stake — how long the dog has stayed
## out since, what the owner is carrying, how far home is, and what the world
## is offering (a standing temptation, a place the dog has marked today).
##
## Presentation only (GREED_TERRITORY_SYSTEM: "outputs are presentation, not
## arbitrary punishment"). It never touches the run RNG, the fights, the loot
## or extraction: the light turns towards evening and home calls more strongly,
## so the player feels the risk they chose — nothing scales behind their back.
##
## Outputs: `level` (0..1, eased) and `tension_changed`; the 3D walk turns it
## into an ambient shift and a stronger call from every open exit.
## Not yet an input: the owner's condition (it resets every fight; open owner
## decision, see SPRINT_STATUS S05-02).

signal tension_changed(level: float)

## How fast the eased level follows the target (per second): a mood, not a meter.
const EASE_RATE: float = 0.25
## Change in level worth telling listeners about.
const NOTIFY_STEP: float = 0.01

@export var run_manager: RunManager
@export var dog: Node3D
@export var temptation_director: TemptationDirector

## The eased level presentation reads, and the raw target it eases towards.
var level: float = 0.0
var target: float = 0.0
var _notified: float = 0.0


func _ready() -> void:
	if run_manager != null:
		run_manager.run_started.connect(func(_s: int) -> void: _reset())


func _process(delta: float) -> void:
	if run_manager == null or not run_manager.is_running():
		return
	target = compute(_inputs(), DataRegistry.balance)
	level = move_toward(level, target, EASE_RATE * delta)
	if absf(level - _notified) >= NOTIFY_STEP or (level == target and level != _notified):
		_notified = level
		tension_changed.emit(level)


## Pure: the tension a walk's state amounts to (0..1). Nothing before going
## home is possible — before that, staying is not a choice.
static func compute(inputs: Dictionary, balance: GameBalance) -> float:
	if not inputs.get("extraction_open", false):
		return 0.0
	var time := clampf(float(inputs.get("seconds_since_open", 0.0)) / maxf(balance.tension_ramp_seconds, 1.0), 0.0, 1.0)
	var stake := clampf(float(inputs.get("unbanked_value", 0)) / maxf(float(balance.risk_heavy_value), 1.0), 0.0, 1.0)
	var far := clampf(float(inputs.get("distance_home", 0.0)) / maxf(balance.tension_far_distance, 1.0), 0.0, 1.0)
	# Being far from home only matters with something to lose.
	var value := 0.35 * time + 0.45 * stake * (0.6 + 0.4 * far)
	if inputs.get("temptation", false):
		value += 0.1
	if inputs.get("territory_marked", false):
		value += 0.1
	return clampf(value, 0.0, 1.0)


func debug_text() -> String:
	return "Tension: %.2f → %.2f" % [level, target]


func _reset() -> void:
	level = 0.0
	target = 0.0
	_notified = 0.0
	tension_changed.emit(0.0)


func _inputs() -> Dictionary:
	var open := run_manager.is_past_first_extraction()
	return {
		"extraction_open": open,
		"seconds_since_open": run_manager.elapsed_time - run_manager.first_extraction_time if open else 0.0,
		"unbanked_value": run_manager.run_value().unbanked_value,
		"distance_home": _distance_home(),
		"temptation": temptation_director != null and temptation_director.has_offer(),
		"territory_marked": not run_manager.marked_territories.is_empty(),
	}


## Flat distance from the dog to the nearest open exit.
func _distance_home() -> float:
	if dog == null:
		return 0.0
	var best := INF
	for node in get_tree().get_nodes_in_group(ExtractionPoint.GROUP):
		var point := node as ExtractionPoint3D
		if point == null or not point.available:
			continue
		var gap := point.global_position - dog.global_position
		best = minf(best, Vector2(gap.x, gap.z).length())
	return 0.0 if best == INF else best
