class_name TemptationData
extends Resource
## Sprint 05 (P4-004): one reason to stay out after the player could have gone
## home. A temptation never changes the rules of a walk — it notices something
## that is already there and says so in the dog's voice, so that staying is the
## player's own choice (ADR-013: greed is voluntary).
##
## Deliberately not a quest and not a Desire: a Desire is what the dog wants,
## a temptation is what the world happens to be offering at the moment going
## home became possible.

## What the world must actually be offering. The director owns the world
## knowledge; the template only says which question to ask.
enum Needs {
	NOTHING,
	UNSNIFFED_CUE,      ## a scent cue the dog has not followed yet
	PRESENT_PAIR,       ## a pair standing around, provokable
	UNSEARCHED_POINT,   ## somewhere still worth a sniff, with room in the bag
	SQUIRREL,           ## a squirrel about
	TERRITORY,          ## an unclaimed or contested territory (P4-005)
}

@export var id: StringName
## What the dog notices, in its own voice.
@export_multiline var dog_text: String
## Short note on where it seems to be (optional).
@export var world_hint: String

@export_group("Rules")
@export var needs: Needs = Needs.NOTHING
@export var weight: float = 1.0
## Seconds before this one may be offered again in the same walk.
@export var cooldown: float = 90.0
## The offer stops standing this long after it is made.
@export var expiry: float = 45.0
## Only worth offering when the owner is carrying at least this much: with
## nothing at stake, staying on is not a decision.
@export var min_unbanked_value: int = 0
## Progress flags (Game.goal_progress) required, and ones that retire it.
@export var requires_flags: Array[StringName] = []
@export var blocked_by_flags: Array[StringName] = []
## Desire thread this belongs to, so a temptation can speak for an unresolved
## thread instead of inventing a new errand (optional).
@export var related_desire: StringName


func is_allowed(unbanked_value: int, flags: Dictionary) -> bool:
	if unbanked_value < min_unbanked_value:
		return false
	for flag in requires_flags:
		if not flags.has(flag):
			return false
	for flag in blocked_by_flags:
		if flags.has(flag):
			return false
	return true
