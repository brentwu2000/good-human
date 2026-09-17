class_name GoalProgress
extends RefCounted
## Persistent dog desires, flags and discoveries (saved under
## SaveManager.data["dog"]["goals"]). Holds no run state.

enum State { INACTIVE, ACTIVE, COMPLETED, FAILED, DORMANT }
## Collection categories.
const CATEGORIES: Array[StringName] = [&"dogs", &"humans", &"places", &"items", &"events"]

## Desire id -> State.
var states: Dictionary[StringName, State] = {}
var flags: Dictionary[StringName, bool] = {}
## Category -> {id: true}.
var discoveries: Dictionary[StringName, Dictionary] = {}
## Desire id -> completed count.
var completions: Dictionary[StringName, int] = {}
var walks: int = 0
## Primary desire offered on the previous walk (anti-repetition).
var last_primary: StringName


func _init() -> void:
	clear()


func clear() -> void:
	states.clear()
	flags.clear()
	completions.clear()
	discoveries.clear()
	for category in CATEGORIES:
		discoveries[category] = {}
	walks = 0
	last_primary = &""


func state_of(id: StringName) -> State:
	return states.get(id, State.INACTIVE)


func has_flag(flag: StringName) -> bool:
	return flag.is_empty() or flags.has(flag)


func set_flag(flag: StringName) -> void:
	if not flag.is_empty():
		flags[flag] = true


## Returns true when this is a new discovery.
func discover(category: StringName, id: StringName) -> bool:
	if id.is_empty() or not discoveries.has(category) or discoveries[category].has(id):
		return false
	discoveries[category][id] = true
	return true


func is_discovered(category: StringName, id: StringName) -> bool:
	return discoveries.has(category) and discoveries[category].has(id)


func discovered_count(category: StringName) -> int:
	return discoveries.get(category, {}).size()


func ids_in_state(state: State) -> Array[StringName]:
	var ids: Array[StringName] = []
	for id in states:
		if states[id] == state:
			ids.append(id)
	return ids


func serialize() -> Dictionary:
	var state_names: Dictionary = {}
	for id in states:
		state_names[String(id)] = State.keys()[states[id]]
	var discovery_lists: Dictionary = {}
	for category in discoveries:
		var ids: Array[String] = []
		for id: StringName in discoveries[category]:
			ids.append(String(id))
		discovery_lists[String(category)] = ids
	var flag_names: Array[String] = []
	for flag in flags:
		flag_names.append(String(flag))
	var completion_counts: Dictionary = {}
	for id in completions:
		completion_counts[String(id)] = completions[id]
	return {
		"states": state_names,
		"flags": flag_names,
		"discoveries": discovery_lists,
		"completions": completion_counts,
		"walks": walks,
		"last_primary": String(last_primary),
	}


## Tolerates missing or malformed data.
func deserialize(data: Dictionary) -> void:
	clear()
	var raw_states: Variant = data.get("states")
	if raw_states is Dictionary:
		for id: Variant in raw_states:
			var name: Variant = raw_states[id]
			if id is String and name is String and State.has(name):
				states[StringName(id)] = State[name]
	var raw_flags: Variant = data.get("flags")
	if raw_flags is Array:
		for flag: Variant in raw_flags:
			if flag is String:
				flags[StringName(flag)] = true
	var raw_discoveries: Variant = data.get("discoveries")
	if raw_discoveries is Dictionary:
		for category in CATEGORIES:
			var ids: Variant = raw_discoveries.get(String(category))
			if ids is Array:
				for id: Variant in ids:
					if id is String:
						discoveries[category][StringName(id)] = true
	var raw_completions: Variant = data.get("completions")
	if raw_completions is Dictionary:
		for id: Variant in raw_completions:
			var value: Variant = raw_completions[id]
			if id is String and (value is float or value is int):
				completions[StringName(id)] = maxi(int(value), 0)
	var raw_walks: Variant = data.get("walks")
	if raw_walks is float or raw_walks is int:
		walks = maxi(int(raw_walks), 0)
	var raw_last: Variant = data.get("last_primary")
	if raw_last is String:
		last_primary = StringName(raw_last)
