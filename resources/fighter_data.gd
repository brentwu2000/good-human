class_name FighterData
extends Resource
## A human who can fight: stats, skill set and placeholder look.
## `id` is stable so a future persistent rival can refer to it.

@export var id: StringName
@export var display_name: String
@export var stats: CombatStats
@export var skills: Array[CombatSkillData] = []

@export_group("Placeholder Look")
@export var skin_color: Color = Color(0.95, 0.8, 0.65)
@export var hair_color: Color = Color(0.25, 0.18, 0.12)
@export var shirt_color: Color = Color(0.85, 0.45, 0.35)
@export var pants_color: Color = Color(0.2, 0.25, 0.4)
## x = width, y = height.
@export var body_scale: Vector2 = Vector2.ONE
## Forward lean in radians (older people stoop).
@export var stoop: float = 0.0
