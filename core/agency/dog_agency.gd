class_name DogAgency
extends Node
## Sprint 04 (ADR-011): the dog stays meaningfully active during seamless
## fights through its body in the world, not QTE prompts.
## - Bark: an attention event. Near the fight and roughly facing the opponent,
##   from anywhere not hidden behind the owner, it makes the opponent look away:
##   the owner seizes the opening at once for extra damage. Right behind the
##   owner it startles the owner instead. Quick repeats lose effect.
## - Leash pull: running away past the leash length yanks the owner. Pulling
##   away or sideways repositions them (dodging an attack being wound up);
##   only dragging them towards the opponent makes them stumble; a strong
##   sustained pull away drags them out of the fight.
## Every consequence is announced (`outcome`) so players can learn it.
## Hidden numbers are debug-only. Training goes through TrainingObserver.

signal barked(result: StringName)
signal pulled(result: StringName)
## Player-facing consequence, so cause and effect can be learned.
signal outcome(text: String, positive: bool)
## For TrainingObserver: a meaningful dog-agency moment.
signal training_moment(event_id: StringName, key: StringName)

enum BarkResult { NONE, DISTRACTED, IGNORED, STARTLED_OWNER, UNHEARD, SOCIAL }

const BARK_COOLDOWN: float = 0.6
## Meters.
const BARK_RANGE: float = 6.0
## Dog must roughly face the opponent (degrees).
const BARK_FACING_ANGLE: float = 110.0
## Seen from the opponent, a dog within this angle of the owner is "behind the
## owner" (degrees): the bark isn't useful there.
const BARK_SIDE_ANGLE: float = 25.0
## ...and only startles the owner when the dog is this close to them (m).
const BARK_STARTLE_DISTANCE: float = 1.5
const BARK_DISTRACT_SECONDS: float = 0.7
const BARK_OWNER_STARTLE_SECONDS: float = 0.4
## Each bark in this window halves the next one's effect, so only the first of
## a burst is a full distraction and the third is ignored. Wait it out and the
## next bark lands fully again.
const BARK_RESIST_WINDOW: float = 8.0
## On top of that, an opponent gets used to a dog over one fight: every bark
## they have already heard shrinks the next one. Waiting does not undo this, so
## a fight allows a handful of useful barks, not an endless stream.
const BARK_HABITUATION: float = 0.75
const BARK_MIN_EFFECT: float = 0.3
## A yank is a rescue, not a stance: the owner has to find their feet again
## before the leash can save them a second time.
const PULL_COOLDOWN: float = 3.0
## Meters past the leash length before a pull happens.
const PULL_SLACK: float = 0.3
const PULL_MIN_DOG_SPEED: float = 1.0
## Pulls pointing towards the opponent below this share (dragging the owner
## into the fight) make them stumble; everything else repositions.
const PULL_INTO_FIGHT_SHARE: float = -0.3
## A drag-out needs the pull to point mostly away from the opponent.
const PULL_AWAY_SHARE: float = 0.5
const PULL_DISTANCE: float = 0.7
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
## Barks the current opponent has already heard (habituation).
var barks_heard: int = 0

var _time: float = 0.0
var _bark_ready_at: float = 0.0
var _pull_ready_at: float = 0.0
var _drag_out_time: float = 0.0


func _ready() -> void:
	run_manager.run_started.connect(func(_s: int) -> void: _reset())
	coordinator.engagement_started.connect(func(_e: Engagement3D) -> void: barks_heard = 0)


func _reset() -> void:
	last_bark = BarkResult.NONE
	last_pull = &""
	recent_barks.clear()
	barks_heard = 0
	_bark_ready_at = 0.0
	_pull_ready_at = 0.0
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
		outcome.emit("…太遠或沒對著對手叫", false)
		return BarkResult.UNHEARD
	var at_opponent := rad_to_deg(_flat(dog.global_position - opponent_position).angle_to(_flat(human.global_position - opponent_position)))
	if at_opponent < BARK_SIDE_ANGLE:
		if _flat(dog.global_position - human.global_position).length() <= BARK_STARTLE_DISTANCE:
			# Right behind your own human: they're the one who jumps.
			engagement.simulation.distract(CombatSimulation.PLAYER, BARK_OWNER_STARTLE_SECONDS)
			human.say("哇！你叫什麼啦！", Color(1.0, 0.8, 0.6), 1.0)
			outcome.emit("✘ 在主人背後叫，嚇到自己人了", false)
			return BarkResult.STARTLED_OWNER
		outcome.emit("…主人擋住了，對方沒注意到", false)
		return BarkResult.UNHEARD
	var effect := _bark_effect()
	if effect < BARK_MIN_EFFECT:
		opponent.human_puppet.shout("（不理你）", Color(0.8, 0.8, 0.8))
		outcome.emit("…叫太多次，對方不理你了", false)
		return BarkResult.IGNORED
	engagement.simulation.distract(CombatSimulation.OPPONENT, BARK_DISTRACT_SECONDS * effect)
	opponent.human_puppet.shout("什麼？！", Color(1.0, 0.9, 0.5))
	human.say("好機會！", Color(0.7, 1.0, 0.7), 0.8)
	outcome.emit("✦ 對手分心了！主人抓到破綻", true)
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


## 1.0 for the first bark of a fight, halved for each bark still in the
## resistance window and shrunk once more for every bark this opponent has
## already heard.
func _bark_effect() -> float:
	while not recent_barks.is_empty() and _time - recent_barks[0] > BARK_RESIST_WINDOW:
		recent_barks.pop_front()
	var effect := pow(0.5, recent_barks.size()) * pow(BARK_HABITUATION, barks_heard)
	recent_barks.append(_time)
	barks_heard += 1
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
			outcome.emit("✦ 把主人拖出戰鬥了", true)
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
	if away_share < PULL_INTO_FIGHT_SHARE:
		sim.stumble(CombatSimulation.PLAYER, PULL_STUMBLE_SECONDS)
		human.say("別扯啦！", Color(1.0, 0.7, 0.6), 0.9)
		last_pull = &"stumbled"
		outcome.emit("✘ 把主人往對手身上扯，踉蹌了", false)
		training_moment.emit(&"agency_bad_pull", engagement.pair.spot_id)
	elif sim.pull(CombatSimulation.PLAYER, PULL_DISTANCE * CombatCoordinator3D.UNITS_PER_METER):
		human.say("哇！差點被打到！", Color(0.7, 1.0, 0.8), 1.0)
		last_pull = &"saved"
		outcome.emit("✦ 把主人拉開，躲過一招！", true)
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
	return "Agency: bark %s  resist %d  heard %d  pull %s  leash %.2f" % [BarkResult.keys()[last_bark], recent_barks.size(), barks_heard, last_pull, tension]
