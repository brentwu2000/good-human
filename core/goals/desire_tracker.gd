class_name DesireTracker
extends RefCounted
## Walk-scoped desire logic on top of persistent GoalProgress: picks the
## walk's primary desire, reacts to semantic events (emergent triggers,
## completion, failure, chaining) and settles threads when the walk ends.
## Pure logic: no nodes, so it can be tested headless.

signal desire_started(desire: DesireData, reason: StringName)
signal desire_completed(desire: DesireData)
signal desire_failed(desire: DesireData)

## Emergent desires active at once.
const MAX_EMERGENT: int = 2
## Score bonus for an unresolved thread from an earlier walk.
const THREAD_BONUS: int = 100
## Score penalty for offering the same primary twice in a row.
const REPEAT_PENALTY: int = 30

var progress: GoalProgress
var library: Dictionary[StringName, DesireData] = {}
## Active this walk, in start order.
var active: Array[DesireData] = []
var primary: DesireData
## Human perks unlocked (growth context).
var human_perks: int = 0
## category -> undiscovered entries still available on this map.
var undiscovered: Dictionary[StringName, int] = {}

var _emergent_active: int = 0
var _counts: Dictionary[String, int] = {}


func _init(goal_progress: GoalProgress, desires: Array[DesireData]) -> void:
	progress = goal_progress
	for desire in desires:
		if desire != null:
			library[desire.id] = desire


func get_desire(id: StringName) -> DesireData:
	return library.get(id)


func is_active(id: StringName) -> bool:
	return active.any(func(d: DesireData) -> bool: return d.id == id)


# --- Walk lifecycle -------------------------------------------------------------

## Chooses and activates the primary desire. `rng` is the run RNG.
func begin_walk(rng: RandomNumberGenerator) -> DesireData:
	active.clear()
	_counts.clear()
	_emergent_active = 0
	primary = null
	var best_score := -INF
	for id in _sorted_ids():
		var desire := library[id]
		if desire.layer == DesireData.Layer.EMERGENT or not _can_offer(desire):
			continue
		var score := float(desire.priority) + rng.randf_range(0.0, 5.0)
		if progress.state_of(id) == GoalProgress.State.DORMANT:
			score += THREAD_BONUS
		if id == progress.last_primary:
			score -= REPEAT_PENALTY
		if score > best_score:
			best_score = score
			primary = desire
	if primary != null:
		progress.last_primary = primary.id
		_activate(primary, &"primary")
	return primary


## Unresolved persistent desires sleep until a later walk; the rest are dropped
## (desires can always be ignored).
func end_walk() -> void:
	for desire in active:
		if desire.persistent:
			progress.states[desire.id] = GoalProgress.State.DORMANT
		elif progress.state_of(desire.id) == GoalProgress.State.ACTIVE:
			progress.states[desire.id] = GoalProgress.State.INACTIVE
	active.clear()
	progress.walks += 1


# --- Events ----------------------------------------------------------------------

func handle_event(type: StringName, subject: StringName, is_new: bool = false) -> void:
	for desire in active.duplicate():
		if not active.has(desire):
			continue
		if desire.completion != null and _counted(desire, &"done", desire.completion, type, subject, is_new):
			complete(desire)
		elif desire.failure != null and _counted(desire, &"fail", desire.failure, type, subject, is_new):
			fail(desire)
	if _emergent_active >= MAX_EMERGENT:
		return
	for id in _sorted_ids():
		var desire := library[id]
		if desire.layer != DesireData.Layer.EMERGENT or desire.trigger == null or is_active(id):
			continue
		if not desire.trigger.matches(type, subject, is_new) or not _can_offer(desire):
			continue
		_emergent_active += 1
		_activate(desire, &"emergent")
		if _emergent_active >= MAX_EMERGENT:
			return


func complete(desire: DesireData) -> void:
	_close(desire, GoalProgress.State.COMPLETED)
	progress.completions[desire.id] = progress.completions.get(desire.id, 0) + 1
	for flag in desire.sets_flags:
		progress.set_flag(flag)
	desire_completed.emit(desire)
	_chain(desire.next_on_complete)


func fail(desire: DesireData) -> void:
	_close(desire, GoalProgress.State.FAILED)
	for flag in desire.fail_sets_flags:
		progress.set_flag(flag)
	desire_failed.emit(desire)
	_chain(desire.next_on_fail)


# --- Helpers ---------------------------------------------------------------------

func _can_offer(desire: DesireData) -> bool:
	var state := progress.state_of(desire.id)
	if state == GoalProgress.State.ACTIVE:
		return false
	if state == GoalProgress.State.COMPLETED and not desire.repeatable:
		return false
	# Threads only exist once a chain reaches them.
	if desire.layer == DesireData.Layer.THREAD and state != GoalProgress.State.DORMANT:
		return false
	for flag in desire.requires_flags:
		if not progress.has_flag(flag):
			return false
	for flag in desire.blocked_by_flags:
		if progress.has_flag(flag):
			return false
	if human_perks < desire.min_human_perks:
		return false
	if not desire.needs_undiscovered.is_empty() and undiscovered.get(desire.needs_undiscovered, 0) <= 0:
		return false
	return true


func _activate(desire: DesireData, reason: StringName) -> void:
	active.append(desire)
	progress.states[desire.id] = GoalProgress.State.ACTIVE
	desire_started.emit(desire, reason)


func _close(desire: DesireData, state: GoalProgress.State) -> void:
	active.erase(desire)
	progress.states[desire.id] = state
	if desire.layer == DesireData.Layer.EMERGENT:
		_emergent_active = maxi(_emergent_active - 1, 0)


## Follow-ups start right away in the same walk.
func _chain(ids: Array[StringName]) -> void:
	for id in ids:
		var next := get_desire(id)
		if next == null or is_active(id):
			continue
		var state := progress.state_of(id)
		if state == GoalProgress.State.COMPLETED and not next.repeatable:
			continue
		var blocked := next.requires_flags.any(func(f: StringName) -> bool: return not progress.has_flag(f))
		if blocked or human_perks < next.min_human_perks:
			# Not ready yet (e.g. the human must grow first): wait as a thread.
			progress.states[id] = GoalProgress.State.DORMANT
			continue
		_activate(next, &"follow_up")


func _counted(desire: DesireData, slot: StringName, condition: DesireCondition, type: StringName, subject: StringName, is_new: bool) -> bool:
	if not condition.matches(type, subject, is_new):
		return false
	var key := "%s|%s" % [desire.id, slot]
	_counts[key] = _counts.get(key, 0) + 1
	return _counts[key] >= condition.count


func _sorted_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(library.keys())
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return ids
