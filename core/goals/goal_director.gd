class_name GoalDirector
extends Node
## Scene-scoped bridge between the Run World and the dog's desires (ADR-009).
## Turns what already happens on a walk into semantic goal events, feeds the
## DesireTracker and shows world cues. It observes WALK / FIGHT / TRAIN and
## never changes their rules; rewards go through RunManager.
##
## Events: item_found, brought_home, extracted, pair_met, fight_started,
## fight_won, fight_lost, disengaged, cue_sniffed, squirrel_spotted,
## squirrel_treed, squirrel_escaped, place_visited.
## Works in 2D and 3D: cues, squirrels, places and pairs are found by group and
## used through shared methods; distances are in meters.

signal desire_started(desire: DesireData, reason: StringName)
signal desire_completed(desire: DesireData)
signal desire_failed(desire: DesireData)
signal discovered(category: StringName, id: StringName)

## The dog counts as meeting a pair this close (meters).
const MEET_DISTANCE: float = 2.75

@export var run_manager: RunManager
## CombatCoordinator or CombatCoordinator3D.
@export var coordinator: Node
## World units per meter: 80 on the 2D map (pixels), 1 in 3D.
@export var units_per_meter: float = 80.0

var tracker: DesireTracker

var _met_pairs: Dictionary[StringName, bool] = {}
var _visited_places: Dictionary[StringName, bool] = {}


func _ready() -> void:
	tracker = DesireTracker.new(Game.goal_progress, DataRegistry.goals.desires)
	tracker.desire_started.connect(_on_desire_started)
	tracker.desire_completed.connect(_on_desire_completed)
	tracker.desire_failed.connect(_on_desire_failed)
	run_manager.run_started.connect(_on_run_started)
	run_manager.run_ended.connect(_on_run_ended)
	run_manager.loot_gained.connect(_on_loot_gained)
	coordinator.engagement_started.connect(_on_engagement_started)
	coordinator.engagement_ended.connect(_on_engagement_ended)
	for cue in _in_run(ScentCue.GROUP):
		cue.connect(&"sniffed", func(c: Node) -> void: send(&"cue_sniffed", c.cue_id))
	for squirrel in _in_run(Squirrel.GROUP):
		squirrel.connect(&"spotted", func(s: Node) -> void: send(&"squirrel_spotted", s.squirrel_id))
		squirrel.connect(&"treed", func(s: Node) -> void: send(&"squirrel_treed", s.squirrel_id))
		squirrel.connect(&"escaped", func(s: Node) -> void: send(&"squirrel_escaped", s.squirrel_id))


## Reports one semantic event to the tracker.
func send(type: StringName, subject: StringName, is_new: bool = false) -> void:
	if not run_manager.is_running():
		return
	tracker.handle_event(type, subject, is_new)
	_refresh_cues()


func active_desires() -> Array[DesireData]:
	return tracker.active


# --- Walk lifecycle ---------------------------------------------------------------

func _on_run_started(_seed: int) -> void:
	_met_pairs.clear()
	_visited_places.clear()
	for pair in coordinator.get_pairs():
		pair.refresh_presence()
	for squirrel in _in_run(Squirrel.GROUP):
		squirrel.prepare(run_manager.dog_actor, run_manager.run_rng)
	tracker.human_perks = Game.human_growth.perks.size()
	tracker.undiscovered = _undiscovered_counts()
	tracker.begin_walk(run_manager.run_rng)
	_refresh_cues()


func _on_run_ended(result: RunResult) -> void:
	if result.outcome == RunResult.Outcome.EXTRACTED:
		tracker.handle_event(&"extracted", result.extraction_id)
	for stack in result.to_stash:
		tracker.handle_event(&"brought_home", stack.item_id)
	tracker.end_walk()


# --- World observation --------------------------------------------------------------

func _physics_process(_delta: float) -> void:
	if not run_manager.is_running() or run_manager.dog_actor == null:
		return
	var dog_position: Variant = run_manager.dog_actor.global_position
	for pair in coordinator.get_pairs():
		if not pair.is_present() or _met_pairs.has(pair.spot_id):
			continue
		if dog_position.distance_to(pair.human_global_position()) <= MEET_DISTANCE * units_per_meter:
			_met_pairs[pair.spot_id] = true
			var is_new := _discover(&"dogs", pair.encounter.id)
			_discover(&"humans", pair.encounter.human.id)
			send(&"pair_met", pair.encounter.id, is_new)
	for place in _in_run(PlaceMarker.GROUP):
		if _visited_places.has(place.place_id) or dog_position.distance_to(place.global_position) > place.radius:
			continue
		_visited_places[place.place_id] = true
		send(&"place_visited", place.place_id, _discover(&"places", place.place_id))


