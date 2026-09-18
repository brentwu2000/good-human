class_name RunManager
extends Node
## Scene-scoped controller for one walk (NOT an autoload, ADR-001).
## Owns time, seed/RNG, run inventories, searched points, extraction state and
## run-scoped training (TrainingTracker).
## Works with 2D and 3D worlds (P-02): search/extraction points are found by
## group and used through their shared methods, not their node class.

signal run_started(run_seed: int)
signal loot_gained(item: ItemData, quantity: int)
signal loot_blocked(item: ItemData, quantity: int)
## `point` is a SearchPoint or SearchPoint3D.
signal search_empty(point: Node)
## `point` is an ExtractionPoint or ExtractionPoint3D.
signal extraction_unlocked(point: Node)
## What the walk is worth now, split into safe and unbanked (P4-001).
signal value_changed(value: RunValue)
signal run_ended(result: RunResult)

enum RunStatus { NOT_STARTED, RUNNING, EXTRACTED, FAILED }

@export var dog: DogController
## The player dog in any world (DogController or DogController3D). Defaults to `dog`.
@export var dog_actor: Node
@export var auto_start: bool = true
## 0 = generate a new seed each run.
@export var fixed_seed: int = 0
## Hand the result to Game (scene change + stash). Tests turn this off.
@export var report_to_game: bool = true

var elapsed_time: float = 0.0
var run_seed: int = 0
var run_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var human_run_inventory: Inventory
var dog_safe_inventory: Inventory
var searched_points: Dictionary[StringName, bool] = {}
## Territory ids the dog marked on this walk (Sprint 05).
var marked_territories: Dictionary[StringName, bool] = {}
## extraction_id -> available
var extraction_states: Dictionary[StringName, bool] = {}
var run_status: RunStatus = RunStatus.NOT_STARTED
var run_result: RunResult
var training: TrainingTracker
## When going home first became possible (-1 = not yet) and what was at stake
## then, so the walk can tell whether the player chose to stay.
var first_extraction_time: float = -1.0
var value_at_first_extraction: RunValue

var _last_value: RunValue

var _extraction_points: Array[Node] = []
var _all_extractions_forced: bool = false


func _ready() -> void:
	var balance := DataRegistry.balance
	human_run_inventory = Inventory.new(balance.human_run_slots)
	dog_safe_inventory = Inventory.new(balance.dog_safe_slots)
	training = TrainingTracker.new(DataRegistry.training)
	human_run_inventory.changed.connect(_emit_value_changed)
	dog_safe_inventory.changed.connect(_emit_value_changed)
	if dog_actor == null:
		dog_actor = dog
	if dog_actor != null:
		dog_actor.set("interaction_context", self)
		dog_actor.connect(&"interact_requested", _on_dog_interact_requested)
	if auto_start:
		start_run.call_deferred()


func _process(delta: float) -> void:
	if run_status != RunStatus.RUNNING:
		return
	elapsed_time += delta
	_update_extractions()


func start_run(seed_value: int = fixed_seed) -> void:
	if seed_value == 0:
		var seed_source := RandomNumberGenerator.new()
		seed_source.randomize()
		seed_value = seed_source.randi_range(1, 0x7FFFFFFF)
	run_seed = seed_value
	run_rng.seed = run_seed
	elapsed_time = 0.0
	human_run_inventory.clear()
	dog_safe_inventory.clear()
	searched_points.clear()
	marked_territories.clear()
	training.reset()
	run_result = null
	_all_extractions_forced = false
	first_extraction_time = -1.0
	value_at_first_extraction = null
	_last_value = null

	_extraction_points.clear()
	extraction_states.clear()
	for point in get_tree().get_nodes_in_group(ExtractionPoint.GROUP):
		if _belongs_to_run(point):
			_extraction_points.append(point)
			extraction_states[point.extraction_id] = false
			point.set_available(false)

	# Roll every point's loot up front, in a stable order, so it follows the seed.
	var points: Array[Node] = []
	for point in get_tree().get_nodes_in_group(SearchPoint.GROUP):
		if _belongs_to_run(point):
			points.append(point)
	points.sort_custom(func(a: Node, b: Node) -> bool: return String(a.search_id) < String(b.search_id))
	for point in points:
		point.prepare(self)

	run_status = RunStatus.RUNNING
	_update_extractions()
	run_started.emit(run_seed)
	_emit_value_changed()


func is_running() -> bool:
	return run_status == RunStatus.RUNNING


# --- Run value ----------------------------------------------------------------

## What the walk is worth right now: the dog's bag is safe, the owner's is not.
func run_value() -> RunValue:
	return RunValue.of(dog_safe_inventory, human_run_inventory)


## True once the player could have gone home and stayed out anyway.
func is_past_first_extraction() -> bool:
	return first_extraction_time >= 0.0


func _emit_value_changed() -> void:
	var value := run_value()
	if value.equals(_last_value):
		return
	_last_value = value
	value_changed.emit(value)


# --- Search -----------------------------------------------------------------

func is_searched(search_id: StringName) -> bool:
	return searched_points.has(search_id)


## Called by SearchPoint when its search completes. `stack` is the rolled
## (or still pending) loot. Returns what is left over because the bag is full,
## or null when the point is finished.
func resolve_search(point: Node, stack: ItemStack) -> ItemStack:
	if not is_running():
		return stack
	if stack == null:
		searched_points[point.search_id] = true
		search_empty.emit(point)
		return null

	var left := human_run_inventory.add_item(stack.item, stack.quantity)
	var added := stack.quantity - left
	if added > 0:
		loot_gained.emit(stack.item, added)
	if left == 0:
		searched_points[point.search_id] = true
		return null
	loot_blocked.emit(stack.item, left)
	return ItemStack.new(stack.item, left)


