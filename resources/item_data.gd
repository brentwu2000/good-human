class_name ItemData
extends Resource
## Static definition of an item. Runtime quantities live in ItemStack.

enum ItemType { JUNK, FOOD, MEDICAL, TRAINING, EQUIPMENT, SPECIAL }
enum Rarity { COMMON, UNCOMMON, RARE }

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var type: ItemType
@export var rarity: Rarity
@export var stackable: bool = true
@export var max_stack: int = 99
@export var value: int = 0
@export var icon: Texture2D


## Effective per-slot limit (non-stackable items always hold 1).
func get_stack_limit() -> int:
	return maxi(max_stack, 1) if stackable else 1
