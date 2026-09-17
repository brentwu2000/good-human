class_name OwnerBehavior
extends Node
## The owner's growth-shaped habits while following the dog: stumbling when
## dragged, getting exhausted, hesitating near unfamiliar pairs, slowing down
## under a heavy bag. Values come from HumanTraits (GrowthResolver), so a
## trained owner visibly handles the same walk better. Presentation of
## behaviour only; no stats or loot here.

signal stumbled
signal exhausted
signal hesitated(pair: OpponentPair)

## Faster than this share of walk_speed counts as being dragged.
const DRAGGED_SPEED_RATIO: float = 1.05
const STUMBLE_HOLD: float = 0.35
const MEET_DISTANCE: float = 200.0
const EXERTION_DECAY: float = 0.08
const EXERTION_AFTER_REST: float = 0.25

@export var run_manager: RunManager
@export var human: HumanFollower
@export var coordinator: CombatCoordinator

var traits: HumanTraits = HumanTraits.new()
## 0..1; exhausted at 1.
var exertion: float = 0.0
## Continuous seconds of being dragged fast.
var dragged_time: float = 0.0

var _met_pairs: Dictionary[StringName, bool] = {}


func _ready() -> void:
	run_manager.run_started.connect(_on_run_started)


func _on_run_started(_seed: int) -> void:
	refresh_traits()
	exertion = 0.0
	dragged_time = 0.0
	_met_pairs.clear()
	human.speed_multiplier = 1.0
	human.hold_time = 0.0


func refresh_traits() -> void:
	traits = GrowthResolver.traits(Game.human_growth, DataRegistry.training)


func is_dragged() -> bool:
	return human.is_following() and human.velocity.length() > human.walk_speed * DRAGGED_SPEED_RATIO


func _physics_process(delta: float) -> void:
	if not run_manager.is_running() or not human.is_following():
		dragged_time = 0.0
		return
	var heavy := run_manager.human_run_inventory.used_slot_count() >= DataRegistry.training.heavy_bag_slots
	human.speed_multiplier = traits.heavy_bag_speed if heavy else 1.0
	_check_pairs()
	if human.hold_time > 0.0:
		dragged_time = 0.0
		return

	if is_dragged():
		dragged_time += delta
		exertion += traits.exertion_gain * delta
	else:
		dragged_time = 0.0
		exertion = maxf(exertion - EXERTION_DECAY * delta, 0.0)

	if exertion >= 1.0:
		exertion = EXERTION_AFTER_REST
		human.hold_time = traits.recovery_time
		human.say("呼…呼…讓我喘一下…", Color(0.85, 0.85, 1.0), traits.recovery_time)
		human.play_growth_behavior(&"recovery", _recovery_improved(), traits.recovery_time)
		exhausted.emit()
	elif dragged_time >= traits.stumble_after:
		dragged_time = 0.0
		human.hold_time = STUMBLE_HOLD
		human.say("哇啊！", Color(1.0, 0.8, 0.6), 0.8)
		human.play_growth_behavior(&"leash", _stumble_improved(), STUMBLE_HOLD)
		stumbled.emit()


## First time the dog brings the owner near a pair this walk.
func _check_pairs() -> void:
	var dog := run_manager.dog
	if dog == null or coordinator == null:
		return
	for pair in coordinator.get_pairs():
		if not pair.is_present() or pair.state != OpponentPair.State.IDLE or _met_pairs.has(pair.spot_id):
			continue
		if dog.global_position.distance_to(pair.global_position) > MEET_DISTANCE:
			continue
		_met_pairs[pair.spot_id] = true
		if traits.hesitation_time > 0.05:
			human.hold_time = maxf(human.hold_time, traits.hesitation_time)
			human.say("要…要過去喔？", Color(0.9, 0.9, 0.9), traits.hesitation_time)
		elif traits.greets:
			human.say("你好～今天天氣不錯喔", Color(0.7, 1.0, 0.8))
		human.play_growth_behavior(&"threat", _hesitation_improved(), maxf(traits.hesitation_time, 0.45))
		hesitated.emit(pair)


func _stumble_improved() -> bool:
	var balance := DataRegistry.training
	return traits.stumble_after >= (balance.stumble_after_untrained + balance.stumble_after_trained) * 0.5


func _recovery_improved() -> bool:
	var balance := DataRegistry.training
	return traits.recovery_time <= (balance.recovery_untrained + balance.recovery_trained) * 0.5


func _hesitation_improved() -> bool:
	var balance := DataRegistry.training
	return traits.hesitation_time <= (balance.hesitation_untrained + balance.hesitation_trained) * 0.5
