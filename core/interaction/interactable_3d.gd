class_name Interactable3D
extends Node3D
## 3D counterpart of Interactable. Needs an InteractionArea3D child so the
## dog's detector can find it. Same methods, so run systems treat both alike.

@export var prompt: String = "互動"
@export var enabled: bool = true


func can_interact(_context: Object) -> bool:
	return enabled


func interact(_context: Object) -> void:
	pass


func get_prompt(_context: Object) -> String:
	return prompt


## Adds the detection sphere (interactable physics layer).
func add_interaction_area(radius: float) -> InteractionArea3D:
	var area := InteractionArea3D.new()
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	shape.shape = sphere
	area.add_child(shape)
	add_child(area)
	return area
