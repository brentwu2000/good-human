class_name CombatSimulation
extends RefCounted
## Autonomous 1v1 human fight on a line. Pure logic: no nodes, no input, so it
## can be stepped headless. In the Run World the line runs between the two
## humans' positions (see Engagement); presentation listens to `combat_event`.
## Each fighter picks skills with a condition + priority evaluator.
##
## P-04: the line itself moves. A fighter circling or sidestepping moves round
## the other one, which turns the line (`line_angle`) about the one standing
## still and shifts its `origin`; distance and every outcome still come from
## positions along the line, so the rules stay one-dimensional.

## kind: skill_started, strike (the attack is released), hit, blocked, dodged,
## missed, staggered, defeated, distracted, opening (a hit on a distracted
## fighter), pulled, stumbled.
## `fighter` is the side the event is about (the attacker for hit/blocked/
## dodged/missed, the victim for staggered/defeated).
signal combat_event(kind: StringName, fighter: int, skill: CombatSkillData, amount: float)
signal finished(result: Result)

## DISENGAGED = the player's side broke away; ABORTED = took too long.
enum Result { NONE, VICTORY, DEFEAT, DISENGAGED, ABORTED }

const PLAYER: int = 0
const OPPONENT: int = 1
const START_DISTANCE: float = 220.0
## How far either human may drift from the engagement origin.
const MAX_DRIFT: float = 600.0
## Damage multiplier for hits on a distracted (exposed) fighter.
const OPENING_DAMAGE: float = 1.4
## The opening stays open this long after the target stops looking away, so the
## other human's next attack lands on it without being handed a free turn.
const OPENING_GRACE: float = 1.2
## A distraction at least this long is a full one: the target can still drop
## what it was doing. Shorter ones only make it look away.
const DISTRACT_STRONG: float = 0.5
## An attack can only be called off while this much of its wind-up is left:
## once they have committed, the swing comes anyway.
const COMMIT_SHARE: float = 0.5
## Extra reach so an attack started in range still lands after tiny movement.
const REACH_TOLERANCE: float = 12.0
## How long after a telegraph starts a fighter can still answer it.
const REACTION_WINDOW: float = 0.3
## Yanked off balance, even usefully, they need this long to set their feet
## again — so dodging on the leash trades the owner's own tempo for safety.
const PULL_RECOVERY: float = 1.5
## Share of an attack's displacement that still moves someone who blocked it.
const BLOCKED_DISPLACEMENT: float = 0.4

var fighters: Array[CombatFighter] = []
var result: Result = Result.NONE
var time: float = 0.0
var spacing: SpacingData
## The line the fight is on: its direction (radians, 0 = the starting line)
## and where its zero point has moved to (units, from where the fight began).
var line_angle: float = 0.0
var origin: Vector2 = Vector2.ZERO

var _first_to_decide: int = 0

var _balance: GameBalance
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init(player: FighterData, opponent: FighterData, rng_seed: int, balance: GameBalance = null, start_distance: float = START_DISTANCE) -> void:
	_balance = balance if balance != null else DataRegistry.balance
	spacing = DataRegistry.spacing if DataRegistry.spacing != null else SpacingData.new()
	_rng.seed = rng_seed
	fighters = [CombatFighter.new(player, PLAYER, _balance), CombatFighter.new(opponent, OPPONENT, _balance)]
	fighters[PLAYER].position = -start_distance / 2.0
	fighters[OPPONENT].position = start_distance / 2.0


func is_finished() -> bool:
	return result != Result.NONE


func distance() -> float:
	return absf(fighters[OPPONENT].position - fighters[PLAYER].position)


## Where `side` stands on the ground, in units from where the fight began.
func world_position(side: int) -> Vector2:
	return origin + _line_direction() * fighters[side].position


## Which way both fighters start circling (+1 / -1). The same for both, so the
## line visibly turns rather than two people shuffling against each other.
func set_lateral(value: float) -> void:
	for fighter in fighters:
		fighter.lateral = signf(value) if value != 0.0 else 1.0


