extends "res://tests/test_case.gd"
## Owner, 2026-10-08: 「把codex完成的狗建模套入遊戲中」. Every breed model the
## game loads (the adoptable dogs and the opponents' dogs) is a skinned dog the
## game can drive: a skeleton, the clips DogModelMotion3D plays, a body of dog
## size standing on the ground facing the way the game expects, and textures.

const BREEDS_DIR: String = "res://data/identity/breeds/"
const ENCOUNTERS_DIR: String = "res://data/encounters/"
const CLIPS: Array[String] = [DogModelMotion3D.IDLE_CLIP, DogModelMotion3D.WALK_CLIP, DogModelMotion3D.SIT_CLIP]
## Triangles a breed model may have (the published ones are 30–51 k; this
## catches a full-detail sculpt being dropped in by mistake).
const MAX_TRIANGLES: int = 60000


func _ready() -> void:
	var paths: Dictionary = {}
	for file in DirAccess.get_files_at(BREEDS_DIR):
		if file.ends_with(".tres"):
			var breed := load(BREEDS_DIR + file) as DogBreedData
			if breed != null and not breed.model_path.is_empty():
				paths[breed.model_path] = true
	for file in DirAccess.get_files_at(ENCOUNTERS_DIR):
		if file.ends_with(".tres"):
			var text := FileAccess.get_file_as_string(ENCOUNTERS_DIR + file)
			for line in text.split("\n"):
				if line.contains("models/breeds/") and line.contains("path=\""):
					paths[line.get_slice("path=\"", 1).get_slice("\"", 0)] = true
	check(paths.size() >= 7, "breed models found (%d)" % paths.size())
	for path: String in paths:
		_check_model(path)
	finish()


func _check_model(path: String) -> void:
	var name := path.get_file()
	var scene := load(path) as PackedScene
	check(scene != null, "%s loads" % name)
	if scene == null:
		return
	var model := scene.instantiate() as Node3D
	add_child(model)
	var skeleton := model.find_children("*", "Skeleton3D", true, false)
	check(not skeleton.is_empty() and (skeleton[0] as Skeleton3D).get_bone_count() > 10, "%s has a skeleton" % name)
	var players := model.find_children("*", "AnimationPlayer", true, false)
	var player := players[0] as AnimationPlayer if not players.is_empty() else null
	for clip in CLIPS:
		check(player != null and player.has_animation(clip), "%s has the %s clip" % [name, clip])
	var triangles := 0
	var box := AABB()
	var first := true
	var textured := false
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		var mesh := mesh_instance.mesh
		if mesh == null:
			continue
		for surface in mesh.get_surface_count():
			var arrays := mesh.surface_get_arrays(surface)
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			triangles += (indices.size() if not indices.is_empty() else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
			var material := mesh_instance.get_active_material(surface) as BaseMaterial3D
			# A texture, or colour painted on the vertices (the player's shiba).
			var painted: bool = (mesh.surface_get_format(surface) & Mesh.ARRAY_FORMAT_COLOR) != 0
			textured = textured or painted or (material != null and material.albedo_texture != null)
		var world := mesh_instance.global_transform * mesh.get_aabb()
		box = world if first else box.merge(world)
		first = false
	check(textured, "%s is coloured (texture or vertex colour)" % name)
	check(triangles > 1000 and triangles <= MAX_TRIANGLES, "%s is a sensible size for the game (%d triangles)" % [name, triangles])
	# Dog-sized before the breed's own scale, standing on the ground, longer
	# nose to tail than it is wide (so the game's facing turns it the right way).
	check(box.size.y > 0.2 and box.size.y < 1.5, "%s is dog height (%.2f m)" % [name, box.size.y])
	check(absf(box.position.y) < 0.1, "%s stands on the ground (lowest %.2f m)" % [name, box.position.y])
	check(box.size.z > box.size.x, "%s faces along its length (%.2f × %.2f m)" % [name, box.size.x, box.size.z])
	model.queue_free()
