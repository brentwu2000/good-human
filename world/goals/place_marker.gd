class_name PlaceMarker
extends Node2D
## A named place for the dog's discoveries (collection: places).

const GROUP: StringName = &"place_markers"

@export var place_id: StringName
@export var display_name: String
@export var radius: float = 300.0


func _enter_tree() -> void:
	add_to_group(GROUP)
