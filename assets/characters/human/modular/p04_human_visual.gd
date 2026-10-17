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

const MODEL := preload("res://assets/characters/human/models/p04_owner/p04_owner_refined.glb")
const BONE_MAP := {"Hips": "pelvis", "Torso": "spine_03", "Head": "head", "ArmL": "upperarm_r", "ArmR": "upperarm_l", "LegL": "thigh_r", "LegR": "thigh_l"}
## Relaxed Idle / Walk on the same OwnerSkeleton (arms down, open hands).
## Every authored P-04 idle and walk holds a guard; outside a fight nobody
## should stand like a boxer. Shared by every model on this skeleton; a model
## that carries its own Idle_Relaxed (retargeted to its proportions) uses that.
## Style Bible v1 proportions of the same model (tools/art/stylize_rigged.py).
const STYLIZED_MODEL := "res://assets/characters/human/models/p04_owner/p04_owner_stylized.glb"
const RELAXED_CLIPS := preload("res://assets/characters/human/animations/p04_relaxed_clips.glb")
const RELAXED_LIBRARY: StringName = &"relaxed"
## Fighting-game style combat clips (Claude, owner request 2026-10-07;
## tools/art/make_fight_clips.py): a bladed, bouncing stance, footwork,
## strikes with weight transfer, defence and whole-body hit reactions.
const FIGHT_CLIPS := preload("res://assets/characters/human/animations/p04_fight_clips.glb")
const FIGHT_LIBRARY: StringName = &"fight"
static var _fight_library: AnimationLibrary
## Owner, 2026-10-09: Mesh2Motion's people clips (CC0), baked onto this rig by
## tools/art/retarget_mesh2motion.py — gestures and states the fight clips
## and Codex's relaxed clips do not cover (a fist-pump, picking something up,
## standing hurt, a wave).
const M2M_CLIPS := preload("res://assets/characters/human/animations/p04_m2m_clips.glb")
const M2M_LIBRARY: StringName = &"m2m"
static var _m2m_library: AnimationLibrary
static var _relaxed_library: AnimationLibrary
## Owner, 2026-10-06 (「戰鬥動作太單一」): the attacks mirrored left for right
## — the jab's rear-hand cross, the other hook, a kick off the other leg.
const MIRROR_LIBRARY: StringName = &"mirror"
const MIRRORED_CLIPS: Array[String] = ["Jab", "HeavyHook", "Kick"]
## One mirrored library per model's own clips (the grandma has hers).
static var _mirror_libraries: Dictionary = {}
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
## Owner, 2026-10-07: changes between clips blend instead of snapping. The
## pose when the clip changed, and how long is left of the blend from it.
const BLEND_SECONDS: float = 0.12
var _blend_from: Array[Quaternion] = []
var _blend_hips := Vector3.ZERO
var _blend_left: float = 0.0

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
	_add_fight_clips()
	_add_m2m_clips()
	_add_mirrored_clips()
	SoftToon.register(self)
	for joint_name: String in BONE_MAP:
		var joint := Node3D.new()
		joint.name = joint_name
		add_child(joint)
		controls[joint_name] = joint
	# After the AnimationPlayer: the clip writes its pose, then the controls.
	process_priority = 50

## Remembers the pose right now, to blend from into the next clip.
func _start_blend() -> void:
	if skeleton == null or skeleton.get_bone_count() == 0:
		return
	_blend_from.resize(skeleton.get_bone_count())
	for i in skeleton.get_bone_count():
		_blend_from[i] = skeleton.get_bone_pose_rotation(i)
	var hips := skeleton.find_bone("pelvis")
	_blend_hips = skeleton.get_bone_pose_position(hips) if hips >= 0 else Vector3.ZERO
	_blend_left = BLEND_SECONDS


func _apply_blend(delta: float) -> void:
	if _blend_left <= 0.0 or skeleton == null or _blend_from.size() != skeleton.get_bone_count():
		return
	_blend_left = maxf(_blend_left - delta, 0.0)
	var w := 1.0 - _blend_left / BLEND_SECONDS
	w = w * w * (3.0 - 2.0 * w)
	for i in skeleton.get_bone_count():
		skeleton.set_bone_pose_rotation(i, _blend_from[i].slerp(skeleton.get_bone_pose_rotation(i), w))
	var hips := skeleton.find_bone("pelvis")
	if hips >= 0:
		skeleton.set_bone_pose_position(hips, _blend_hips.lerp(skeleton.get_bone_pose_position(hips), w))


