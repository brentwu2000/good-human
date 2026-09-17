class_name InteractionArea3D
extends Area3D
## Detection shape for the parent Interactable3D (3D physics layer "interactable").

var interactable: Interactable3D


func _ready() -> void:
	interactable = get_parent() as Interactable3D
	if interactable == null:
		push_error("InteractionArea3D %s must be a child of an Interactable3D" % get_path())
	collision_layer = Greybox.INTERACTABLE_LAYER
	collision_mask = 0
	monitoring = false
	monitorable = true
