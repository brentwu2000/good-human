class_name WeaponData
extends Resource
## P-05 (P05-02, ADR-021/022): an ordinary street object a human can fight
## with. Holding it replaces the human's moveset and changes their reach,
## rhythm, defence, recovery and spacing — never only their damage. The dog
## never uses it.

enum Archetype { UNARMED, UMBRELLA, LONG_OBJECT, HEAVY_BLUNT }

@export var id: StringName
@export var display_name: String
@export var archetype: Archetype = Archetype.UNARMED
## The find it comes from (an umbrella in the owner's bag). Its size class is
## what decides where it can be carried (P05-01).
@export var item: ItemData
## Null for UNARMED: the human's own fists and feet (their FighterData skills).
@export var moveset: WeaponMoveSet
## How much use it takes before it breaks (P05-09). 0 = it never wears.
@export var condition_max: int = 0
@export var world_prefab: PackedScene
@export var tags: Array[StringName] = []


func is_unarmed() -> bool:
	return archetype == Archetype.UNARMED or moveset == null
