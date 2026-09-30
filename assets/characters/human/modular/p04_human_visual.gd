class_name P04HumanVisual
extends Node3D
## Opt-in Blender candidate. Seven legacy controls remain real Node3D nodes.
##
## Three ways to drive it:
## - `play_clip`: an authored clip at its own speed (walking, idling, Down).
## - `pose_clip`: an authored clip held at a chosen point, so gameplay can put
##   its peak exactly where the fight's contact window opens.
## - The seven controls. `use_legacy_controls` (the ART review scene) poses
##   the rest skeleton with them alone; `use_clip_layer` adds them on top of
##   whatever clip is playing, at a weight, so gameplay accents (a head snap, a
##   hook's twist, breathing) layer over the authored motion.

const MODEL := preload("res://assets/characters/human/models/p04_owner/p04_owner.glb")
const BONE_MAP := {"Hips": "pelvis", "Torso": "spine_03", "Head": "head", "ArmL": "upperarm_r", "ArmR": "upperarm_l", "LegL": "thigh_r", "LegR": "thigh_l"}
var skeleton: Skeleton3D
var player: AnimationPlayer
var model: Node3D
var legacy_driven := false
## Controls added on top of the playing clip, and how strongly (0..1).
var layered := false
var layer_weight := 0.0
## Per bone: what this layer last wrote, and the clip pose it was added to.
var _written: Dictionary = {}
var _clip_base: Dictionary = {}
var controls: Dictionary = {}

## `scene`: another model on the same OwnerSkeleton (FighterData.skeletal_model);
## null = the shared P-04 human.
func _init(scene: PackedScene = null) -> void:
	name = "P04HumanCandidate"
	set_meta("skeletal_art", true)
	model = (scene if scene != null else SoftToon.pick(MODEL, STYLIZED_MODEL)).instantiate()
	model.rotation.y = PI
	add_child(model)
	skeleton = _find_type(model, "Skeleton3D") as Skeleton3D
	player = _find_type(model, "AnimationPlayer") as AnimationPlayer
	_add_relaxed_clips()
	SoftToon.register(self)
	for joint_name: String in BONE_MAP:
		var joint := Node3D.new()
		joint.name = joint_name
		add_child(joint)
		controls[joint_name] = joint
	# After the AnimationPlayer: the clip writes its pose, then the controls.
	process_priority = 50

func _process(_delta: float) -> void:
	# Gameplay also tilts this whole node (a blow's recoil, a stoop). Layered
	# over a clip that already leans, only `layer_weight` of that tilt is kept:
	# the model counter-rotates by the rest, root·model = root^w·yaw.
	var yaw := Quaternion(Vector3.UP, PI)
	model.quaternion = quaternion.inverse().slerp(Quaternion.IDENTITY, layer_weight) * yaw if layered else yaw
	if skeleton == null or not (legacy_driven or layered):
		return
	for joint_name: String in BONE_MAP:
		var index := skeleton.find_bone(BONE_MAP[joint_name])
		if index < 0:
			continue
		var control: Node3D = controls[joint_name]
		var turn := control.basis.orthonormalized()
		var base := skeleton.get_bone_rest(index).basis.orthonormalized()
		if layered:
			# The clip's pose this frame is the base — but only if the clip
			# actually wrote this bone. Godot's import drops tracks that never
			# change (the pelvis, in most clips), so a bone can still hold what
			# this layer wrote last frame; taking that as the base again made
			# the layer add onto itself every frame and the pelvis drifted to
			# 90–160° (the owner leaning back, a fighter turned on their side).
			var current := skeleton.get_bone_pose_rotation(index)
			var clip_pose := current
			if _written.has(index) and current.is_equal_approx(_written[index]):
				clip_pose = _clip_base[index]
			_clip_base[index] = clip_pose
			base = Basis(clip_pose)
			turn = Basis(Quaternion.IDENTITY.slerp(turn.get_rotation_quaternion(), layer_weight))
		# The control is a rotation in this node's frame, turning the bone about
		# its own joint. With the parent's global rest P and the bone's local
		# pose L: global G = P·L, turned G' = C·G, so the new local pose is
		# P⁻¹·C·P·L. (Integration fix: the first version dropped L and P, and a
		# 0.5 rad control turned the head bone by 0.06 rad.)
		var parent := skeleton.get_bone_parent(index)
		var parent_rest := model.basis * (skeleton.get_bone_global_rest(parent).basis if parent >= 0 else Basis.IDENTITY)
		parent_rest = parent_rest.orthonormalized()
		var posed := (parent_rest.inverse() * turn * parent_rest * base).get_rotation_quaternion()
		skeleton.set_bone_pose_rotation(index, posed)
		_written[index] = posed

## The clip for standing or walking outside a fight: relaxed when available.
func ambient_clip(moving: bool) -> String:
	var own := "Walk_Relaxed" if moving else "Idle_Relaxed"
	if player != null and player.has_animation(own):
		return own
	var shared := "%s/%s" % [RELAXED_LIBRARY, own]
	if player != null and player.has_animation(shared):
		return shared
	return "Walk" if moving else "Idle"


func _add_relaxed_clips() -> void:
	if player == null or player.has_animation("Idle_Relaxed") or player.has_animation_library(RELAXED_LIBRARY):
		return
	if _relaxed_library == null:
		var source := RELAXED_CLIPS.instantiate()
		var source_player := _find_type(source, "AnimationPlayer") as AnimationPlayer
		if source_player != null:
			_relaxed_library = source_player.get_animation_library(&"")
		source.free()
	if _relaxed_library != null:
		player.add_animation_library(RELAXED_LIBRARY, _relaxed_library)


func play_clip(clip: String, loop := true) -> void:
	legacy_driven = false
	if player == null or not player.has_animation(clip):
		return
	var animation := player.get_animation(clip)
	animation.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	player.speed_scale = 1.0
	player.play(clip, 0.12)
	# A one-shot clip stops rewriting the pose when it ends; layering over it
	# would then accumulate, so it plays alone.
	if not loop:
		layered = false

## Holds `clip` at `t` (0..1 of its length). Called every frame by gameplay,
## which owns the timing; blends in when the clip changes.
func pose_clip(clip: String, t: float) -> void:
	legacy_driven = false
	if player == null or not player.has_animation(clip):
		return
	var animation := player.get_animation(clip)
	if player.current_animation != clip:
		animation.loop_mode = Animation.LOOP_NONE
		# No cross-fade: at speed 0 a blend never advances, and the new clip
		# would never take over (it did not, until this was found measuring
		# reach). Gameplay moves the time smoothly anyway.
		player.play(clip, 0.0)
	player.speed_scale = 0.0
	player.seek(clampf(t, 0.0, 1.0) * animation.length, true)

## Controls on top of the playing clip, at `weight` (0..1).
func use_clip_layer(weight: float) -> void:
	legacy_driven = false
	layered = true
	layer_weight = clampf(weight, 0.0, 1.0)

func use_legacy_controls() -> void:
	if player != null:
		player.stop()
	if skeleton != null:
		skeleton.reset_bone_poses()
	layered = false
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
