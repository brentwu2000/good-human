class_name HumanBackgroundData
extends Resource
## Sprint 06 (S06-04, D6-04): an ordinary person who might come to the shelter
## — who they are underneath, which the player never reads directly. It shapes
## what dog behaviour reaches them and how they show it. It never decides how
## strong they are (their stats are rolled apart), and their looks are drawn
## from ordinary clothes, not from how they fight.

## How a visiting human shows what a dog just did to them (D6-05).
enum Reaction { INTERESTED, AMUSED, CAUTIOUS, STARTLED, AFFECTIONATE, INDIFFERENT }

@export var id: StringName
## Who they turn out to be, said once the adoption is done.
@export var reveal_text: String
@export var personality_tags: Array[StringName] = []
## DogTraitData.Behavior -> how much it draws them in (-1..1).
@export var preference_weights: Dictionary[int, float] = {}
## Dog personality tag -> how much they warm to a dog like that (-1..1).
@export var likes_dog_tags: Dictionary[StringName, float] = {}
## Things about them that show up later (habits, growth), never shown here.
@export var tendencies: Array[StringName] = []
## Names the player is offered (they can type their own).
@export var name_suggestions: Array[String] = []

@export_group("Looks (ordinary clothes)")
@export var shirt_colors: Array[Color] = []
@export var pants_colors: Array[Color] = []
@export var hair_styles: Array[int] = []
@export var top_styles: Array[int] = []
@export var accessory_styles: Array[int] = []
## Their own model on the OwnerSkeleton (e.g. the office worker's), worn by
## everyone of this background; null = the shared P-04 human in their colours.
@export var skeletal_model: PackedScene
## Xiaomi toy proxy (docs/04_systems/XIAOMI_TOY_PROXY.md): who fights for
## people of this background. Null = they fight themselves. When set, this
## fighter (with the person's own rolled stats) takes every blow, and the
## person stays out of the fight: never a target, never hurt.
@export var combat_proxy: FighterData

@export_group("Reactions")
## Reaction -> what they say (short, in their own voice).
@export var reaction_lines: Dictionary[int, String] = {}