# --- Training -----------------------------------------------------------------

## World observers report meaningful moments here; returns the accepted amount.
func record_training(data: TrainingEventData, key: StringName = &"", source: String = "", context: Dictionary = {}, scale: float = 1.0) -> float:
	if not is_running() or data == null:
		return 0.0
	return training.record(TrainingEvent.new(data, key, elapsed_time, source, context, scale))


## The dog left its own scent on a place. Recorded, not resolved: a mark only
## becomes claim progress if this walk gets home (P4-010).
func record_territory_mark(territory_id: StringName) -> void:
	if is_running() and not territory_id.is_empty():
		marked_territories[territory_id] = true


# --- Combat outcomes -------------------------------------------------------------

## Victory reward: one roll with the run RNG into the human bag. Whatever does
## not fit is left behind. Returns the rolled stack (null = nothing).
func grant_reward(table: LootTableData) -> ItemStack:
	if not is_running() or table == null:
		return null
	var stack := table.roll(run_rng)
	if stack == null:
		return null
	var left := human_run_inventory.add_item(stack.item, stack.quantity)
	if stack.quantity - left > 0:
		loot_gained.emit(stack.item, stack.quantity - left)
	if left > 0:
		loot_blocked.emit(stack.item, left)
	return stack


# --- Extraction ---------------------------------------------------------------

func is_extraction_available(extraction_id: StringName) -> bool:
	return is_running() and extraction_states.get(extraction_id, false)


func extract(extraction_id: StringName) -> void:
	if not is_running():
		return
	run_status = RunStatus.EXTRACTED
	var result := _build_result(RunResult.Outcome.EXTRACTED, extraction_id)
	result.to_stash = human_run_inventory.get_stacks()
	result.to_stash.append_array(dog_safe_inventory.get_stacks())
	_end_run(result)


## Run failure: unprotected human inventory is lost; Dog Safe Inventory is kept.
func fail_run() -> void:
	_lose_run(RunResult.Outcome.FAILED, "")


## The player's human was knocked out: same loss rules as a failed run, plus
## the hospital result. Permanent progression (stash, save) is untouched.
func defeat_run(defeated_by: String) -> void:
	_lose_run(RunResult.Outcome.DEFEATED, defeated_by)


func _lose_run(outcome: RunResult.Outcome, defeated_by: String) -> void:
	if not is_running():
		return
	run_status = RunStatus.FAILED
	var result := _build_result(outcome, &"")
	result.defeated_by = defeated_by
	result.to_stash = dog_safe_inventory.get_stacks()
	result.lost = human_run_inventory.get_stacks()
	result.lost_value = result.unbanked_value
	_end_run(result)


func _update_extractions() -> void:
	for point in _extraction_points:
		if not is_instance_valid(point) or extraction_states.get(point.extraction_id, false):
			continue
		if _all_extractions_forced or elapsed_time >= point.unlock_time:
			extraction_states[point.extraction_id] = true
			point.set_available(true)
			if first_extraction_time < 0.0:
				first_extraction_time = elapsed_time
				value_at_first_extraction = run_value()
			extraction_unlocked.emit(point)


func _build_result(outcome: RunResult.Outcome, extraction_id: StringName) -> RunResult:
	var result := RunResult.new()
	result.outcome = outcome
	result.run_seed = run_seed
	result.elapsed_time = elapsed_time
	result.extraction_id = extraction_id
	result.training = RunTrainingSummary.from_tracker(training, outcome)
	var value := run_value()
	result.safe_value = value.safe_value
	result.unbanked_value = value.unbanked_value
	result.marked_territories.assign(marked_territories.keys())
	result.first_extraction_time = first_extraction_time
	result.value_at_first_extraction = value_at_first_extraction.total() if value_at_first_extraction != null else 0
	return result


func _end_run(result: RunResult) -> void:
	run_result = result
	run_ended.emit(result)
	if report_to_game:
		Game.finish_run(result)


## `target` is an Interactable or Interactable3D.
func _on_dog_interact_requested(target: Node) -> void:
	if is_running() and target != null and target.can_interact(self):
		target.interact(self)


## Only extraction points from this run's scene (all of them when built in code).
func _belongs_to_run(node: Node) -> bool:
	return owner == null or owner.is_ancestor_of(node)


# --- Debug (used only by the Debug Panel) -----------------------------------

func debug_add_time(seconds: float) -> void:
	debug_set_time(elapsed_time + seconds)


func debug_set_time(seconds: float) -> void:
	if not is_running():
		return
	elapsed_time = maxf(seconds, 0.0)
	_update_extractions()


## Jumps to `seconds` before the next extraction unlock.
func debug_skip_to_next_unlock(seconds: float = 10.0) -> void:
	var next := INF
	for point in _extraction_points:
		if is_instance_valid(point) and not extraction_states.get(point.extraction_id, false):
			next = minf(next, point.unlock_time)
	if next < INF:
		debug_set_time(maxf(next - seconds, elapsed_time))


func debug_unlock_all_extractions() -> void:
	_all_extractions_forced = true
	_update_extractions()


## Returns the amount that did not fit.
func debug_give_item(item_id: StringName, quantity: int = 1) -> int:
	var item := DataRegistry.get_item(item_id)
	if item == null:
		push_warning("RunManager: unknown debug item %s" % item_id)
		return quantity
	var left := human_run_inventory.add_item(item, quantity)
	if quantity - left > 0:
		loot_gained.emit(item, quantity - left)
	return left