func _process(_delta: float) -> void:
	_apply_blend(_delta)
	apply_layers()


## The controls and this node's own tilt and offset over the clip's pose.
## Safe to call more than once a frame (it knows what it wrote), which the
## fight does to measure the pose people will actually see.
func apply_layers() -> void:
	# Gameplay also tilts this whole node (a blow's recoil, a stoop). Layered
	# over a clip that already leans, only `layer_weight` of that tilt is kept:
	# the model counter-rotates by the rest, root·model = root^w·yaw.
	var yaw := Quaternion(Vector3.UP, PI)
	model.quaternion = quaternion.inverse().slerp(Quaternion.IDENTITY, layer_weight) * yaw if layered else yaw
	# The same for where it puts this node (a lunge into a strike, a guard
	# pushed forward, knocked back): the fight clips step in and back
	# themselves, and both at full strength put one person inside the other.
	model.position = basis.inverse() * -position * (1.0 - layer_weight) if layered else Vector3.ZERO
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
			_source_rests[_relaxed_library] = _rest_rotations(_find_type(source, "Skeleton3D") as Skeleton3D)
		source.free()
	if _relaxed_library != null:
		player.add_animation_library(RELAXED_LIBRARY, _for_this_skeleton(_relaxed_library))


## Shared clip libraries were authored on the P-04 owner's skeleton and set each bone's own
## rotation. Every character on the OwnerSkeleton has its own rests (other proportions, other
## bone rolls: hands and forearms differ by 65–98 degrees), so played as they are, the same
## rotations twisted their wrists and bent arms the wrong way (owner, 2026-10-17: 「手部錯位」).
## Each shared library is converted once per skeleton so every bone makes the same move in
## the world (LESSONS 6.31): A = R_source⁻¹·S·R_this (global rest; S swings this bone's direction
## onto the source's), and a key L becomes A_parent⁻¹·L·A_bone.
static var _source_rests: Dictionary = {}
## Bones that are swung onto the source's direction (arms, hands, legs).
const LIMB_BONES := ["clavicle", "upperarm", "lowerarm", "hand", "index", "middle", "ring", "pinky", "thumb", "thigh", "calf", "foot", "ball"]
static var _converted: Dictionary = {}


static func _rest_rotations(sk: Skeleton3D) -> Dictionary:
	var out := {}
	if sk == null:
		return out
	for i in sk.get_bone_count():
		var g := sk.get_bone_global_rest(i)
		# The way the bone points: towards the child that continues its chain — a spine
		# towards the neck, not a shoulder (child order differs between rigs); a hand towards
		# the middle of its fingers — else its own +Y.
		var axis := g.basis.orthonormalized() * Vector3.UP
		var me := sk.get_bone_name(i)
		var sided := me.ends_with("_l") or me.ends_with("_r")
		var picks: Array[Vector3] = []
		for c in sk.get_bone_children(i):
			var cn := sk.get_bone_name(c)
			if not sided and (cn.ends_with("_l") or cn.ends_with("_r")):
				continue
			picks.append(sk.get_bone_global_rest(c).origin)
		if not picks.is_empty():
			var mid := Vector3.ZERO
			for p in picks:
				mid += p
			var to_child := mid / picks.size() - g.origin
			if to_child.length() > 0.001:
				axis = to_child.normalized()
		out[sk.get_bone_name(i)] = [g.basis.orthonormalized().get_rotation_quaternion(), axis, sk.get_bone_rest(i).basis.orthonormalized().get_rotation_quaternion()]
	return out


