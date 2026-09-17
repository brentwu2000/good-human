class_name DogAgency
extends Node
## Sprint 04 (ADR-011): the dog stays meaningfully active during seamless
## fights through its body in the world, not QTE prompts.
## - Bark: an attention event. Near the fight, from a useful side and facing
##   the opponent, it makes the opponent look away (an opening). From behind
##   the owner it startles the owner instead. Repeats quickly lose effect.
## - Leash pull: running away past the leash length yanks the owner. Pulling
##   away from the opponent moves them (out of an incoming attack if timed);
##   pulling sideways or towards the fight knocks them off balance; a strong
##   sustained pull drags them out of the fight.
## Hidden numbers are debug-only. Training goes through TrainingObserver.

signal barked(result: StringName)
signal pulled(result: StringName)
## For TrainingObserver: a meaningful dog-agency moment.
signal training_moment(event_id: StringName, key: StringName)

enum BarkResult { NONE, DISTRACTED, IGNORED, STARTLED_OWNER, UNHEARD, SOCIAL }

const BARK_COOLDOWN: float = 0.6
## Meters.
const BARK_RANGE: float = 5.0
## Dog must roughly face the opponent (degrees).
const BARK_FACING_ANGLE: float = 75.0
## At the opponent, dog and owner must be at least this far apart (degrees):
## a bark from the owner's side isn't "useful direction".
const BARK_SIDE_ANGLE: float = 50.0
const BARK_DISTRACT_SECONDS: float = 0.9
const BARK_OWNER_STARTLE_SECONDS: float = 0.4
## Each bark in this window halves the next one's effect.
const BARK_RESIST_WINDOW: float = 6.0
const BARK_MIN_EFFECT: float = 0.3
const PULL_COOLDOWN: float = 1.0
## Meters past the leash length before a pull happens.
const PULL_SLACK: float = 0.3
const PULL_MIN_DOG_SPEED: float = 1.0
## Share of the pull that must point away from the opponent to be a good pull.
const PULL_AWAY_SHARE: float = 0.5
const PULL_DISTANCE: float = 0.7
## Two good pulls closer than this become a stumble.
const PULL_REPEAT_STUMBLE: float = 1.6
const PULL_STUMBLE_SECONDS: float = 0.6
## Sustained strong pull (meters past the leash, seconds) drags the owner out.
const DRAG_OUT_EXTRA: float = 1.5
const DRAG_OUT_SECONDS: float = 1.2

@export var run_manager: RunManager
@export var dog: DogController3D
@export var human: HumanFollower3D
@export var coordinator: CombatCoordinator3D

var last_bark: BarkResult = BarkResult.NONE
var last_pull: StringName = &""
## Times of recent barks (resistance).
var recent_barks: Array[float] = []

var _time: float = 0.0
var _bark_ready_at: float = 0.0
var _pull_ready_at: float = 0.0
var _last_good_pull: float = -INF
var _drag_out_time: float = 0.0


func _ready() -> void:
	run_manager.run_started.connect(func(_s: int) -> void: _reset())


func _reset() -> void:
	last_bark = BarkResult.NONE
	last_pull = &""
	recent_barks.clear()
	_bark_ready_at = 0.0
	_pull_ready_at = 0.0
	_last_good_pull = -INF
	_drag_out_time = 0.0


func _physics_process(delta: float) -> void:
	_time += delta
	if not run_manager.is_running():
		return
	if Input.is_action_just_pressed("bark"):
		bark()
	_update_leash(delta)


# --- Bark --------------------------------------------------------------------------

## Returns what the bark did.
func bark() -> BarkResult:
	if not run_manager.is_running() or _time < _bark_ready_at:
		return BarkResult.NONE
	_bark_ready_at = _time + BARK_COOLDOWN
	dog.play_bark()
	var result := _bark_in_fight() if coordinator.is_fighting() else _bark_in_world()
	last_bark = result
	barked.emit(BarkResult.keys()[result].to_lower())
	return result


