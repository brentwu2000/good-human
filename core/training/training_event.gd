class_name TrainingEvent
extends RefCounted
## One occurrence of a TrainingEventData during a run.

var data: TrainingEventData
## Cooldown / uniqueness key (e.g. a pair's spot id). Empty = global.
var key: StringName
var source: String
var context: Dictionary
var run_time: float
## Magnitude multiplier from context (e.g. a tougher opponent).
var scale: float = 1.0
## Amount the tracker actually accepted.
var accepted: float = 0.0


func _init(event_data: TrainingEventData, event_key: StringName = &"", time: float = 0.0, event_source: String = "", event_context: Dictionary = {}, event_scale: float = 1.0) -> void:
	data = event_data
	key = event_key
	run_time = time
	source = event_source
	context = event_context
	scale = event_scale


func experience_text() -> String:
	return data.experience_text.replace("{name}", str(context.get("name", "")))
