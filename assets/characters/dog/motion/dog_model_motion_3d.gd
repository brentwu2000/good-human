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

var motion := Motion.IDLE

var _model: Node3D
var _player: AnimationPlayer
var _sniff_left: float = 0.0
var _base_rotation_x: float = 0.0


func bind(target: Node3D) -> void:
	_model = target
	_base_rotation_x = _model.rotation.x
	_player = _find_player(_model)
	if _player == null:
		push_warning("DogModelMotion3D: no AnimationPlayer under " + str(_model.name))
		return
	# glTF clips arrive as one-shots; locomotion has to cycle.
	for clip_name in [IDLE_CLIP, WALK_CLIP]:
		if _player.has_animation(clip_name):
			_player.get_animation(clip_name).loop_mode = Animation.LOOP_LINEAR
	_player.play(IDLE_CLIP)


func update_motion(delta: float, speed: float, sprinting: bool) -> void:
	if _player == null:
		return
	_sniff_left = maxf(_sniff_left - delta, 0.0)
	var next := Motion.SNIFF if _sniff_left > 0.0 else Motion.IDLE
	if next != Motion.SNIFF and speed > 0.25:
		next = Motion.RUN if sprinting or speed > 4.2 else Motion.WALK
	motion = next

	# No sniff clip exists yet, so the nose-down read stays procedural: the
	# whole dog pitches forward over the idle, as the greybox version did.
	_model.rotation.x = _base_rotation_x + (0.10 if motion == Motion.SNIFF else 0.0)

	match motion:
		Motion.IDLE, Motion.SNIFF:
			_play(IDLE_CLIP, 1.0)
		Motion.WALK, Motion.RUN:
			_play(WALK_CLIP, clampf(speed / WALK_REFERENCE_SPEED, 0.6, 2.6))


func play_sniff(seconds: float = 0.85) -> void:
	_sniff_left = maxf(_sniff_left, seconds)


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
