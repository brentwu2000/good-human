class_name BanyanRivalPair3D
extends RefCounted
## Recognition layer for the persistent Banyan rival pair.
## The accessories communicate identity and place, never combat strength.

const CORAL := Color("#cf674f")
const CREAM := Color("#ead9b8")
const TEAL := Color("#358d84")
const INK := Color("#293438")


static func decorate(human: Node3D, dog: Node3D) -> void:
	_remove_previous(human)
	_remove_previous(dog)
	var human_style := Node3D.new()
	human_style.name = "BanyanRivalStyle"
	# Folded park map and ordinary enamel pin: recognizable, not threatening.
	human_style.add_child(Greybox.box(Vector3(0.22, 0.28, 0.035), CREAM, Vector3(-0.30, 1.02, -0.13), Vector3(0, 0, -0.15)))
	human_style.add_child(Greybox.sphere(0.045, TEAL, Vector3(0.20, 1.30, -0.27)))
	human.add_child(human_style)
	var dog_style := Node3D.new()
	dog_style.name = "BanyanRivalStyle"
	# Worn coral neckerchief and leaf tag make the black dog memorable.
	dog_style.add_child(Greybox.box(Vector3(0.34, 0.055, 0.12), CORAL, Vector3(0, 0.57, -0.31), Vector3(0.05, 0, 0)))
	dog_style.add_child(Greybox.box(Vector3(0.13, 0.22, 0.045), CORAL.darkened(0.10), Vector3(0.12, 0.45, -0.29), Vector3(0, 0, -0.48)))
	dog_style.add_child(Greybox.box(Vector3(0.10, 0.025, 0.18), TEAL, Vector3(-0.08, 0.49, -0.38), Vector3(0.15, 0.25, 0.30)))
	dog_style.add_child(Greybox.sphere(0.025, INK, Vector3(-0.08, 0.49, -0.48)))
	dog.add_child(dog_style)


static func _remove_previous(node: Node) -> void:
	var previous := node.get_node_or_null("BanyanRivalStyle")
	if previous != null:
		previous.queue_free()