func _for_this_skeleton(library: AnimationLibrary) -> AnimationLibrary:
	var source: Dictionary = _source_rests.get(library, {})
	if skeleton == null or source.is_empty() or OS.get_environment("GH_NO_RETARGET") == "1":
		return library
	var mine := _rest_rotations(skeleton)
	var offset := {}
	var differs := false
	for bone: String in mine:
		if not source.has(bone):
			continue
		var r_src: Quaternion = source[bone][0]
		var r_dst: Quaternion = mine[bone][0]
		# Swing this bone's rest onto the source's direction first (its own roll kept):
		# a different rest pose (arms wider, lower) then still points each limb where the
		# clip points it, instead of offset by the rest difference.
		# Limbs only: a torso, neck or head is not a stick along its bone (a round belly
		# leans the auntie's spine back), and swinging it upright folded her forward.
		var limb := LIMB_BONES.any(func(prefix: String) -> bool: return bone.begins_with(prefix))
		var swing := Quaternion(mine[bone][1] as Vector3, source[bone][1] as Vector3) if limb else Quaternion.IDENTITY
		var a: Quaternion = r_src.inverse() * swing * r_dst
		offset[bone] = a
		differs = differs or a.angle_to(Quaternion.IDENTITY) > deg_to_rad(0.5)
	if not differs:
		return library
	# One conversion per library and skeleton shape (every character of a background shares it).
	var key := "%d:%s" % [library.get_instance_id(), str(offset.values().map(func(q: Quaternion) -> String: return "%.3f,%.3f,%.3f,%.3f" % [q.x, q.y, q.z, q.w]).hash())]
	if _converted.has(key):
		return _converted[key]
	var out := AnimationLibrary.new()
	for clip_name in library.get_animation_list():
		var clip := library.get_animation(clip_name).duplicate(true) as Animation
		for t in clip.get_track_count():
			if clip.track_get_type(t) != Animation.TYPE_ROTATION_3D:
				continue
			var bone := clip.track_get_path(t).get_concatenated_subnames()
			var index := skeleton.find_bone(bone)
			if index < 0 or not offset.has(bone):
				continue
			var parent := skeleton.get_bone_parent(index)
			var a_bone: Quaternion = offset[bone]
			var a_parent: Quaternion = offset.get(skeleton.get_bone_name(parent), Quaternion.IDENTITY) if parent >= 0 else Quaternion.IDENTITY
			for k in clip.track_get_key_count(t):
				var q: Quaternion = clip.track_get_key_value(t, k)
				clip.track_set_key_value(t, k, (a_parent.inverse() * q * a_bone).normalized())
		# Bones the clip never keys (spine_01, the clavicles, neck_01, Root) sit at their
		# rest: here that must be the source's rest, converted, or the chain bends by the
		# difference (37 degrees in the office worker's spine).
		var keyed := {}
		var prefix := ""
		for t in clip.get_track_count():
			if clip.track_get_type(t) == Animation.TYPE_ROTATION_3D:
				var path := clip.track_get_path(t)
				keyed[String(path.get_concatenated_subnames())] = true
				prefix = String(path).get_slice(":", 0)
		if not prefix.is_empty():
			for bone: String in offset:
				if keyed.has(bone):
					continue
				var index := skeleton.find_bone(bone)
				var parent := skeleton.get_bone_parent(index)
				var a_parent: Quaternion = offset.get(skeleton.get_bone_name(parent), Quaternion.IDENTITY) if parent >= 0 else Quaternion.IDENTITY
				var track := clip.add_track(Animation.TYPE_ROTATION_3D)
				clip.track_set_path(track, NodePath("%s:%s" % [prefix, bone]))
				clip.rotation_track_insert_key(track, 0.0, (a_parent.inverse() * (source[bone][2] as Quaternion) * (offset[bone] as Quaternion)).normalized())
		out.add_animation(clip_name, clip)
	_converted[key] = out
	return out


## "fight/<clip>" when the fight library has it, else "".
func fight_clip(clip: String) -> String:
	var name := "%s/%s" % [FIGHT_LIBRARY, clip]
	return name if player != null and player.has_animation(name) else ""


func _add_fight_clips() -> void:
	if player == null or player.has_animation_library(FIGHT_LIBRARY):
		return
	if _fight_library == null:
		var source := FIGHT_CLIPS.instantiate()
		var source_player := _find_type(source, "AnimationPlayer") as AnimationPlayer
		if source_player != null:
			_fight_library = source_player.get_animation_library(&"")
			_source_rests[_fight_library] = _rest_rotations(_find_type(source, "Skeleton3D") as Skeleton3D)
		source.free()
	if _fight_library != null:
		player.add_animation_library(FIGHT_LIBRARY, _for_this_skeleton(_fight_library))


