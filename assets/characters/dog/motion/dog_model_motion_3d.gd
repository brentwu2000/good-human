class_name DogModelMotion3D
extends Node
## Locomotion for the generated shiba: picks a baked clip and a playback rate
## from the movement state. Same interface as DogMotion3D, which drives the
## code-built greybox dog, so DogController3D can hold either.
## Changes animation state only — never movement, collision or game rules.

enum Motion { IDLE, WALK, RUN, SNIFF }

const IDLE_CLIP: String = "Idle"
const WALK_CLIP: String = "Walk"
const SIT_CLIP: String = "Sit"
## The walk cycle covers one stride per loop; this is the ground speed that
## looks right at 1x, so faster movement speeds the same clip up.
const WALK_REFERENCE_SPEED: float = 1.9
const BLEND: float = 0.18
## Owner, 2026-10-09 (「好的，狗的部分也要使用」): Mesh2Motion's fox clips
## (CC0), baked onto each dog model by tools/art/retarget_mesh2motion.py, one
## library per model so every breed keeps its own size. Played where the
## model's own three clips (Idle, Walk, Sit) had nothing: a run, a nose to the
## ground, a bark, an alert stance.
const EXTRA_DIR: String = "res://assets/characters/dog/animations/m2m/"
const EXTRA_LIBRARY: StringName = &"m2m"
const RUN_CLIP: String = "m2m/M2M_Run"
const SNIFF_CLIP: String = "m2m/M2M_Fetch"
const BARK_CLIP: String = "m2m/M2M_Bark"
const ALERT_CLIP: String = "m2m/M2M_Alert"
## One run cycle covers this much ground at 1x.
const RUN_REFERENCE_SPEED: float = 4.6
## The bark clip barks several times; the game's bark is one, so it plays fast
## and only its first part.
const BARK_RATE: float = 2.2
const BARK_SECONDS: float = 0.55

var motion := Motion.IDLE

var _model: Node3D
var _player: AnimationPlayer
var _sniff_left: float = 0.0
var _bark_left: float = 0.0
var _alert: bool = false
var _base_rotation_x: float = 0.0


func bind(target: Node3D) -> void:
	_model = target
	_base_rotation_x = _model.rotation.x
	_player = _find_player(_model)
	if _player == null:
		push_warning("DogModelMotion3D: no AnimationPlayer under " + str(_model.name))
		return
	_add_extra_clips()
	# glTF clips arrive as one-shots; locomotion has to cycle.
	for clip_name in [IDLE_CLIP, WALK_CLIP, RUN_CLIP, ALERT_CLIP]:
		if _player.has_animation(clip_name):
			_player.get_animation(clip_name).loop_mode = Animation.LOOP_LINEAR
	_player.play(IDLE_CLIP)


func update_motion(delta: float, speed: float, sprinting: bool) -> void:
	if _player == null:
		return
	_sniff_left = maxf(_sniff_left - delta, 0.0)
	_bark_left = maxf(_bark_left - delta, 0.0)
	var next := Motion.SNIFF if _sniff_left > 0.0 else Motion.IDLE
	if next != Motion.SNIFF and speed > 0.25:
		next = Motion.RUN if sprinting or speed > 4.2 else Motion.WALK
	motion = next

	# Without the sniff clip the nose-down read is procedural: the whole dog
	# pitches forward over the idle, as the greybox version did.
	var has_sniff := _player.has_animation(SNIFF_CLIP)
	_model.rotation.x = _base_rotation_x + (0.10 if motion == Motion.SNIFF and not has_sniff else 0.0)

	if _bark_left > 0.0 and motion != Motion.RUN and _player.has_animation(BARK_CLIP):
		_play(BARK_CLIP, BARK_RATE)
		return
	match motion:
		Motion.SNIFF:
			_play(SNIFF_CLIP if has_sniff else IDLE_CLIP, 1.0)
		Motion.IDLE:
			_play(ALERT_CLIP if _alert and _player.has_animation(ALERT_CLIP) else IDLE_CLIP, 1.0)
		Motion.WALK:
			_play(WALK_CLIP, clampf(speed / WALK_REFERENCE_SPEED, 0.6, 2.6))
		Motion.RUN:
			if _player.has_animation(RUN_CLIP):
				_play(RUN_CLIP, clampf(speed / RUN_REFERENCE_SPEED, 0.7, 1.8))
			else:
				_play(WALK_CLIP, clampf(speed / WALK_REFERENCE_SPEED, 0.6, 2.6))


func play_sniff(seconds: float = 0.85) -> void:
	_sniff_left = maxf(_sniff_left, seconds)
	# The nose goes down from the start of the clip each time.
	if _player != null and _player.current_animation == SNIFF_CLIP:
		_player.seek(0.0, true)


## A bark in the body: head up and the bark, once.
func play_bark() -> void:
	_bark_left = BARK_SECONDS
	if _player != null and _player.current_animation == BARK_CLIP:
		_player.seek(0.0, true)


## Standing alert (danger to its human): the alert stance instead of the idle.
func set_alert(on: bool) -> void:
	_alert = on


func _add_extra_clips() -> void:
	if _player.has_animation_library(EXTRA_LIBRARY):
		return
	var path := EXTRA_DIR + _model_file().get_file().get_basename().trim_suffix("_stylized") + ".glb"
	if not ResourceLoader.exists(path):
		return
	var source := (load(path) as PackedScene).instantiate()
	var source_player := _find_player(source)
	var skeleton := _find_skeleton(_model)
	if source_player == null or skeleton == null:
		source.free()
		return
	# Point every track at this model's skeleton, whatever its node is called.
	var root := _player.get_node(_player.root_node)
	var to_skeleton := root.get_path_to(skeleton)
	var library := AnimationLibrary.new()
	var shared := source_player.get_animation_library(&"")
	for clip_name in shared.get_animation_list():
		var clip := shared.get_animation(clip_name).duplicate() as Animation
		for track in clip.get_track_count():
			var bone := clip.track_get_path(track).get_concatenated_subnames()
			clip.track_set_path(track, NodePath("%s:%s" % [to_skeleton, bone]))
		library.add_animation(clip_name, clip)
	source.free()
	_player.add_animation_library(EXTRA_LIBRARY, library)


func _model_file() -> String:
	return _model.scene_file_path


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null


## The sit clip runs once and holds. Nothing calls this yet; it is the hook for
## whatever decides the dog should sit.
func play_sit() -> void:
	if _player != null and _player.has_animation(SIT_CLIP):
		_player.play(SIT_CLIP, BLEND)


func _play(clip_name: String, rate: float) -> void:
	if not _player.has_animation(clip_name):
		return
	_player.speed_scale = rate
	if _player.current_animation != clip_name:
		_player.play(clip_name, BLEND)


func _find_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_player(child)
		if found != null:
			return found
	return null
