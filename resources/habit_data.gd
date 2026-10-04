class_name HabitData
extends Resource
## Sprint 06 (S06-09, SPRINT06_IDENTITY_SCHEMA HabitData): something the human
## starts doing because the dog keeps doing something. Built over walks from
## the same moments TRAIN already sees, and shown in how the owner walks
## (OwnerBehavior), never as a stat.

@export var id: StringName
## Training event ids that count towards it.
@export var trigger_event_ids: Array[StringName] = []
## Also counts the walk's searches (the dog rummaging through things).
@export var counts_searches: bool = false
## Moments needed, across walks.
@export var threshold: int = 4
## Human tendency -> moments it takes off the threshold (who they are makes
## some habits come sooner).
@export var tendency_head_start: Dictionary[StringName, int] = {}
## What OwnerBehavior does with it: sprint_ready, leash_brace, search_sigh,
## social_ready.
@export var presentation_effect: StringName
## Said at Home, about the human: 「看你一加速，就先跟著小跑。」
@export var home_text: String
## Said the walk it first shows: 「（主人好像……）」
@export var noticed_text: String
## What the owner says when it shows on a walk (once per walk).
@export var walk_line: String