func _add_m2m_clips() -> void:
	if player == null or player.has_animation_library(M2M_LIBRARY):
		return
	if _m2m_library == null:
		var source := M2M_CLIPS.instantiate()
		var source_player := _find_type(source, "AnimationPlayer") as AnimationPlayer
		if source_player != null:
			_m2m_library = source_player.get_animation_library(&"")
			_source_rests[_m2m_library] = _rest_rotations(_find_type(source, "Skeleton3D") as Skeleton3D)
		source.free()
	if _m2m_library != null:
		player.add_animation_library(M2M_LIBRARY, _for_this_skeleton(_m2m_library))


## "m2m/<clip>" when the Mesh2Motion library has it, else "".
func m2m_clip(clip: String) -> String:
	var name := "%s/%s" % [M2M_LIBRARY, clip]
	return name if player != null and player.has_animation(name) else ""


## `clip` played off the other side ("mirror/Jab"), or `clip` itself when there
## is no mirrored version.
func mirrored(clip: String) -> String:
	var name := "%s/%s" % [MIRROR_LIBRARY, clip]
	return name if player != null and player.has_animation(name) else clip


func _add_mirrored_clips() -> void:
	if player == null or player.has_animation_library(MIRROR_LIBRARY) or not player.has_animation_library(&""):
		return
	var source := player.get_animation_library(&"")
	if not _mirror_libraries.has(source):
		var library := AnimationLibrary.new()
		for clip in MIRRORED_CLIPS:
			if source.has_animation(clip):
				library.add_animation(clip, mirror_animation(source.get_animation(clip)))
		_mirror_libraries[source] = library
	player.add_animation_library(MIRROR_LIBRARY, _mirror_libraries[source])


## The rig is symmetric across its X plane (each _l bone's rest is its _r
## twin's mirrored), so a clip mirrors by swapping _l and _r tracks and
## reflecting every key: rotation (x, y, z, w) -> (x, -y, -z, w), position
## (x, y, z) -> (-x, y, z).
static func mirror_animation(source: Animation) -> Animation:
	var mirror := source.duplicate(true) as Animation
	for i in mirror.get_track_count():
		var path := String(mirror.track_get_path(i))
		var colon := path.rfind(":")
		if colon >= 0:
			var bone := path.substr(colon + 1)
			if bone.ends_with("_l"):
				bone = bone.trim_suffix("_l") + "_r"
			elif bone.ends_with("_r"):
				bone = bone.trim_suffix("_r") + "_l"
			mirror.track_set_path(i, NodePath(path.substr(0, colon + 1) + bone))
		for k in mirror.track_get_key_count(i):
			var value: Variant = mirror.track_get_key_value(i, k)
			match mirror.track_get_type(i):
				Animation.TYPE_ROTATION_3D:
					var q := value as Quaternion
					mirror.track_set_key_value(i, k, Quaternion(q.x, -q.y, -q.z, q.w))
				Animation.TYPE_POSITION_3D:
					var v := value as Vector3
					mirror.track_set_key_value(i, k, Vector3(-v.x, v.y, v.z))
	return mirror


func play_clip(clip: String, loop := true) -> void:
	legacy_driven = false
	if player == null or not player.has_animation(clip):
		return
	var animation := player.get_animation(clip)
	animation.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	if player.current_animation != clip:
		_start_blend()
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
		_start_blend()
		animation.loop_mode = Animation.LOOP_NONE
		# No cross-fade: at speed 0 a blend never advances, and the new clip
		# would never take over (it did not, until this was found measuring
		# reach). Gameplay moves the time smoothly anyway.
		player.play(clip, 0.0)
	player.speed_scale = 0.0
	# Seeking a one-shot to its very end makes the player stop and drop the
	# clip (current_animation ""), so the next frame restarts it with a blend.
	player.seek(clampf(t, 0.0, 0.999) * animation.length, true)

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
			# The model's own material: a toon override may already sit on top.
			var original := mesh.mesh.surface_get_material(surface)
			if original is StandardMaterial3D and ("Jacket" in original.resource_name or "Denim" in original.resource_name):
				var material := original.duplicate() as StandardMaterial3D
				material.vertex_color_use_as_albedo = false
				material.albedo_color = top if "Top_Module" in mesh.name else trousers
				mesh.set_surface_override_material(surface, material)
	if SoftToon.enabled:
		SoftToon.restore(self)
		SoftToon.apply(self)

func _find_type(root: Node, type_name: String) -> Node:
	for child: Node in root.get_children():
		if child.is_class(type_name):
			return child
		var found := _find_type(child, type_name)
		if found != null:
			return found
	return null
