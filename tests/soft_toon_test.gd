extends "res://tests/test_case.gd"
## Style Bible v1: one shared soft-toon material for every character, off by
## default, switchable live, and fully reversible.

const OWNER_MODEL: PackedScene = preload("res://assets/characters/human/models/p04_owner/p04_owner.glb")


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var was := SoftToon.enabled
	check(not ProjectSettings.get_setting("art/soft_toon", false), "off by default: the game's look only changes on purpose")
	SoftToon.enabled = false
	var human := P04HumanVisual.new(OWNER_MODEL)
	add_child(human)
	var dog := Greybox.dog(Color(0.8, 0.5, 0.3), 1.0, 1)
	add_child(dog)
	SoftToon.register(dog)
	await get_tree().process_frame
	check(human.is_in_group(SoftToon.GROUP) and dog.is_in_group(SoftToon.GROUP), "people and dogs are both registered")
	check_eq(_toon_surfaces(human), 0, "nothing changes while it is off")

	SoftToon.set_enabled(get_tree(), true)
	var total := _surfaces(human)
	check(total > 0 and _toon_surfaces(human) == total, "on: every surface of the human uses the toon shader (%d)" % total)
	check(_toon_surfaces(dog) == _surfaces(dog), "and the dog's")
	var mi := human.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var original := mi.mesh.surface_get_material(0) as BaseMaterial3D
	var toon := mi.get_surface_override_material(0) as ShaderMaterial
	if original != null:
		check(toon.get_shader_parameter("albedo_color") == original.albedo_color, "the character keeps its own colour")
	var late := Greybox.dog(Color.WHITE, 0.6, 3)
	add_child(late)
	SoftToon.register(late)
	check(_toon_surfaces(late) == _surfaces(late), "a character spawned while on gets it straight away")

	var stylized := SoftToon.pick(OWNER_MODEL, P04HumanVisual.STYLIZED_MODEL)
	check(stylized != OWNER_MODEL and stylized.resource_path.ends_with("_stylized.glb"), "on: new characters get the Style v1 proportions")
	var styled_human := P04HumanVisual.new()
	add_child(styled_human)
	check(styled_human.skeleton.find_bone("head") >= 0 and styled_human.player.has_animation("Jab"), "same skeleton and clips on the stylized model")
	var dog_scene := SoftToon.pick(DogController3D.MODEL_SCENE, DogController3D.STYLIZED_SCENE)
	check(dog_scene.resource_path.ends_with("shiba_01_stylized.glb"), "and the shiba's")

	SoftToon.set_enabled(get_tree(), false)
	check(SoftToon.pick(OWNER_MODEL, P04HumanVisual.STYLIZED_MODEL) == OWNER_MODEL, "off: the original models")
	check_eq(_toon_surfaces(human) + _toon_surfaces(dog) + _toon_surfaces(late), 0, "off again: the original materials are back")
	SoftToon.enabled = was
	finish()


func _surfaces(root: Node) -> int:
	var n := 0
	for m in root.find_children("*", "MeshInstance3D", true, false):
		if (m as MeshInstance3D).mesh != null:
			n += (m as MeshInstance3D).mesh.get_surface_count()
	return n


func _toon_surfaces(root: Node) -> int:
	var n := 0
	for m in root.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var o := mi.get_surface_override_material(s)
			if o is ShaderMaterial and (o as ShaderMaterial).shader == SoftToon.SHADER:
				n += 1
	return n