func step(delta: float) -> void:
	if is_finished():
		return
	time += delta
	for fighter in fighters:
		_tick_cooldowns(fighter, delta)
	for fighter in fighters:
		_advance(fighter, delta)
		if is_finished():
			return
	# Alternate who decides first. Deciding first means starting attacks first,
	# and therefore being the one caught mid-attack when the other answers —
	# a fixed order quietly hands one side the whole fight.
	_first_to_decide = 1 - _first_to_decide
	for i in 2:
		var fighter: CombatFighter = fighters[(_first_to_decide + i) % 2]
		if fighter.is_idle():
			_decide(fighter, delta)
	if time >= _balance.combat_max_duration:
		abort()


## Runs until the fight ends (tests / instant resolution).
func run_to_end(delta: float = 1.0 / 30.0) -> Result:
	while not is_finished():
		step(delta)
	return result


func abort() -> void:
	_finish(Result.ABORTED)


## The player's human broke away to follow the dog.
func disengage() -> void:
	_finish(Result.DISENGAGED)


## Debug hook: end immediately as if one side was knocked out.
func force_result(value: Result) -> void:
	if is_finished():
		return
	if value == Result.VICTORY:
		fighters[OPPONENT].hp = 0.0
		combat_event.emit(&"defeated", OPPONENT, null, 0.0)
	elif value == Result.DEFEAT:
		fighters[PLAYER].hp = 0.0
		combat_event.emit(&"defeated", PLAYER, null, 0.0)
	_finish(value)


# --- Dog agency (Sprint 04) ---------------------------------------------------
# The dog never commands attacks; it changes the situation the humans react to.

## A bark makes `side` look away: no decisions for `seconds`, and hits land on
## the opening (OPENING_DAMAGE). A full-strength one (DISTRACT_STRONG) also
## costs them the action they were in and lets the other human pounce at once;
## a worn-out bark only turns their head, so repeat barking cannot stun-lock.
func distract(side: int, seconds: float) -> void:
	var fighter := fighters[side]
	if is_finished() or fighter.is_defeated() or seconds <= 0.0:
		return
	fighter.distracted_until = maxf(fighter.distracted_until, time + seconds)
	fighter.exposed_until = maxf(fighter.exposed_until, time + seconds + OPENING_GRACE)
	# A full-strength bark also costs them what they were doing — for as long as
	# they looked away, not for their own recovery, so slow heavy fighters are
	# not perma-cancelled. An attack they have already committed to still lands.
	# The other human is never handed a free turn: their ordinary next attack is
	# simply worth more while the opening lasts.
	if seconds >= DISTRACT_STRONG and _can_be_called_off(fighter):
		_enter(fighter, CombatFighter.Phase.RECOVERY, seconds)
	combat_event.emit(&"distracted", side, null, seconds)


## Guard and evade break at any time; an attack only before it is committed.
func _can_be_called_off(fighter: CombatFighter) -> bool:
	if fighter.is_guarding() or fighter.is_evading():
		return true
	return fighter.is_winding_up_attack() and fighter.phase_time_left > fighter.action.windup * COMMIT_SHARE


## The leash yanks `side` away from the opponent by `amount` units. Returns
## true when it pulled them out of an incoming attack. With nothing to dodge
## they just brace against the leash, so a mistimed pull costs nothing but the
## chance — only pulling them into the opponent (`stumble`) is punished.
func pull(side: int, amount: float) -> bool:
	var fighter := fighters[side]
	if is_finished() or fighter.is_defeated():
		return false
	var attacker := _other(fighter)
	var saved := attacker.is_winding_up_attack()
	if saved:
		# Out of the way until that attack's contact window has closed, then
		# back on their feet.
		_move(fighter, -amount * _toward_opponent(fighter))
		fighter.pulled_until = time + _time_to_contact_end(attacker) + 0.05
		fighter.ready_at = maxf(fighter.ready_at, fighter.pulled_until + PULL_RECOVERY)
	# Report how far they were actually moved, not how far was asked for: with
	# nothing to dodge they brace against the leash and do not move at all, and
	# presentation has to be able to tell those apart.
	combat_event.emit(&"pulled", side, null, amount if saved else 0.0)
	return saved


## A bad pull knocks `side` off balance: current action lost, no attacks for a while.
func stumble(side: int, seconds: float) -> void:
	var fighter := fighters[side]
	if is_finished() or fighter.is_defeated():
		return
	if not fighter.is_idle() and fighter.action != null:
		_enter(fighter, CombatFighter.Phase.RECOVERY, maxf(fighter.action.recovery, seconds))
	fighter.ready_at = maxf(fighter.ready_at, time + seconds)
	combat_event.emit(&"stumbled", side, null, seconds)


