class_name GameBalance
extends Resource
## Tunable numbers shared across systems. Per-point values (search duration,
## extraction unlock time) stay on the SearchPoint / ExtractionPoint exports.

@export var human_run_slots: int = 8
@export var dog_safe_slots: int = 2
@export var home_stash_slots: int = 30
