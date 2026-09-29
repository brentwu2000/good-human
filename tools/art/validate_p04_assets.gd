extends SceneTree
const HUMAN := preload("res://assets/characters/human/modular/p04_human_visual.gd")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _run() -> void:
	var human = HUMAN.new()
	root.add_child(human)
	_check(human.skeleton != null, "Missing Skeleton3D")
	_check(human.player != null, "Missing AnimationPlayer")
	for name: String in HUMAN.BONE_MAP:
		_check(human.find_child(name, true, false) is Node3D, "Missing legacy control: " + name)
		_check(human.skeleton.find_bone(HUMAN.BONE_MAP[name]) >= 0, "Missing mapped bone: " + name)
	var clips := ["Idle", "Idle_Untrained", "Idle_Scrapper", "Idle_Calm", "Walk", "Approach", "Circle", "Backstep", "Jab", "HeavyHook", "Kick", "Block", "Dodge", "HitLight", "HitHeavy", "Stumble", "Down"]
	for clip: String in clips:
		_check(human.player.has_animation(clip), "Missing clip: " + clip)
		if human.player.has_animation(clip):
			human.play_clip(clip, false)
			human.player.seek(human.player.get_animation(clip).length * 0.5, true)
			for index in human.skeleton.get_bone_count():
				_check(human.skeleton.get_bone_global_pose(index).is_finite(), "Non-finite pose: " + clip)
	human.use_legacy_controls()
	var index: int = human.skeleton.find_bone("upperarm_r")
	var before: Quaternion = human.skeleton.get_bone_pose_rotation(index)
	human.controls["ArmL"].rotation.x = -0.5
	human._process(0.016)
	_check(not before.is_equal_approx(human.skeleton.get_bone_pose_rotation(index)), "Legacy arm control did not deform skeleton")
	ProjectSettings.set_setting("art/use_p04_candidate", true)
	var candidate := HumanModular3D.build(FighterData.new())
	root.add_child(candidate)
	var model_parent: Node = candidate.model.get_parent()
	Greybox.bind_parts(candidate)
	_check(candidate.model.get_parent() == model_parent, "Legacy bind moved the imported skeleton")
	_check(Greybox.part(candidate, "ArmL") != null, "Gameplay joint lookup failed")
	ProjectSettings.set_setting("art/use_p04_candidate", false)
	var tree_scene := load("res://assets/environment/territory/models/banyan_01/banyan_01.glb") as PackedScene
	var tree := tree_scene.instantiate()
	root.add_child(tree)
	var mesh_count := 0
	for node: Node in tree.find_children("*", "MeshInstance3D", true, false):
		mesh_count += 1
		var mesh := node as MeshInstance3D
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(surface) as StandardMaterial3D
			_check(material != null, "Tree material missing")
			if material != null:
				print("TREE_MATERIAL ", node.name, " color=", material.albedo_color, " vertex=", material.vertex_color_use_as_albedo, " alpha=", material.transparency, " cull=", material.cull_mode)
	_check(mesh_count == 3, "Tree export contains unexpected meshes")
	_check(tree.find_children("*", "Skeleton3D", true, false).is_empty(), "Character leaked into tree export")
	var result := {"passed":failures.is_empty(), "failures":failures, "clips":clips.size(), "legacy_controls":HUMAN.BONE_MAP.size(), "tree_meshes":mesh_count}
	var file := FileAccess.open("res://assets/art_previews/p04/validation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	print(JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
