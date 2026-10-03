class_name BanyanRivalPair3D
extends RefCounted
## Recognition layer for the persistent Banyan rival pair.
## The accessories communicate identity and place, never combat strength.

const CORAL := Color("#cf674f")
const CREAM := Color("#ead9b8")
const TEAL := Color("#358d84")
const INK := Color("#293438")
## Where the neckerchief sits on the greybox dog, and where it sits on a
## rigged breed dog relative to its neck bone (fraction up the neck), shrunk
## to the narrower neck.
const GREYBOX_COLLAR := Vector3(0, 0.57, -0.31)
const NECK_COLLAR_AT: float = 0.35
const NECK_COLLAR_SCALE: float = 1.0
## Out past the fur, towards the chest.
const NECK_COLLAR_OUT := Vector3(0, -0.02, -0.07)


static func decorate(human: Node3D, dog: Node3D) -> void:
	_remove_previous(human)
	_remove_previous(dog)
	var old_skeleton := _neck_skeleton(dog)
	if old_skeleton != null:
		_remove_previous(old_skeleton)
	var human_style := Node3D.new()
	human_style.name = "BanyanRivalStyle"
	# Folded park map and ordinary enamel pin: recognizable, not threatening.
	human_style.add_child(Greybox.box(Vector3(0.22, 0.28, 0.035), CREAM, Vector3(-0.30, 1.02, -0.13), Vector3(0, 0, -0.15)))
	human_style.add_child(Greybox.sphere(0.045, TEAL, Vector3(0.20, 1.30, -0.27)))
	human.add_child(human_style)
	var dog_style := Node3D.new()
	dog_style.name = "BanyanRivalStyle"
	# Worn coral neckerchief and leaf tag make the rival's dog memorable.
	dog_style.add_child(Greybox.box(Vector3(0.34, 0.055, 0.12), CORAL, Vector3(0, 0.57, -0.31), Vector3(0.05, 0, 0)))
	dog_style.add_child(Greybox.box(Vector3(0.13, 0.22, 0.045), CORAL.darkened(0.10), Vector3(0.12, 0.45, -0.29), Vector3(0, 0, -0.48)))
	dog_style.add_child(Greybox.box(Vector3(0.10, 0.025, 0.18), TEAL, Vector3(-0.08, 0.49, -0.38), Vector3(0.15, 0.25, 0.30)))
	dog_style.add_child(Greybox.sphere(0.025, INK, Vector3(-0.08, 0.49, -0.48)))
	var skeleton := _neck_skeleton(dog)
	if skeleton == null:
		dog.add_child(dog_style)
		return
	# A rigged dog wears it on its neck bone, so it follows Idle / Walk.
	var neck := skeleton.find_bone("neck")
	var attachment := BoneAttachment3D.new()
	attachment.name = "BanyanRivalStyle"
	attachment.bone_name = "neck"
	skeleton.add_child(attachment)
	var rest := skeleton.get_bone_global_rest(neck)
	var child := skeleton.find_bone("head")
	var collar_in_skeleton := rest.origin.lerp(skeleton.get_bone_global_rest(child).origin, NECK_COLLAR_AT) if child >= 0 else rest.origin
	var to_skeleton := dog.global_transform.affine_inverse() * skeleton.global_transform
	var collar := to_skeleton * collar_in_skeleton + NECK_COLLAR_OUT
	var placed := Transform3D(Basis().scaled(Vector3.ONE * NECK_COLLAR_SCALE), collar) * Transform3D(Basis(), -GREYBOX_COLLAR)
	dog_style.name = "Style"
	attachment.add_child(dog_style)
	dog_style.transform = (to_skeleton * rest).affine_inverse() * placed


static func _neck_skeleton(dog: Node3D) -> Skeleton3D:
	for skeleton: Skeleton3D in dog.find_children("*", "Skeleton3D", true, false):
		if skeleton.find_bone("neck") >= 0:
			return skeleton
	return null


static func _remove_previous(node: Node) -> void:
	var previous := node.get_node_or_null("BanyanRivalStyle")
	if previous != null:
		previous.queue_free()
