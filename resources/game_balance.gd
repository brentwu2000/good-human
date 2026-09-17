class_name GameBalance
extends Resource
## Tunable numbers shared across systems. Per-point values (search duration,
## extraction unlock time) stay on the SearchPoint / ExtractionPoint exports.

@export var human_run_slots: int = 8
@export var dog_safe_slots: int = 2
@export var home_stash_slots: int = 30

@export_group("Combat")
## Derived combat values (CombatStats). Keep formulas here, not in skills.
@export var hp_base: float = 40.0
@export var hp_per_endurance: float = 6.0
@export var attack_base: float = 4.0
@export var attack_per_strength: float = 1.5
@export var action_interval_base: float = 1.2
@export var action_interval_per_agility: float = 0.06
@export var action_interval_min: float = 0.25
@export var move_speed_base: float = 90.0
@export var move_speed_per_agility: float = 8.0
@export var stability_per_will: float = 1.0
## Random spread applied to every hit, e.g. 0.15 = ±15%.
@export_range(0.0, 1.0) var damage_variance: float = 0.15
## Chance an idle fighter hesitates for one decision (keeps fights from being scripted).
@export_range(0.0, 1.0) var hesitation_chance: float = 0.15
## Once engaged, the player's human breaks away when the dog is this far away.
@export var disengage_distance: float = 480.0
## Fights longer than this end as ABORTED.
@export var combat_max_duration: float = 90.0
