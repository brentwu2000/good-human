class_name CombatAtmosphere3D
extends Node
## P03-E09 (COMBAT_ATMOSPHERE_DIRECTOR): "the world should communicate 'this
## is escalating' before the first punch". Presentation only — it reads the
## camera's beat, the fight's events and the dog, and never decides anything.
## Sound (placeholders from SfxSynth until real audio exists):
## - the street's ambience ducks as a fight builds and comes back after;
## - a restrained low heartbeat under the stand-off, fading once blows land
##   and returning when the owner is in trouble (no battle music);
## - blows: air on the swing, a light or heavy body thump, a dull block;
## - the dog: its bark, a growl when it senses danger, the leash when pulled,
##   its footsteps on the walk.
## World: people standing nearby turn to watch; the first heavy blow puts the
## birds up out of the trees; heavy blows and falls kick up a little dust.

const Context := CameraRig3D.Context
## Ambience and heartbeat loudness (dB) by the camera's beat of the fight.
const AMBIENCE_DB := {
	Context.EXPLORE: -14.0, Context.TENSION: -22.0, Context.ACTIVE: -27.0,
	Context.CRISIS: -30.0, Context.AFFECTION: -24.0, Context.RELEASE: -18.0,
}
const PULSE_DB := {Context.TENSION: -10.0, Context.ACTIVE: -30.0, Context.CRISIS: -14.0}
const SILENT_DB: float = -60.0
## People this close to a fight (m) stop and watch it.
const WATCH_RANGE: float = 12.0
## The dog's paws: one soft step every this many metres.
const STRIDE: float = 0.45

var coordinator: CombatCoordinator3D
var rig: CameraRig3D
var dog: DogController3D
var agency: Node
var instinct: DogInstinct

var _ambience: AudioStreamPlayer
var _pulse: AudioStreamPlayer
var _voices: Array[AudioStreamPlayer3D] = []
var _next_voice: int = 0
var _engagement: Engagement3D
var _watchers: Array[OpponentPair3D] = []
var _watch_left: float = 0.0
var _birds_flown: bool = false
var _growl_cooldown: float = 0.0
var _last_instinct: DogInstinct.Instinct = DogInstinct.Instinct.CALM
var _walked: float = 0.0
var _last_dog_position := Vector3.INF


func _ready() -> void:
	_ambience = _loop_player(&"ambience")
	_pulse = _loop_player(&"pulse")
	for i in 8:
		var voice := AudioStreamPlayer3D.new()
		voice.unit_size = 6.0
		voice.max_db = 3.0
		add_child(voice)
		_voices.append(voice)
	if coordinator != null:
		coordinator.engagement_started.connect(_on_engagement_started)
		coordinator.engagement_ended.connect(_on_engagement_ended)
	if agency != null:
		agency.connect(&"barked", func(_result: StringName) -> void: play(&"bark", _dog_position(), 0.0))
		agency.connect(&"pulled", func(_result: StringName) -> void: play(&"leash", _dog_position() + Vector3(0, 0.4, 0), -4.0))


func _process(delta: float) -> void:
	var context: Context = rig.context if rig != null else Context.EXPLORE
	_ambience.volume_db = lerpf(_ambience.volume_db, AMBIENCE_DB.get(context, -14.0), minf(delta * 1.5, 1.0))
	_pulse.volume_db = lerpf(_pulse.volume_db, PULSE_DB.get(context, SILENT_DB), minf(delta * 1.2, 1.0))
	_dog_sounds(delta)
	_keep_watching(delta)


## Plays `sound` once at `at` (world), `gain_db` louder or softer.
func play(sound: StringName, at: Vector3, gain_db: float = 0.0) -> void:
	var voice := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	voice.stream = SfxSynth.get_sound(sound)
	voice.volume_db = gain_db
	voice.pitch_scale = randf_range(0.93, 1.07)
	voice.global_position = at
	voice.play()


