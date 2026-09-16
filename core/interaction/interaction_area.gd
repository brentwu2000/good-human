class_name InteractionArea
extends Area2D
## Detection shape for the parent Interactable (physics layer 3 "interactable").

const INTERACTABLE_LAYER: int = 1 << 2

var interactable: Interactable


func _ready() -> void:
	interactable = get_parent() as Interactable
	if interactable == null:
		push_error("InteractionArea %s must be a child of an Interactable" % get_path())
	collision_layer = INTERACTABLE_LAYER
	collision_mask = 0
	monitoring = false
	monitorable = true
