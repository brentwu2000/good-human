class_name FighterData
extends Resource
## A human who can fight: stats, skill set and placeholder look.
## `id` is stable so a future persistent rival can refer to it.

@export var id: StringName
@export var display_name: String
@export var stats: CombatStats
@export var skills: Array[CombatSkillData] = []

@export_group("Production Art")
## Optional. FighterPuppet keeps its Polygon2D fallback when this is null.
@export var combat_sprite_frames: SpriteFrames

@export_group("Placeholder Look")
@export var skin_color: Color = Color(0.95, 0.8, 0.65)
@export var hair_color: Color = Color(0.25, 0.18, 0.12)
@export var shirt_color: Color = Color(0.85, 0.45, 0.35)
@export var pants_color: Color = Color(0.2, 0.25, 0.4)
## x = width, y = height.
@export var body_scale: Vector2 = Vector2.ONE
## Forward lean in radians (older people stoop).
@export var stoop: float = 0.0

@export_group("3D Modular Appearance")
## Authored appearance-only values. Never derive these from combat stats.
@export_enum("Short", "Bob", "Curly", "Cap", "Bun") var hair_style: int = 0
@export_enum("Overshirt", "Hoodie", "Work Jacket", "Tee", "Cardigan") var top_style: int = 0
@export_enum("Straight", "Cuffed", "Wide") var bottom_style: int = 0
@export_enum("None", "Glasses", "Messenger Bag", "Tote Bag", "Backpack") var accessory_style: int = 0
@export var shoe_color: Color = Color(0.12, 0.14, 0.16)
