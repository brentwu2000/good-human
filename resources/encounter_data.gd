class_name EncounterData
extends Resource
## A dog + human pair that can be met on a walk. The dog is the social
## identity; the human does the fighting. Never expose a power number.

enum Tier { ORDINARY, RECOGNIZABLE, OVERPOWERED }

@export var id: StringName
@export var tier: Tier = Tier.ORDINARY
@export var human: FighterData
@export var dog_name: String = "狗"
@export var dog_color: Color = Color(0.9, 0.9, 0.9)
@export var dog_scale: float = 1.0
## Shown when the pair blocks the way. Appearance only.
@export_multiline var intro_text: String
@export var reward_table: LootTableData
