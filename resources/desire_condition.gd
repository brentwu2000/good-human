class_name DesireCondition
extends Resource
## Matches semantic world events (see GoalDirector for the event list).

## e.g. item_found, cue_sniffed, pair_met, fight_won, fight_lost, fight_started,
## brought_home, extracted, squirrel_spotted, squirrel_treed, squirrel_escaped,
## place_visited.
@export var event_type: StringName
## Specific subject (item id, cue id, encounter id...). Empty = any.
@export var subject: StringName
## Only counts when the subject was discovered for the first time.
@export var only_new: bool = false
## Matching events needed.
@export_range(1, 99) var count: int = 1


func matches(type: StringName, event_subject: StringName, is_new: bool) -> bool:
	if type != event_type:
		return false
	if not subject.is_empty() and subject != event_subject:
		return false
	return is_new or not only_new