# --- AI -----------------------------------------------------------------------

## Valid skills are filtered by condition and cooldown, then the highest
## priority wins (ties broken randomly). No valid skill → close the distance.
func choose_skill(fighter: CombatFighter) -> CombatSkillData:
	var best: CombatSkillData = null
	var ties := 0
	for skill in fighter.data.skills:
		if skill == null or fighter.cooldown_left(skill) > 0.0 or not _condition_met(fighter, skill):
			continue
		if best == null or skill.priority > best.priority:
			best = skill
			ties = 1
		elif skill.priority == best.priority:
			ties += 1
			if _rng.randi_range(1, ties) == 1:
				best = skill
	return best


func _condition_met(fighter: CombatFighter, skill: CombatSkillData) -> bool:
	var target := _other(fighter)
	match skill.condition:
		CombatSkillData.Condition.TARGET_IN_RANGE:
			return time >= fighter.ready_at and distance() <= skill.preferred_range
		CombatSkillData.Condition.INCOMING_ATTACK:
			# You react to a telegraph starting, not to it still being under
			# way. Otherwise a longer wind-up is simply a longer free window for
			# the defender, and making attacks readable turns every fight into a
			# blocking contest.
			# Strictly after it starts, never in the same step: fighters decide
			# in order, so a same-step reaction would hand whoever decides
			# second a free answer to everything the other one does.
			var since := time - target.windup_started_at
			return target.is_winding_up_attack() and since > 0.0 and since <= REACTION_WINDOW 				and distance() <= target.action.preferred_range + REACH_TOLERANCE
	return false


func _decide(fighter: CombatFighter, delta: float) -> void:
	if time < fighter.distracted_until:
		# Looking at the dog, not moving their feet.
		fighter.footwork = CombatFighter.Footwork.HOLD
		fighter.step_left = 0.0
		return
	var skill := choose_skill(fighter)
	# A step is finished before an attack starts; a defence can still cut in.
	if skill != null and fighter.is_stepping() and skill.effect == CombatSkillData.Effect.ATTACK:
		skill = null
	# Hesitation only delays attacks; it never makes the AI scripted.
	if skill != null and skill.effect == CombatSkillData.Effect.ATTACK and _rng.randf() < _balance.hesitation_chance:
		fighter.ready_at = time + fighter.action_interval * 0.5
		skill = null
	if skill != null:
		fighter.step_left = 0.0
		fighter.footwork = CombatFighter.Footwork.HOLD
		_start(fighter, skill)
		return
	_footwork(fighter, delta)


## P-04: between actions nobody stands still trading turns. Too far, they
## close; too close, they step back out; in their range they circle, now and
## then sidestep, and sometimes change which way they are going round.
func _footwork(fighter: CombatFighter, delta: float) -> void:
	if fighter.is_stepping():
		_continue_step(fighter, delta)
		return
	var d := distance()
	if d > minf(_min_attack_range(fighter), spacing.ideal_max):
		fighter.footwork = CombatFighter.Footwork.APPROACH
		_move(fighter, fighter.move_speed * spacing.approach_speed * delta * _toward_opponent(fighter))
		return
	if d < spacing.ideal_min:
		_begin_step(fighter, CombatFighter.Footwork.BACKSTEP, spacing.backstep_distance, spacing.backstep_seconds)
		_continue_step(fighter, delta)
		return
	if _rng.randf() < spacing.lateral_flip_chance * delta:
		fighter.lateral = -fighter.lateral
	if _rng.randf() < spacing.sidestep_chance * delta:
		_begin_step(fighter, CombatFighter.Footwork.SIDESTEP, spacing.sidestep_distance, spacing.sidestep_seconds)
		_continue_step(fighter, delta)
		return
	fighter.footwork = CombatFighter.Footwork.CIRCLE
	_circle(fighter, spacing.circle_speed * delta * fighter.lateral)


func _begin_step(fighter: CombatFighter, kind: CombatFighter.Footwork, distance_units: float, seconds: float) -> void:
	fighter.footwork = kind
	fighter.step_left = maxf(seconds, 0.01)
	fighter.step_speed = distance_units / fighter.step_left


