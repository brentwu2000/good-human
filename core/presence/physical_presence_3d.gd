class_name PhysicalPresence3D
extends AnimatableBody3D
## ADR-016: a body that is drawn and posed by presentation but still occupies
## space. It rides on the node it is attached to (an opponent human or dog),
## so wherever the fight or the walk puts that node, the body is there too.
## It blocks the player's dog and owner; it never pushes anything itself and
## never deals damage.

## The player's dog ran into this body fast enough to be felt.
signal dog_contact(from: Vector3, speed: float)


func _init() -> void:
	collision_layer = Greybox.ACTOR_LAYER
	collision_mask = 0
	# Moved by its parent's transform (the combat sync places fighters
	# directly), not by an animation, so there is no motion to sync.
	sync_to_physics = false


## A standing person, scaled with the fighter's build.
static func for_human(data: PresenceData, body_scale: Vector2 = Vector2.ONE) -> PhysicalPresence3D:
	var body := PhysicalPresence3D.new()
	body.name = "Presence"
	var capsule := CapsuleShape3D.new()
	capsule.radius = data.human_radius * body_scale.x
	capsule.height = maxf(data.human_height * body_scale.y, capsule.radius * 2.0)
	var shape := CollisionShape3D.new()
	shape.shape = capsule
	shape.position.y = capsule.height * 0.5
	body.add_child(shape)
	return body


## A dog lying along its facing (-Z), scaled with its breed size.
static func for_dog(data: PresenceData, size: float = 1.0) -> PhysicalPresence3D:
	var body := PhysicalPresence3D.new()
	body.name = "Presence"
	var capsule := CapsuleShape3D.new()
	capsule.radius = data.dog_radius * size
	capsule.height = maxf(data.dog_length * size, capsule.radius * 2.0)
	var shape := CollisionShape3D.new()
	shape.shape = capsule
	shape.rotation_degrees.x = 90.0
	shape.position.y = maxf(data.dog_center_height * size, capsule.radius)
	body.add_child(shape)
	return body


## Called by the player's dog when it runs into this body.
func receive_dog_contact(from: Vector3, speed: float) -> void:
	dog_contact.emit(from, speed)
