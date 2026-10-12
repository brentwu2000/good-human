extends "res://tests/breed_models_test.gd"
func _ready() -> void:
	var path = "res://assets/art_previews/dogs/candidates/r31/chihuahua.glb"
	_check_model(path)
	var dog = load(path).instantiate()
	add_child(dog)
	var player = dog.find_child("AnimationPlayer", true, false)
	for clip in ["HeadLook", "Sniff"]:
		check(player.has_animation(clip), "new clip exists: " + clip)
		check(player.get_animation(clip).length >= 2.0, "new clip duration: " + clip)
	finish()