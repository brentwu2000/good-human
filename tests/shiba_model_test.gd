extends "res://tests/test_case.gd"
## The generated shiba imports as a usable Godot character: skinned mesh,
## the quadruped skeleton with the agreed bone names, and the three PoC clips.

const MODEL_PATH: String = "res://assets/characters/dog/models/shiba_01/shiba_01.glb"
const REQUIRED_BONES: PackedStringArray = [
	"ROOT", "pelvis", "spine_01", "spine_02", "neck", "head",
	"front_leg_L", "front_leg_R", "rear_leg_L", "rear_leg_R", "tail_01",
]
const REQUIRED_CLIPS: PackedStringArray = ["Idle", "Walk", "Sit"]


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	check(ResourceLoader.exists(MODEL_PATH), "model imported: " + MODEL_PATH)
	var packed: PackedScene = load(MODEL_PATH) as PackedScene
	check(packed != null, "model loads as a PackedScene")
	if packed == null:
		finish()
		return

	var root: Node3D = packed.instantiate() as Node3D
	add_child(root)

	var skeleton: Skeleton3D = _find(root, "Skeleton3D") as Skeleton3D
	check(skeleton != null, "model has a Skeleton3D")
	if skeleton != null:
		for bone_name in REQUIRED_BONES:
			check(skeleton.find_bone(bone_name) != -1, "skeleton keeps bone " + bone_name)

	var mesh_node: MeshInstance3D = _find(root, "MeshInstance3D") as MeshInstance3D
	check(mesh_node != null, "model has a MeshInstance3D")
	if mesh_node != null:
		check(mesh_node.skin != null, "body mesh is skinned to the rig")

	var player: AnimationPlayer = _find(root, "AnimationPlayer") as AnimationPlayer
	check(player != null, "model has an AnimationPlayer")
	if player != null:
		var clips: PackedStringArray = player.get_animation_list()
		for clip in REQUIRED_CLIPS:
			check(clips.has(clip), "animation present: " + clip)
		if clips.has("Walk"):
			check(player.get_animation("Walk").length > 0.0, "Walk has a duration")

	var aabb: AABB = _visual_bounds(root)
	# A shiba is knee-high: sanity-check the export scale rather than the art.
	check(aabb.size.y > 0.2 and aabb.size.y < 1.0,
		"model height is in metres, got %.3f" % aabb.size.y)

	root.queue_free()
	finish()


func _find(node: Node, type_name: String) -> Node:
	if node.is_class(type_name):
		return node
	for child in node.get_children():
		var found: Node = _find(child, type_name)
		if found != null:
			return found
	return null


func _visual_bounds(node: Node) -> AABB:
	var bounds: AABB = AABB()
	var seen: bool = false
	for child in node.get_children():
		if child is VisualInstance3D:
			var vi: VisualInstance3D = child as VisualInstance3D
			var box: AABB = vi.get_aabb()
			box.position += vi.position
			bounds = box if not seen else bounds.merge(box)
			seen = true
		var sub: AABB = _visual_bounds(child)
		if sub.size != Vector3.ZERO:
			bounds = sub if not seen else bounds.merge(sub)
			seen = true
	return bounds
