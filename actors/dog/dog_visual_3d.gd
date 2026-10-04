class_name DogVisual3D
extends RefCounted
## Sprint 06: the look of one particular dog, built from its breed. Shared by
## the shelter, the adoption room, Home and the walk, so the dog the player
## chose is the dog they see everywhere.


## Just the breed's model at the breed's size (the walk adds its own pivot).
static func model_for(dog: DogCandidate) -> Node3D:
	var breed := DataRegistry.get_dog_breed(dog.breed_id) if dog != null else null
	var scene: PackedScene = null
	if breed != null and ResourceLoader.exists(breed.model_path):
		scene = SoftToon.pick(load(breed.model_path) as PackedScene, breed.stylized_model_path)
	if scene == null:
		scene = SoftToon.pick(DogController3D.MODEL_SCENE, DogController3D.STYLIZED_SCENE)
	var model := scene.instantiate() as Node3D
	model.name = "Model"
	if breed != null:
		model.scale = Vector3.ONE * breed.size
	return model


## A bare pivot (callers yaw it to face) holding the breed model and its
## motion driver, reachable as `pivot.get_node("Motion")`. Falls back to the
## shiba when the breed is unknown.
static func build(dog: DogCandidate) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = "DogVisual"
	var model := model_for(dog)
	model.rotation.y = DogController3D.MODEL_YAW
	pivot.add_child(model)
	var motion := DogModelMotion3D.new()
	motion.name = "Motion"
	pivot.add_child(motion)
	motion.bind(model)
	SoftToon.register(pivot)
	return pivot
