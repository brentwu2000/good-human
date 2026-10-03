class_name TerritoryProgress
extends RefCounted
## Sprint 05 (P4-005): what the dog remembers about the places it keeps going
## back to. Saved under SaveManager.data["dog"]["territories"]; holds no run
## state and knows nothing about the world scene.
##
## The states are a relationship, not a capture meter (ADR-012):
## UNKNOWN    — never been there.
## DISCOVERED — found the place, but not yet what it means.
## CONTESTED  — smelled the resident; this belongs to another dog.
## CLAIMING   — the dog has marked it and is coming back.
## OWNED      — it is the dog's place now.
##
## Progress only ever moves forward on a successful extraction, so a place is
## earned by walks that came home, not by time spent standing next to a tree.

enum State { UNKNOWN, DISCOVERED, CONTESTED, CLAIMING, OWNED }

## Territory id -> State.
var states: Dictionary[StringName, State] = {}
## Territory id -> relevant successful extractions so far.
var claims: Dictionary[StringName, int] = {}
## Territory id -> short note on the last thing that happened there.
var last_events: Dictionary[StringName, String] = {}
## S05-07: the persistent rival — encounter id -> {"wins": int, "losses": int,
## "last": int}. Wins/losses are the dog's side; "last" is RivalOutcome. It is
## memory only: it never changes how strong anyone is.
var rivals: Dictionary[StringName, Dictionary] = {}

enum RivalOutcome { NONE, DOG_WON, DOG_LOST }

## S05-11: territory id -> true once its ownership reward has been found.
var rewards_given: Dictionary[StringName, bool] = {}


func clear() -> void:
	states.clear()
	claims.clear()
	last_events.clear()
	rivals.clear()
	rewards_given.clear()


func state_of(id: StringName) -> State:
	return states.get(id, State.UNKNOWN)


func claim_progress(id: StringName) -> int:
	return claims.get(id, 0)


func last_event(id: StringName) -> String:
	return last_events.get(id, "")


func is_owned(id: StringName) -> bool:
	return state_of(id) == State.OWNED


## Moves a place forward only; a walk can never make the dog forget somewhere.
func advance_to(id: StringName, state: State) -> bool:
	if state <= state_of(id):
		return false
	states[id] = state
	return true


func note_event(id: StringName, text: String) -> void:
	last_events[id] = text


## One relevant successful extraction. Returns true when that completes the
## claim, which is the only way a place becomes OWNED.
func add_claim(id: StringName, target: int) -> bool:
	if is_owned(id):
		return false
	claims[id] = claim_progress(id) + 1
	if claims[id] < maxi(target, 1):
		advance_to(id, State.CLAIMING)
		return false
	states[id] = State.OWNED
	return true


## S05-07: a fight with a persistent rival ended (won or lost; a broken-off
## fight is not remembered as either).
func record_rival_fight(encounter_id: StringName, dog_won: bool) -> void:
	var record := rival_record(encounter_id)
	if dog_won:
		record["wins"] = int(record["wins"]) + 1
	else:
		record["losses"] = int(record["losses"]) + 1
	record["last"] = RivalOutcome.DOG_WON if dog_won else RivalOutcome.DOG_LOST
	rivals[encounter_id] = record


func rival_record(encounter_id: StringName) -> Dictionary:
	var record: Dictionary = rivals.get(encounter_id, {})
	return {"wins": int(record.get("wins", 0)), "losses": int(record.get("losses", 0)), "last": int(record.get("last", RivalOutcome.NONE))}


func last_rival_outcome(encounter_id: StringName) -> RivalOutcome:
	return rival_record(encounter_id)["last"] as RivalOutcome


func is_reward_given(id: StringName) -> bool:
	return rewards_given.get(id, false)


func mark_reward_given(id: StringName) -> void:
	rewards_given[id] = true


func serialize() -> Dictionary:
	var state_names: Dictionary = {}
	for id in states:
		state_names[String(id)] = int(states[id])
	var claim_counts: Dictionary = {}
	for id in claims:
		claim_counts[String(id)] = claims[id]
	var events: Dictionary = {}
	for id in last_events:
		events[String(id)] = last_events[id]
	var rival_records: Dictionary = {}
	for id in rivals:
		rival_records[String(id)] = rival_record(id)
	var given: Array[String] = []
	for id in rewards_given:
		given.append(String(id))
	return {"states": state_names, "claims": claim_counts, "last_events": events, "rivals": rival_records, "rewards_given": given}


func deserialize(data: Dictionary) -> void:
	clear()
	var raw_states: Variant = data.get("states")
	if raw_states is Dictionary:
		for key: Variant in raw_states:
			var value := int(raw_states[key])
			if value >= State.UNKNOWN and value <= State.OWNED:
				states[StringName(str(key))] = value as State
	var raw_claims: Variant = data.get("claims")
	if raw_claims is Dictionary:
		for key: Variant in raw_claims:
			claims[StringName(str(key))] = maxi(int(raw_claims[key]), 0)
	var raw_events: Variant = data.get("last_events")
	if raw_events is Dictionary:
		for key: Variant in raw_events:
			last_events[StringName(str(key))] = str(raw_events[key])
	var raw_given: Variant = data.get("rewards_given")
	if raw_given is Array:
		for key: Variant in raw_given:
			rewards_given[StringName(str(key))] = true
	# Saves from before S05-07 have no rivals: nobody has been fought yet.
	var raw_rivals: Variant = data.get("rivals")
	if raw_rivals is Dictionary:
		for key: Variant in raw_rivals:
			var raw: Variant = raw_rivals[key]
			if not raw is Dictionary:
				continue
			var last := int(raw.get("last", RivalOutcome.NONE))
			rivals[StringName(str(key))] = {
				"wins": maxi(int(raw.get("wins", 0)), 0),
				"losses": maxi(int(raw.get("losses", 0)), 0),
				"last": last if last >= RivalOutcome.NONE and last <= RivalOutcome.DOG_LOST else RivalOutcome.NONE,
			}
