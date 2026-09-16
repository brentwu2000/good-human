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


static func rarity_color(value: Rarity) -> Color:
	match value:
		Rarity.UNCOMMON:
			return Color(0.45, 0.8, 1.0)
		Rarity.RARE:
			return Color(1.0, 0.8, 0.25)
	return Color(0.92, 0.92, 0.92)


func get_rarity_color() -> Color:
	return rarity_color(rarity)


## Effective per-slot limit (non-stackable items always hold 1).
func get_stack_limit() -> int:
	return maxi(max_stack, 1) if stackable else 1
