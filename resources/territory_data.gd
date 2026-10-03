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
## S05-08: who that is, for what the dog remembers at Home. By id and name
## only, so loading the places never loads the pair.
@export var resident_encounter_id: StringName
@export var resident_name: String
## Collection/place id this landmark registers as when first found.
@export var place_id: StringName
## S05-11: found once, at the roots, on the first walk the place is the
## dog's own (the claim itself completes at home).
@export var reward_table: LootTableData
## Progress flag set once the place is owned, so content can react to it.
@export var owned_flag: StringName
## S05-10: progress flag set once the dog knows another dog lives here, so
## desires can follow the place.
@export var contested_flag: StringName

@export_group("Dog words")
@export var discovered_text: String
@export var rival_scent_text: String
@export var marked_text: String
@export var claimed_text: String
## S05-11: said when the dog finds the place's reward at the roots.
@export var reward_found_text: String
## S05-09: on the result screen — marked and got home (it counted)…
@export var came_home_text: String
## …or marked and did not (it did not, and nothing was lost either).
@export var not_home_text: String
## S05-05: what the roots smell of on a later walk, by whose scent is on top.
## Only the resident's (CONTESTED)…
@export var rival_only_text: String
## …both dogs', mixed (CLAIMING)…
@export var mixed_scent_text: String
## …mostly the dog's own (OWNED).
@export var own_scent_text: String