func _loop_player(sound: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = SfxSynth.get_sound(sound)
	player.volume_db = SILENT_DB
	player.autoplay = true
	add_child(player)
	return player


# --- The fight ----------------------------------------------------------------

func _on_engagement_started(engagement: Engagement3D) -> void:
	_engagement = engagement
	_birds_flown = false
	engagement.simulation.combat_event.connect(_on_combat_event)
	# Anyone standing near stops to watch.
	_watchers.clear()
	var centre := _fight_centre()
	for pair in coordinator.get_pairs():
		if pair != engagement.pair and pair.is_present() and pair.human_global_position().distance_to(centre) < WATCH_RANGE:
			_watchers.append(pair)
	_watch_left = 0.0


func _on_engagement_ended(_engagement_ended: Engagement3D, _result: CombatSimulation.Result) -> void:
	_engagement = null
	_watchers.clear()


func _on_combat_event(kind: StringName, side: int, skill: CombatSkillData, _amount: float) -> void:
	if _engagement == null:
		return
	var attacker := _fighter_position(side)
	var target := _fighter_position(1 - side)
	match kind:
		&"strike":
			play(&"whoosh", attacker + Vector3(0, 1.2, 0), -6.0 if skill != null and not skill.is_heavy() else -2.0)
		&"hit":
			var heavy := skill != null and skill.is_heavy()
			play(&"impact_heavy" if heavy else &"impact_light", target + Vector3(0, 1.1, 0), 0.0)
			if heavy:
				_dust(target)
				_put_up_birds()
		&"blocked":
			play(&"block", target + Vector3(0, 1.2, 0), -3.0)
		&"defeated":
			play(&"impact_heavy", _fighter_position(side) + Vector3(0, 0.5, 0), 2.0)
			_dust(_fighter_position(side))


func _fighter_position(side: int) -> Vector3:
	if _engagement == null:
		return Vector3.ZERO
	if side == CombatSimulation.PLAYER:
		return coordinator.human.global_position
	return _engagement.pair.human_global_position()


func _fight_centre() -> Vector3:
	return (_fighter_position(CombatSimulation.PLAYER) + _fighter_position(CombatSimulation.OPPONENT)) * 0.5


## Watchers keep their eyes on it while it lasts.
func _keep_watching(delta: float) -> void:
	if _engagement == null or _watchers.is_empty():
		return
	_watch_left -= delta
	if _watch_left > 0.0:
		return
	_watch_left = 0.4
	var centre := _fight_centre()
	for pair in _watchers:
		if is_instance_valid(pair) and pair.human_puppet != null:
			pair.human_puppet.face_towards(centre)


# --- The dog --------------------------------------------------------------------

func _dog_position() -> Vector3:
	return dog.global_position if dog != null else Vector3.ZERO


func _dog_sounds(delta: float) -> void:
	if dog == null:
		return
	# Paws on the pavement.
	var here := dog.global_position
	if _last_dog_position != Vector3.INF:
		_walked += Vector2(here.x - _last_dog_position.x, here.z - _last_dog_position.z).length()
		if _walked >= STRIDE:
			_walked = 0.0
			play(&"step", here, -16.0)
	_last_dog_position = here
	# A growl the moment it senses danger to its human (dog instinct before UI).
	_growl_cooldown = maxf(_growl_cooldown - delta, 0.0)
	if instinct != null:
		if instinct.state == DogInstinct.Instinct.THREAT and _last_instinct != DogInstinct.Instinct.THREAT and _growl_cooldown <= 0.0:
			play(&"growl", here + Vector3(0, 0.4, 0), -4.0)
			_growl_cooldown = 4.0
		_last_instinct = instinct.state


# --- The world --------------------------------------------------------------------

## The first heavy blow of a fight puts the birds up.
func _put_up_birds() -> void:
	if _birds_flown:
		return
	_birds_flown = true
	var from := _fight_centre() + Vector3(randf_range(-4.0, 4.0), 3.5, randf_range(-4.0, 4.0))
	play(&"birds", from, -2.0)
	for i in 6:
		var bird := Greybox.box(Vector3(0.12, 0.03, 0.06), Color(0.15, 0.15, 0.17), from + Vector3(randf_range(-0.8, 0.8), randf_range(-0.3, 0.3), randf_range(-0.8, 0.8)))
		bird.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		get_parent().add_child(bird)
		var away := Vector3(randf_range(-6.0, 6.0), randf_range(5.0, 9.0), randf_range(-6.0, 6.0))
		var tween := bird.create_tween()
		tween.tween_property(bird, "global_position", bird.global_position + away, randf_range(1.2, 1.8)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(bird, "scale", Vector3(1.0, 1.0, 1.0) * 0.4, 1.6)
		tween.tween_callback(bird.queue_free)


## A little dust at someone's feet: low, thin, gone in half a second.
func _dust(at: Vector3) -> void:
	for i in 4:
		var puff := Greybox.sphere(0.05, Color(0.66, 0.62, 0.55), Vector3(at.x, 0.04, at.z) + Vector3(randf_range(-0.22, 0.22), 0.0, randf_range(-0.22, 0.22)))
		puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var haze := StandardMaterial3D.new()
		haze.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		haze.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		haze.albedo_color = Color(0.66, 0.62, 0.55, 0.35)
		puff.material_override = haze
		puff.scale = Vector3(1.0, 0.45, 1.0)
		get_parent().add_child(puff)
		var tween := puff.create_tween()
		tween.tween_property(puff, "scale", Vector3(2.2, 0.9, 2.2), 0.5).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(haze, "albedo_color:a", 0.0, 0.5)
		tween.tween_callback(puff.queue_free)
