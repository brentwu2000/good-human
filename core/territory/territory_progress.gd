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


func clear() -> void:
	states.clear()
	claims.clear()
	last_events.clear()


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
	return {"states": state_names, "claims": claim_counts, "last_events": events}


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