func _continue_step(fighter: CombatFighter, delta: float) -> void:
	var amount := fighter.step_speed * minf(delta, fighter.step_left)
	if fighter.footwork == CombatFighter.Footwork.BACKSTEP:
		_move(fighter, -amount * _toward_opponent(fighter))
	else:
		_circle(fighter, amount * fighter.lateral)
	fighter.step_left -= delta
	if fighter.step_left <= 0.0:
		fighter.step_left = 0.0
		fighter.footwork = CombatFighter.Footwork.HOLD


## Moves `fighter` `amount` units sideways round the other one, who stays
## exactly where they are. The distance between them does not change.
func _circle(fighter: CombatFighter, amount: float) -> void:
	var pivot_side := _other(fighter).side
	var pivot := world_position(pivot_side)
	line_angle += amount / maxf(distance(), 1.0)
	origin = pivot - _line_direction() * fighters[pivot_side].position
	origin = origin.limit_length(MAX_DRIFT)


func _line_direction() -> Vector2:
	return Vector2(cos(line_angle), sin(line_angle))


func _min_attack_range(fighter: CombatFighter) -> float:
	var reach := INF
	for skill in fighter.data.skills:
		if skill != null and skill.effect == CombatSkillData.Effect.ATTACK:
			reach = minf(reach, skill.preferred_range)
	return reach * 0.9 if reach < INF else 0.0


# --- Actions ------------------------------------------------------------------

func _start(fighter: CombatFighter, skill: CombatSkillData) -> void:
	fighter.action = skill
	fighter.uses[skill.id] = fighter.uses.get(skill.id, 0) + 1
	fighter.cooldowns[skill.id] = skill.cooldown
	combat_event.emit(&"skill_started", fighter.side, skill, 0.0)
	if skill.effect == CombatSkillData.Effect.ATTACK:
		fighter.windup_started_at = time
	_enter(fighter, CombatFighter.Phase.WINDUP, skill.windup)


func _enter(fighter: CombatFighter, phase: CombatFighter.Phase, duration: float) -> void:
	fighter.phase = phase
	fighter.phase_time_left = duration
	if duration <= 0.0:
		_phase_done(fighter)


func _advance(fighter: CombatFighter, delta: float) -> void:
	if fighter.is_idle():
		return
	if fighter.phase == CombatFighter.Phase.CONTACT and not fighter.connected:
		_try_contact(fighter)
		if is_finished() or fighter.phase != CombatFighter.Phase.CONTACT:
			return
	if fighter.is_evading():
		var speed := fighter.action.reposition_distance / maxf(fighter.action.active_time, 0.01)
		_move(fighter, -speed * delta * _toward_opponent(fighter))
	fighter.phase_time_left -= delta
	if fighter.phase_time_left <= 0.0:
		_phase_done(fighter)


func _phase_done(fighter: CombatFighter) -> void:
	var skill := fighter.action
	match fighter.phase:
		CombatFighter.Phase.WINDUP:
			if skill.effect == CombatSkillData.Effect.ATTACK:
				# P-04: released. Nothing can land until the contact window.
				fighter.connected = false
				combat_event.emit(&"strike", fighter.side, skill, 0.0)
				_enter(fighter, CombatFighter.Phase.STRIKE, skill.strike_time)
			else:
				_enter(fighter, CombatFighter.Phase.ACTIVE, skill.active_time)
		CombatFighter.Phase.STRIKE:
			fighter.phase = CombatFighter.Phase.CONTACT
			fighter.phase_time_left = maxf(skill.contact_time, 0.0)
			_try_contact(fighter)
			if is_finished() or fighter.phase != CombatFighter.Phase.CONTACT:
				return
			if fighter.phase_time_left <= 0.0:
				_phase_done(fighter)
		CombatFighter.Phase.CONTACT:
			# The window closed on nobody: a whiff, and they overreach.
			var whiffed := not fighter.connected
			if whiffed:
				combat_event.emit(&"missed", fighter.side, skill, 0.0)
			_enter(fighter, CombatFighter.Phase.FOLLOW_THROUGH, skill.follow_through)
		CombatFighter.Phase.FOLLOW_THROUGH:
			var whiff := 0.0 if fighter.connected else skill.whiff_recovery
			_enter(fighter, CombatFighter.Phase.RECOVERY, skill.recovery + whiff)
		CombatFighter.Phase.ACTIVE:
			_enter(fighter, CombatFighter.Phase.RECOVERY, skill.recovery)
		CombatFighter.Phase.RECOVERY:
			fighter.phase = CombatFighter.Phase.IDLE
			fighter.action = null
			if skill != null and skill.effect == CombatSkillData.Effect.ATTACK:
				fighter.ready_at = time + fighter.action_interval
				# Spacing reset: sometimes they come off the exchange rather
				# than staying on top of the other person.
				if _rng.randf() < spacing.reset_chance:
					_begin_step(fighter, CombatFighter.Footwork.BACKSTEP, spacing.backstep_distance, spacing.backstep_seconds)


