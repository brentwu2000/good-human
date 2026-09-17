class_name TrainingEventData
extends Resource
## Definition of one meaningful thing that can happen on a walk and teach the
## human something. World observers emit these; they never touch permanent
## stats. Player-facing text describes the experience, never the tag.

enum Tag { RUN, STRAIN, COURAGE, SOCIAL, ENDURE }

@export var id: StringName
@export var tag: Tag = Tag.RUN
## Base TrainingTag amount before anti-farming.
@export var magnitude: float = 1.0
## Same event with the same key is ignored for this many seconds.
@export var cooldown: float = 0.0
## Only once per key per run (e.g. one chat per pair).
@export var unique_per_key: bool = false
## Result screen line. `{name}` is replaced by context["name"] when given.
@export var experience_text: String
## Optional owner speech bubble when it happens.
@export var owner_line: String


static func tag_name(value: Tag) -> String:
	return Tag.keys()[value]
