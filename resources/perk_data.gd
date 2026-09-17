class_name PerkData
extends Resource
## A named change in the human, unlocked by accumulated growth. Its effect is
## read by GrowthResolver (behaviour traits) and CombatStats bonuses.

@export var id: StringName
@export var display_name: String
## What the player notices, in plain words.
@export_multiline var description: String
## Not listed at Home before it is unlocked.
@export var hidden: bool = false
## Tag name (RUN/STRAIN/COURAGE/SOCIAL/ENDURE) -> minimum growth.
@export var requirements: Dictionary[String, float] = {}
## Human defeats needed (hard experiences).
@export var min_defeats: int = 0

@export_group("Effect")
## Behaviour trait this perk completes: stumble, exertion, recovery,
## hesitation, heavy_bag, greeting. Empty = none.
@export var trait_key: StringName
## Small permanent combat stat bonuses.
@export var bonus_strength: int = 0
@export var bonus_endurance: int = 0
@export var bonus_agility: int = 0
@export var bonus_will: int = 0


func is_met(growth: Dictionary, defeats: int) -> bool:
	if defeats < min_defeats:
		return false
	for tag: String in requirements:
		if float(growth.get(tag, 0.0)) < requirements[tag]:
			return false
	return true
