class_name PlaceMarker3D
extends Node3D
## A named place for the dog's discoveries (collection: places), in meters.

@export var place_id: StringName
@export var display_name: String
@export var radius: float = 4.0


func _enter_tree() -> void:
	add_to_group(PlaceMarker.GROUP)
