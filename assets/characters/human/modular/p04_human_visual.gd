class_name P04HumanVisual
extends Node3D
## Opt-in Blender candidate. Seven legacy controls remain real Node3D nodes.
## Authored clip playback and procedural legacy control are mutually exclusive.

const MODEL := preload("res://assets/characters/human/models/p04_owner/p04_owner.glb")
const BONE_MAP := {"Hips": "pelvis", "Torso": "spine_03", "Head": "head", "ArmL": "upperarm_r", "ArmR": "upperarm_l", "LegL": "thigh_r", "LegR": "thigh_l"}
var skeleton: Skeleton3D
var player: AnimationPlayer
var model: Node3D
var legacy_driven := false
var controls: Dictionary = {}

func _init() -> void:
	name = "P04HumanCandidate"
	set_meta("skeletal_art", true)
	model = MODEL.instantiate()
	model.rotation.y = PI
	add_child(model)
	skeleton = _find_type(model, "Skeleton3D") as Skeleton3D
	player = _find_type(model, "AnimationPlayer") as AnimationPlayer
	for joint_name: String in BONE_MAP:
		var joint := Node3D.new()
		joint.name = joint_name
		add_child(joint)
		controls[joint_name] = joint
	process_priority = 50

func _process(_delta: float) -> void:
	if not legacy_driven or skeleton == null:
		return
	for joint_name: String in BONE_MAP:
		var index := skeleton.find_bone(BONE_MAP[joint_name])
		if index < 0:
			continue
		var control: Node3D = controls[joint_name]
		# The control is a rotation in this node's frame, turning the bone about
		# its own joint. With the parent's global rest P and the bone's local
		# rest L: global G = P·L, turned G' = C·G, so the new local pose is
		# P⁻¹·C·P·L. (Integration fix: the first version dropped L and P, and a
		# 0.5 rad control turned the head bone by 0.06 rad.)
		var parent := skeleton.get_bone_parent(index)
		var parent_rest := model.basis * (skeleton.get_bone_global_rest(parent).basis if parent >= 0 else Basis.IDENTITY)
		parent_rest = parent_rest.orthonormalized()
		var local_rest := skeleton.get_bone_rest(index).basis.orthonormalized()
		var posed := parent_rest.inverse() * control.basis * parent_rest * local_rest
		skeleton.set_bone_pose_rotation(index, posed.get_rotation_quaternion())

func play_clip(clip: String, loop := true) -> void:
	legacy_driven = false
	if player == null or not player.has_animation(clip):
		return
	var animation := player.get_animation(clip)
	animation.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	player.play(clip, 0.12)

func use_legacy_controls() -> void:
	if player != null:
		player.stop()
	if skeleton != null:
		skeleton.reset_bone_poses()
	legacy_driven = true

func set_outfit_colors(top: Color, trousers: Color) -> void:
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if not ("Top_Module" in mesh.name or "Bottom_Jeans" in mesh.name):
			continue
		for surface in mesh.mesh.get_surface_count():
			var original := mesh.get_active_material(surface)
			if original is StandardMaterial3D and ("Jacket" in original.resource_name or "Denim" in original.resource_name):
				var material := original.duplicate() as StandardMaterial3D
				material.vertex_color_use_as_albedo = false
				material.albedo_color = top if "Top_Module" in mesh.name else trousers
				mesh.set_surface_override_material(surface, material)

func _find_type(root: Node, type_name: String) -> Node:
	for child: Node in root.get_children():
		if child.is_class(type_name):
			return child
		var found := _find_type(child, type_name)
		if found != null:
			return found
	return null