func _bark_in_fight() -> BarkResult:
	var engagement := coordinator.engagement
	var opponent := engagement.pair
	opponent.react_to_bark(dog.global_position)
	var opponent_position := opponent.human_global_position()
	var to_opponent := _flat(opponent_position - dog.global_position)
	if to_opponent.length() > BARK_RANGE or rad_to_deg(dog.facing.angle_to(to_opponent.normalized())) > BARK_FACING_ANGLE:
		return BarkResult.UNHEARD
	var at_opponent := rad_to_deg(_flat(dog.global_position - opponent_position).angle_to(_flat(human.global_position - opponent_position)))
	if at_opponent < BARK_SIDE_ANGLE:
		# From behind your own human: they're the one who jumps.
		engagement.simulation.distract(CombatSimulation.PLAYER, BARK_OWNER_STARTLE_SECONDS)
		human.say("哇！你叫什麼啦！", Color(1.0, 0.8, 0.6), 1.0)
		return BarkResult.STARTLED_OWNER
	var effect := _bark_effect()
	if effect < BARK_MIN_EFFECT:
		opponent.human_puppet.shout("（不理你）", Color(0.8, 0.8, 0.8))
		return BarkResult.IGNORED
	engagement.simulation.distract(CombatSimulation.OPPONENT, BARK_DISTRACT_SECONDS * effect)
	opponent.human_puppet.shout("什麼？！", Color(1.0, 0.9, 0.5))
	training_moment.emit(&"agency_bark_distract", opponent.spot_id)
	return BarkResult.DISTRACTED


## Outside a fight: nearby pairs' dogs answer; the owner shushes.
func _bark_in_world() -> BarkResult:
	var answered := false
	for pair in coordinator.get_pairs():
		if pair.is_present() and dog.global_position.distance_to(pair.global_position) <= BARK_RANGE:
			pair.react_to_bark(dog.global_position)
			answered = true
	if answered and human.is_following():
		human.say("噓！別亂叫", Color(0.9, 0.9, 0.9), 1.0)
	return BarkResult.SOCIAL if answered else BarkResult.UNHEARD


## 1.0 for a fresh bark, halved for each bark in the resistance window.
func _bark_effect() -> float:
	while not recent_barks.is_empty() and _time - recent_barks[0] > BARK_RESIST_WINDOW:
		recent_barks.pop_front()
	var effect := pow(0.5, recent_barks.size())
	recent_barks.append(_time)
	return effect


# --- Leash ----------------------------------------------------------------------------

func _update_leash(delta: float) -> void:
	if not coordinator.is_fighting() or human.state != HumanFollower3D.State.COMBAT:
		_drag_out_time = 0.0
		return
	var engagement := coordinator.engagement
	var to_dog := _flat(dog.global_position - human.global_position)
	var over := to_dog.length() - human.max_length
	var dog_velocity := _flat(dog.velocity)
	var moving_away := dog_velocity.length() >= PULL_MIN_DOG_SPEED and dog_velocity.dot(to_dog.normalized()) > 0.0
	if over < PULL_SLACK or not moving_away:
		_drag_out_time = 0.0
		return
	var fight_axis := _flat(engagement.pair.human_global_position() - human.global_position).normalized()
	var away_share := -to_dog.normalized().dot(fight_axis)

	# A long hard pull away drags the owner out of the fight.
	if over >= DRAG_OUT_EXTRA and away_share >= PULL_AWAY_SHARE:
		_drag_out_time += delta
		if _drag_out_time >= DRAG_OUT_SECONDS:
			_drag_out_time = 0.0
			last_pull = &"escaped"
			training_moment.emit(&"agency_pull_escape", engagement.pair.spot_id)
			pulled.emit(last_pull)
			engagement.simulation.disengage()
			return
	else:
		_drag_out_time = 0.0

	if _time < _pull_ready_at:
		return
	_pull_ready_at = _time + PULL_COOLDOWN
	var sim := engagement.simulation
	if away_share < PULL_AWAY_SHARE or _time - _last_good_pull < PULL_REPEAT_STUMBLE:
		sim.stumble(CombatSimulation.PLAYER, PULL_STUMBLE_SECONDS)
		human.say("別扯啦！", Color(1.0, 0.7, 0.6), 0.9)
		last_pull = &"stumbled"
		training_moment.emit(&"agency_bad_pull", engagement.pair.spot_id)
	else:
		_last_good_pull = _time
		if sim.pull(CombatSimulation.PLAYER, PULL_DISTANCE * CombatCoordinator3D.UNITS_PER_METER):
			human.say("哇！差點被打到！", Color(0.7, 1.0, 0.8), 1.0)
			last_pull = &"saved"
			training_moment.emit(&"agency_pull_save", engagement.pair.spot_id)
		else:
			last_pull = &"repositioned"
	pulled.emit(last_pull)


func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


## Debug overlay line (numbers never shown to players).
func debug_text() -> String:
	var tension := 0.0
	if human != null and dog != null:
		tension = _flat(dog.global_position - human.global_position).length() / human.max_length
	return "Agency: bark %s  resist %d  pull %s  leash %.2f" % [BarkResult.keys()[last_bark], recent_barks.size(), last_pull, tension]
