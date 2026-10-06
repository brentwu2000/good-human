class_name TemptationDirector
extends Node
## Sprint 05 (P4-003): once the player could have gone home, notice what the
## world is still offering and say so — so that staying out is a choice the
## player makes, not a punishment the walk springs on them (ADR-013).
##
## It reads the world and the run's value; it never changes run rules, spawns
## content, blocks extraction or moves the dog. Everything it offers is already
## out there. Nothing is guaranteed: a walk with nothing at stake, or a quiet
## world, is offered nothing at all.
##
## Works in 2D and 3D: cues, squirrels, pairs and search points are found by
## group and used through their shared methods.

signal offered(temptation: TemptationData)
signal expired(temptation: TemptationData)

## Rolled once each time an offer could be made, so temptation stays occasional.
const OFFER_CHANCE: float = 0.55
## Nothing is offered in the first moments after going home becomes possible;
## the player should get to feel the choice before being nudged.
const FIRST_OFFER_DELAY: float = 6.0
## Gap between offers, on top of each template's own cooldown.
const BETWEEN_OFFERS: float = 30.0

@export var run_manager: RunManager
## CombatCoordinator or CombatCoordinator3D (optional; pairs are a temptation).
@export var coordinator: Node
@export var catalog: Array[TemptationData] = []

var current: TemptationData
## S05-04: the place the current offer is about, calling the dog in the world.
var calling_point: TerritoryPoint3D
## P-05: the spot (a search point or a weapon lying in the street) holding the
## weapon the current offer is about.
var calling_weapon: Node3D
var offered_ids: Dictionary[StringName, float] = {}

var _next_attempt: float = 0.0
var _offer_expires_at: float = 0.0


func _ready() -> void:
	if catalog.is_empty():
		catalog = DataRegistry.temptations
	run_manager.run_started.connect(_on_run_started)


func _process(_delta: float) -> void:
	if not run_manager.is_running():
		return
	var now := run_manager.elapsed_time
	if current != null:
		if now >= _offer_expires_at:
			var done := current
			current = null
			_stop_calling()
			_next_attempt = now + BETWEEN_OFFERS
			expired.emit(done)
		return
	if not run_manager.is_past_first_extraction() or now < _next_attempt:
		return
	_attempt_offer(now)


## True while the player is being shown a reason to stay.
func has_offer() -> bool:
	return current != null


func _on_run_started(_run_seed: int) -> void:
	current = null
	calling_point = null
	offered_ids.clear()
	_next_attempt = 0.0
	_offer_expires_at = 0.0


func _attempt_offer(now: float) -> void:
	_next_attempt = now + BETWEEN_OFFERS
	if run_manager.first_extraction_time + FIRST_OFFER_DELAY > now:
		_next_attempt = run_manager.first_extraction_time + FIRST_OFFER_DELAY
		return
	# Not every walk gets tempted.
	if run_manager.run_rng.randf() > OFFER_CHANCE:
		return
	var choice := _pick(now)
	if choice != null:
		offer(choice, now)


## Makes `choice` the current offer (also used by tests and the debug panel).
func offer(choice: TemptationData, now: float) -> void:
	current = choice
	offered_ids[choice.id] = now
	_offer_expires_at = now + choice.expiry
	if choice.needs == TemptationData.Needs.BETTER_WEAPON:
		calling_weapon = better_weapon_spot()
		if calling_weapon != null and calling_weapon.has_method(&"set_calling"):
			calling_weapon.set_calling(true)
	if choice.needs == TemptationData.Needs.TERRITORY:
		# World cue before words: the place itself calls (S05-04).
		calling_point = _territory_worth_returning()
		if calling_point != null:
			calling_point.set_calling(true)
	offered.emit(choice)


func _stop_calling() -> void:
	if calling_point != null and is_instance_valid(calling_point):
		calling_point.set_calling(false)
	calling_point = null
	if calling_weapon != null and is_instance_valid(calling_weapon) and calling_weapon.has_method(&"set_calling"):
		calling_weapon.set_calling(false)
	calling_weapon = null


## P-05 / Sprint 05 greed revision: where something that suits the human
## better than what they hold already is — lying in the street, or waiting at
## a spot not yet searched (its loot is rolled at the start of the walk).
func better_weapon_spot() -> Node3D:
	var human := coordinator.get("human") as HumanFollower3D if coordinator != null else null
	var style: CombatStyleData = human.fighter.style if human != null and human.fighter != null else null
	var held := run_manager.equipped_weapon
	var held_left := WeaponCondition.left(held, run_manager.equipped_stack)
	for node in _in_run(&"world_weapons"):
		var lying := node as WorldWeapon3D
		if lying != null and not lying.is_queued_for_deletion() and WeaponCompare.suits_better(lying.weapon, lying.stack.condition, style, held, held_left):
			return lying
	for node in _in_run(SearchPoint.GROUP):
		var point := node as SearchPoint3D
		if point == null or not point.can_interact(run_manager):
			continue
		var stack := point.pending_loot()
		var weapon := DataRegistry.weapon_for_item(stack.item_id) if stack != null else null
		if weapon != null and WeaponCompare.suits_better(weapon, stack.condition, style, held, held_left):
			return point
	return null


func _territory_worth_returning() -> TerritoryPoint3D:
	for point in _in_run(TerritoryPoint3D.GROUP):
		if point.is_worth_returning():
			return point
	return null


## Weighted pick with the run RNG among the templates the world can honour.
func _pick(now: float) -> TemptationData:
	var value := run_manager.run_value()
	var flags: Dictionary = Game.goal_progress.flags
	var available: Array[TemptationData] = []
	var total := 0.0
	for template in catalog:
		if template == null or template.weight <= 0.0:
			continue
		if offered_ids.has(template.id) and now - offered_ids[template.id] < template.cooldown:
			continue
		if not template.is_allowed(value.unbanked_value, flags):
			continue
		if not _world_offers(template.needs, value):
			continue
		available.append(template)
		total += template.weight
	if available.is_empty():
		return null
	var roll := run_manager.run_rng.randf() * total
	for template in available:
		roll -= template.weight
		if roll <= 0.0:
			return template
	return available[-1]


## Is the thing this template speaks about actually out there right now?
func _world_offers(needs: TemptationData.Needs, value: RunValue) -> bool:
	match needs:
		TemptationData.Needs.NOTHING:
			return true
		TemptationData.Needs.UNSNIFFED_CUE:
			for cue in _in_run(ScentCue.GROUP):
				if cue.get("active"):
					return true
			return false
		TemptationData.Needs.PRESENT_PAIR:
			if coordinator == null:
				return false
			for pair in coordinator.get_pairs():
				if pair.is_present() and pair.is_idle():
					return true
			return false
		TemptationData.Needs.UNSEARCHED_POINT:
			if value.is_bag_full():
				return false
			for point in _in_run(SearchPoint.GROUP):
				if point.can_interact(run_manager):
					return true
			return false
		TemptationData.Needs.SQUIRREL:
			return not _in_run(Squirrel.GROUP).is_empty()
		TemptationData.Needs.TERRITORY:
			# A place the dog knows and has not made its own, not yet marked
			# today (S05-03: the Banyan as a reason to stay).
			return _territory_worth_returning() != null
		TemptationData.Needs.BETTER_WEAPON:
			return better_weapon_spot() != null
	return false


## Only nodes belonging to this walk's scene.
func _in_run(group: StringName) -> Array[Node]:
	var result: Array[Node] = []
	for node in get_tree().get_nodes_in_group(group):
		if run_manager.owner == null or run_manager.owner.is_ancestor_of(node):
			result.append(node)
	return result
