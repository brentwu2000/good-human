class_name Memories
extends RefCounted
## Sprint 06 (S06-10): the pair's meaningful moments, kept on the pair as small
## records (SPRINT06_IDENTITY_SCHEMA MemoryData: id, category, run_index,
## participants, place_id, event_id, presentation_key, importance) and brought
## back later: by the human when the walk passes the place or meets the pair
## it was about, and at Home as one quiet photo. Never a scrapbook to fill.


## Adds a memory of `kind` about `subject`, once. Returns it, or {} if it was
## already remembered or the kind is unknown.
static func remember(pair: PairState, kind_id: StringName, subject: StringName, run_index: int, values: Dictionary = {}, place_id: StringName = &"") -> Dictionary:
	var kind := DataRegistry.get_memory_kind(kind_id)
	if pair == null or kind == null:
		return {}
	var id := "%s:%s" % [kind_id, subject]
	for memory in pair.memories:
		if memory.get("id") == id:
			return {}
	var fill := values.duplicate()
	fill["name"] = pair.human_custom_name
	var memory := {
		"id": id,
		"kind": String(kind_id),
		"category": int(kind.category),
		"run_index": run_index,
		"participants": [String(pair.dog.id) if pair.dog != null else "", pair.human_custom_name],
		"place_id": String(place_id),
		"event_id": String(subject),
		"presentation_key": String(kind_id),
		"importance": kind.importance,
		"text": kind.text.format(fill),
		"recall": kind.recall_line.format(fill),
	}
	pair.memories.append(memory)
	return memory


## Everything one finished walk is worth remembering. `run_index` counts
## walks (statistics.runs after this one).
static func apply_walk(pair: PairState, result: RunResult, run_index: int) -> Array[Dictionary]:
	var added: Array[Dictionary] = []
	if result.is_success():
		added.append(remember(pair, &"first_home", &"home", run_index))
	if result.outcome == RunResult.Outcome.DEFEATED and not result.lost_to.is_empty():
		added.append(remember(pair, &"first_defeat", result.lost_to, run_index, {"who": result.defeated_by}))
	for encounter_id in result.won_against:
		var encounter := _encounter(encounter_id)
		if encounter != null and encounter.tier != EncounterData.Tier.ORDINARY:
			added.append(remember(pair, &"won_against", encounter_id, run_index, {"who": encounter.human.display_name, "dog": encounter.dog_name}))
	for territory_id in result.territories_claimed:
		var territory := DataRegistry.get_territory(territory_id)
		if territory != null:
			added.append(remember(pair, &"place_claimed", territory_id, run_index, {"place": territory.display_name}, territory_id))
	if result.training != null:
		for perk in result.training.new_perks:
			added.append(remember(pair, &"human_changed", perk.id, run_index, {"what": perk.display_name}))
	for habit_id in result.habits_formed:
		var habit := DataRegistry.get_habit(habit_id)
		if habit != null:
			added.append(remember(pair, &"habit_formed", habit_id, run_index, {"what": habit.home_text}))
	if result.is_success():
		for stack in result.to_stash:
			if stack.item.rarity == ItemData.Rarity.RARE:
				added.append(remember(pair, &"rare_find", stack.item.id, run_index, {"what": stack.item.display_name}))
	return added.filter(func(m: Dictionary) -> bool: return not m.is_empty())


## A memory about this pair or place that the human can bring back, or {}.
static func recall_for(pair: PairState, subject: StringName) -> Dictionary:
	if pair == null:
		return {}
	for i in range(pair.memories.size() - 1, -1, -1):
		var memory: Dictionary = pair.memories[i]
		if memory.get("event_id") == String(subject) and not str(memory.get("recall", "")).is_empty():
			return memory
	return {}


## The photo at Home: the most recent of the most important.
static func featured(pair: PairState) -> Dictionary:
	if pair == null or pair.memories.is_empty():
		return {}
	var best: Dictionary = pair.memories[0]
	for memory in pair.memories:
		if int(memory.get("importance", 1)) >= int(best.get("importance", 1)):
			best = memory
	return best


static func _encounter(id: StringName) -> EncounterData:
	var path := "res://data/encounters/%s.tres" % id
	return load(path) as EncounterData if ResourceLoader.exists(path) else null