## A guard until `attacker`'s current attack can no longer land.
func _time_to_contact_end(attacker: CombatFighter) -> float:
	var skill := attacker.action
	match attacker.phase:
		CombatFighter.Phase.WINDUP:
			return attacker.phase_time_left + skill.strike_time + skill.contact_time
		CombatFighter.Phase.STRIKE:
			return attacker.phase_time_left + skill.contact_time
		CombatFighter.Phase.CONTACT:
			return attacker.phase_time_left
	return 0.0


## P-04: an attack lands only inside its contact window, only on a body within
## reach at that moment, and only once. Out of reach it keeps looking until the
## window closes; the whiff is reported when it does.
func _try_contact(attacker: CombatFighter) -> void:
	var skill := attacker.action
	if attacker.connected or skill == null:
		return
	if distance() > skill.preferred_range + REACH_TOLERANCE:
		return
	attacker.connected = true
	_resolve_attack(attacker, skill)


func _resolve_attack(attacker: CombatFighter, skill: CombatSkillData) -> void:
	var target := _other(attacker)
	if target.is_evading() or time < target.pulled_until:
		combat_event.emit(&"dodged", attacker.side, skill, 0.0)
		return
	var variance := 1.0 + _rng.randf_range(-_balance.damage_variance, _balance.damage_variance)
	var damage := attacker.attack * skill.power * variance
	if time < target.exposed_until and not target.is_guarding():
		damage *= OPENING_DAMAGE
		combat_event.emit(&"opening", attacker.side, skill, damage)
	if target.is_guarding():
		damage *= 1.0 - target.action.damage_reduction
		target.hp -= damage
		_displace(target, skill.displacement * BLOCKED_DISPLACEMENT)
		combat_event.emit(&"blocked", attacker.side, skill, damage)
	else:
		target.hp -= damage
		_displace(target, skill.displacement)
		combat_event.emit(&"hit", attacker.side, skill, damage)
		# Same rule a bark obeys: an attack they have already committed to still
		# comes. Without this, longer wind-ups mean far more time spent
		# interruptible, and whoever kicks first simply wins.
		if skill.stagger > target.stability and _can_be_called_off(target):
			var interrupted := target.action
			_enter(target, CombatFighter.Phase.RECOVERY, interrupted.recovery)
			combat_event.emit(&"staggered", target.side, interrupted, 0.0)
	if target.is_defeated():
		target.hp = 0.0
		combat_event.emit(&"defeated", target.side, skill, 0.0)
		_finish(Result.VICTORY if target.side == OPPONENT else Result.DEFEAT)


func _finish(value: Result) -> void:
	if is_finished():
		return
	result = value
	finished.emit(result)


# --- Helpers ------------------------------------------------------------------

func _tick_cooldowns(fighter: CombatFighter, delta: float) -> void:
	for id in fighter.cooldowns:
		fighter.cooldowns[id] = maxf(fighter.cooldowns[id] - delta, 0.0)


func _move(fighter: CombatFighter, amount: float) -> void:
	var target := _other(fighter)
	var next := clampf(fighter.position + amount, -MAX_DRIFT, MAX_DRIFT)
	# Never walk into the opponent: two bodies need room (P-04).
	if fighter.side == PLAYER:
		next = minf(next, target.position - spacing.hard_min_separation)
	else:
		next = maxf(next, target.position + spacing.hard_min_separation)
	fighter.position = next


## A blow moves its target back along the line (never into anyone).
func _displace(target: CombatFighter, amount: float) -> void:
	if amount > 0.0:
		_move(target, -amount * _toward_opponent(target))


func _toward_opponent(fighter: CombatFighter) -> float:
	return 1.0 if fighter.side == PLAYER else -1.0


func _other(fighter: CombatFighter) -> CombatFighter:
	return fighters[OPPONENT if fighter.side == PLAYER else PLAYER]
