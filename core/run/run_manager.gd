class_name RunManager
extends Node
## Scene-scoped controller for one walk (NOT an autoload, ADR-002).
## Owns time, seed/RNG, run inventories, searched points and extraction state.

signal run_started(run_seed: int)
signal loot_gained(item: ItemData, quantity: int)
signal loot_blocked(item: ItemData, quantity: int)
signal search_empty(point: SearchPoint)
signal extraction_unlocked(point: ExtractionPoint)
signal run_ended(result: RunResult)

enum RunStatus { NOT_STARTED, RUNNING, EXTRACTED, FAILED }

@export var dog: DogController
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
## extraction_id -> available
var extraction_states: Dictionary[StringName, bool] = {}
var run_status: RunStatus = RunStatus.NOT_STARTED
var run_result: RunResult

var _extraction_points: Array[ExtractionPoint] = []
var _all_extractions_forced: bool = false


func _ready() -> void:
	var balance := DataRegistry.balance
	human_run_inventory = Inventory.new(balance.human_run_slots)
	dog_safe_inventory = Inventory.new(balance.dog_safe_slots)
	if dog != null:
		dog.interaction_context = self
		dog.interact_requested.connect(_on_dog_interact_requested)
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
	run_result = null
	_all_extractions_forced = false

	_extraction_points.clear()
	extraction_states.clear()
	for node in get_tree().get_nodes_in_group(ExtractionPoint.GROUP):
		var point := node as ExtractionPoint
		if point != null and _belongs_to_run(point):
			_extraction_points.append(point)
			extraction_states[point.extraction_id] = false
			point.set_available(false)

	# Roll every point's loot up front, in a stable order, so it follows the seed.
	var points: Array[SearchPoint] = []
	for node in get_tree().get_nodes_in_group(SearchPoint.GROUP):
		var point := node as SearchPoint
		if point != null and _belongs_to_run(point):
			points.append(point)
	points.sort_custom(func(a: SearchPoint, b: SearchPoint) -> bool: return String(a.search_id) < String(b.search_id))
	for point in points:
		point.prepare(self)

	run_status = RunStatus.RUNNING
	_update_extractions()
	run_started.emit(run_seed)


func is_running() -> bool:
	return run_status == RunStatus.RUNNING


# --- Search -----------------------------------------------------------------

func is_searched(search_id: StringName) -> bool:
	return searched_points.has(search_id)


## Called by SearchPoint when its search completes. `stack` is the rolled
## (or still pending) loot. Returns what is left over because the bag is full,
## or null when the point is finished.
func resolve_search(point: SearchPoint, stack: ItemStack) -> ItemStack:
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
	if not is_running():
		return
	run_status = RunStatus.FAILED
	var result := _build_result(RunResult.Outcome.FAILED, &"")
	result.to_stash = dog_safe_inventory.get_stacks()
	result.lost = human_run_inventory.get_stacks()
	_end_run(result)


func _update_extractions() -> void:
	for point in _extraction_points:
		if not is_instance_valid(point) or extraction_states.get(point.extraction_id, false):
			continue
		if _all_extractions_forced or elapsed_time >= point.unlock_time:
			extraction_states[point.extraction_id] = true
			point.set_available(true)
			extraction_unlocked.emit(point)


func _build_result(outcome: RunResult.Outcome, extraction_id: StringName) -> RunResult:
	var result := RunResult.new()
	result.outcome = outcome
	result.run_seed = run_seed
	result.elapsed_time = elapsed_time
	result.extraction_id = extraction_id
	return result


func _end_run(result: RunResult) -> void:
	run_result = result
	run_ended.emit(result)
	if report_to_game:
		Game.finish_run(result)


func _on_dog_interact_requested(target: Interactable) -> void:
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
