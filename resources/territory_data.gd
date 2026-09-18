class_name TerritoryData
extends Resource
## Sprint 05 (P4-005): one place the dog can come to own, in the sense a dog
## owns anywhere — by turning up again and again and leaving its scent on it
## (ADR-012: territory is a relationship, not an empire).
##
## Authoring data only. Live state lives in TerritoryProgress; the world node
## (TerritoryPoint3D) shows it. There is deliberately no passive income, no
## upkeep and no decay.

@export var id: StringName
@export var display_name: String
## Relevant successful extractions needed before the place is the dog's.
@export var claim_target: int = 3
## The pair that lives here and will not simply hand it over.
@export var resident_spot: StringName
## Collection/place id this landmark registers as when first found.
@export var place_id: StringName
## Granted once, when the claim completes.
@export var reward_table: LootTableData
## Progress flag set once the place is owned, so content can react to it.
@export var owned_flag: StringName

@export_group("Dog words")
@export var discovered_text: String
@export var rival_scent_text: String
@export var marked_text: String
@export var claimed_text: String
