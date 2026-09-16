class_name Interactable
extends Node2D
## Base for anything the dog can interact with. Needs an InteractionArea child
## so the dog's InteractionDetector can find it.

@export var prompt: String = "互動"
@export var enabled: bool = true


func can_interact(_context: Object) -> bool:
	return enabled


func interact(_context: Object) -> void:
	pass


func get_prompt(_context: Object) -> String:
	return prompt