func _on_loot_gained(item: ItemData, _quantity: int) -> void:
	send(&"item_found", item.id, _discover(&"items", item.id))


## `engagement` is an Engagement or Engagement3D.
func _on_engagement_started(engagement: RefCounted) -> void:
	send(&"fight_started", engagement.pair.encounter.id)


func _on_engagement_ended(engagement: RefCounted, result: CombatSimulation.Result) -> void:
	var id: StringName = engagement.pair.encounter.id
	match result:
		CombatSimulation.Result.VICTORY:
			send(&"fight_won", id)
		CombatSimulation.Result.DEFEAT:
			send(&"fight_lost", id)
		_:
			send(&"disengaged", id)


# --- Desire outcomes ------------------------------------------------------------------

func _on_desire_started(desire: DesireData, reason: StringName) -> void:
	desire_started.emit(desire, reason)


func _on_desire_completed(desire: DesireData) -> void:
	if desire.reward_table != null and run_manager.is_running():
		run_manager.grant_reward(desire.reward_table)
	_discover(&"events", desire.id)
	# Discovered content (e.g. a rival) can appear right away.
	for pair in coordinator.get_pairs():
		pair.refresh_presence()
	desire_completed.emit(desire)
	_refresh_cues()


func _on_desire_failed(desire: DesireData) -> void:
	desire_failed.emit(desire)
	_refresh_cues()


func _discover(category: StringName, id: StringName) -> bool:
	var is_new := Game.goal_progress.discover(category, id)
	if is_new:
		discovered.emit(category, id)
	return is_new


## Undiscovered things this map still offers.
func _undiscovered_counts() -> Dictionary[StringName, int]:
	var counts: Dictionary[StringName, int] = {&"dogs": 0, &"places": 0}
	var progress := Game.goal_progress
	for pair in coordinator.get_pairs():
		if pair.is_present() and not progress.is_discovered(&"dogs", pair.encounter.id):
			counts[&"dogs"] += 1
	for place in _in_run(PlaceMarker.GROUP):
		if not progress.is_discovered(&"places", place.place_id):
			counts[&"places"] += 1
	return counts


# --- World cues ---------------------------------------------------------------------

## Scent cues and pairs light up while a desire points at them.
func _refresh_cues() -> void:
	var targets: Dictionary[StringName, bool] = {}
	for desire in tracker.active:
		if not desire.hint_target.is_empty():
			targets[desire.hint_target] = true
	for cue in _in_run(ScentCue.GROUP):
		cue.set_active(targets.has(cue.cue_id))
	for pair in coordinator.get_pairs():
		if pair.is_present():
			pair.set_hinted(targets.has(pair.encounter.id) and not pair.is_beaten())


## Closest thing an active desire points at (for the HUD arrow), or null.
## `from` and the result are Vector2 in 2D, Vector3 in 3D.
func hint_position(from: Variant) -> Variant:
	var best: Variant = null
	for desire in tracker.active:
		var target := desire.hint_target
		if target.is_empty():
			continue
		for cue in _in_run(ScentCue.GROUP):
			if cue.cue_id == target and cue.active:
				best = _closer(from, best, cue.global_position)
		for pair in coordinator.get_pairs():
			if pair.is_present() and pair.encounter.id == target:
				best = _closer(from, best, pair.human_global_position())
		for squirrel in _in_run(Squirrel.GROUP):
			if squirrel.squirrel_id == target and squirrel.visible:
				best = _closer(from, best, squirrel.global_position)
	return best


func _closer(from: Variant, current: Variant, candidate: Variant) -> Variant:
	if current == null or from.distance_to(candidate) < from.distance_to(current):
		return candidate
	return current


## Nodes of a group that belong to this run's scene.
func _in_run(group: StringName) -> Array[Node]:
	var nodes: Array[Node] = []
	for node in get_tree().get_nodes_in_group(group):
		if owner == null or owner.is_ancestor_of(node):
			nodes.append(node)
	return nodes


# --- Debug ----------------------------------------------------------------------------

func debug_complete_first() -> void:
	if not tracker.active.is_empty():
		tracker.complete(tracker.active[0])


func debug_reset_goals() -> void:
	Game.goal_progress.clear()
	SaveManager.data["dog"]["goals"] = Game.goal_progress.serialize()
	SaveManager.save_game()
