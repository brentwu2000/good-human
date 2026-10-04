class_name DogBreedData
extends Resource
## Sprint 06 (S06-01): a body a shelter dog can have. Appearance only: a breed
## says nothing about how good a dog is at anything (traits do that, and they
## are rolled separately).

@export var id: StringName
@export var display_name: String
## Model paths, loaded only when the dog is shown (the registry stays light).
@export_file("*.glb") var model_path: String
## Optional stylized variant used when the soft-toon look is on.
@export_file("*.glb") var stylized_model_path: String
## Model scale, for the shelter and the walk.
@export var size: float = 1.0
