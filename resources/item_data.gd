class_name ItemData
extends Resource
## Static definition of an item. Runtime quantities live in ItemStack.

enum ItemType { JUNK, FOOD, MEDICAL, TRAINING, EQUIPMENT, SPECIAL }
enum Rarity { COMMON, UNCOMMON, RARE }
## P-05 (P05-01): what a find is for. A WEAPON changes the human's moveset,
## HUMAN_GEAR their movement / defence / recovery, DOG_GEAR the dog's search /
## leash / carrying; a VALUABLE is mostly worth money or a place in the
## collection. SUPPLY is the existing consumables (food, medicine, training
## kit), which the P-05 list does not name.
enum LootClass { VALUABLE, WEAPON, HUMAN_GEAR, DOG_GEAR, SUPPLY }
## P05-01 / P05-12: how big it physically is. Only SMALL things fit in the
## dog's backpack (DOG_SAFE); an umbrella cannot disappear into it.
enum SizeClass { SMALL, MEDIUM, LARGE }

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var type: ItemType
@export var rarity: Rarity
@export var stackable: bool = true
@export var max_stack: int = 99
@export var value: int = 0
@export var icon: Texture2D
## S05-02: how much of the owner's condition (0..1) using it on them gives
## back. 0 = it cannot be used on the owner.
@export_range(0.0, 1.0) var owner_recovery: float = 0.0
@export var loot_class: LootClass = LootClass.VALUABLE
@export var size_class: SizeClass = SizeClass.SMALL


static func rarity_color(value: Rarity) -> Color:
	match value:
		Rarity.UNCOMMON:
			return Color(0.45, 0.8, 1.0)
		Rarity.RARE:
			return Color(1.0, 0.8, 0.25)
	return Color(0.92, 0.92, 0.92)


func get_rarity_color() -> Color:
	return rarity_color(rarity)


## Small enough for the dog's backpack.
func is_safe_eligible() -> bool:
	return size_class == SizeClass.SMALL


## Effective per-slot limit (non-stackable items always hold 1).
func get_stack_limit() -> int:
	return maxi(max_stack, 1) if stackable else 1
