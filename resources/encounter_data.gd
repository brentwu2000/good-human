class_name EncounterData
extends Resource
## A dog + human pair that can be met on a walk. The dog is the social
## identity; the human does the fighting. Never expose a power number.

enum Tier { ORDINARY, RECOGNIZABLE, OVERPOWERED }
enum DogBreed { MIX, SHIBA, PIT, SMALL_WHITE, BLACK_DOG }

@export var id: StringName
@export var tier: Tier = Tier.ORDINARY
@export var human: FighterData
@export var dog_name: String = "狗"
@export var dog_color: Color = Color(0.9, 0.9, 0.9)
## Sizes the dog's physical presence (and the greybox dog). With a dog_model
## it should match that model's authored size: its length over 0.8 m.
@export var dog_scale: float = 1.0
## Rigged breed model (Idle / Walk / Sit), shown at its authored size.
## Empty: the code-built greybox dog stands in, shaped by dog_breed.
@export var dog_model: PackedScene
## Silhouette and body-language identity; appearance only, never combat power.
@export var dog_breed: DogBreed = DogBreed.MIX
## Shown when the pair blocks the way. Appearance only.
@export_multiline var intro_text: String
## S05-06: what their human says on seeing another dog mark their place.
@export var mark_reaction_text: String

@export_group("Persistent rival (S05-07)")
## The same pair walk after walk: fights with them are remembered, and they
## remember too. Memory only — never stronger or weaker for it.
@export var persistent_rival: bool = false
## Said on meeting again after the player's dog won last time…
@export var recall_beaten_text: String
## …and after it lost.
@export var recall_won_text: String
@export var reward_table: LootTableData
