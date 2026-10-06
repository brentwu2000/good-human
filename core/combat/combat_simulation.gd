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
## How long a leash yank takes to move the owner (P04-10). A pull is a body
## being hauled back, not a teleport, so timing it against the blow matters.
const PULL_SECONDS: float = 0.25
## Share of an attack's displacement that still moves someone who blocked it.
const BLOCKED_DISPLACEMENT: float = 0.4
## A whiff within this long of the target dodging is their dodge's doing.
const DODGE_CREDIT: float = 0.5

var fighters: Array[CombatFighter] = []
var result: Result = Result.NONE
var time: float = 0.0
var spacing: SpacingData
## The line the fight is on: its direction (radians, 0 = the starting line)
## and where its zero point has moved to (units, from where the fight began).
var line_angle: float = 0.0
var origin: Vector2 = Vector2.ZERO
## P04-08: where a fighter can stand, asked with a ground position in units
## from where the fight began (`world_position`). Unset, anywhere is fine,
## which keeps the simulation runnable headless. The Run World answers it
## against walls, benches, trees and the dog. The answer is either a bool (can
## stand there) or a float: how badly placed that is, 0 meaning fine. A move
## is never allowed to make it worse — out of the way and sideways are always
## allowed, so nobody is ever pinned, but nobody steps further into a wall or
## further onto the dog.
var walkable: Callable

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
	for fighter in fighters:
		_restyle_spacing(fighter)


## P05-07: where an armed fighter's style puts them. Untrained, it wanders —
## sometimes too close, sometimes too far — re-picked every few seconds.
func _restyle_spacing(fighter: CombatFighter) -> void:
	var style := fighter.armed_style()
	if style == null:
		fighter.style_shift = 0.0
		return
	fighter.style_shift = style.ideal_shift
	if style.ideal_jitter > 0.0:
		fighter.style_shift += _rng.randf_range(-style.ideal_jitter, style.ideal_jitter * 0.5)
		fighter.style_jitter_left = style.jitter_seconds


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
		_yank(fighter, delta)
		if fighter.style_jitter_left > 0.0:
			fighter.style_jitter_left -= delta
			if fighter.style_jitter_left <= 0.0:
				_restyle_spacing(fighter)
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
## the opening (GameBalance.opening_damage). A full-strength one (DISTRACT_STRONG) also
## costs them the action they were in and lets the other human pounce at once;
## a worn-out bark only turns their head, so repeat barking cannot stun-lock.
func distract(side: int, seconds: float) -> void:
	var fighter := fighters[side]
	if is_finished() or fighter.is_defeated() or seconds <= 0.0:
		return
	fighter.distracted_until = maxf(fighter.distracted_until, time + seconds)
	fighter.exposed_until = maxf(fighter.exposed_until, time + seconds + _balance.opening_grace)
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
		# P04-10: hauled back over PULL_SECONDS. Whether it saves them is
		# decided by where they are when the blow's window opens — pull late,
		# or into a wall, and it still lands.
		fighter.yank_left = PULL_SECONDS
		fighter.yank_speed = amount / PULL_SECONDS
		fighter.pulled_until = time + PULL_SECONDS
		fighter.step_left = 0.0
		fighter.ready_at = maxf(fighter.ready_at, time + _time_to_contact_end(attacker) + 0.05 + PULL_RECOVERY)
	# Report how far they were actually moved, not how far was asked for: with
	# nothing to dodge they brace against the leash and do not move at all, and
	# presentation has to be able to tell those apart.
	combat_event.emit(&"pulled", side, null, amount if saved else 0.0)
	return saved


## The leash went taut on someone with their footing: a jolt, no movement,
## no cost and no save (P04-10).
func brace(side: int) -> void:
	if is_finished() or fighters[side].is_defeated():
		return
	combat_event.emit(&"pulled", side, null, 0.0)


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

## Valid skills are filtered by condition and cooldown. A valid defence with
## the highest priority wins outright; otherwise one valid attack is picked at
## random, weighted by priority (P-04). No valid skill → footwork.
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
	# A defence answers a telegraph: the most important one wins outright. An
	# attack is a choice among what is available, weighted by priority, so a
	# heavy blow is a choice and not a reflex and the jab still gets thrown.
	if best == null or best.effect != CombatSkillData.Effect.ATTACK:
		return best
	# An opening is not the moment for a jab. Someone looking at the dog gets
	# the heaviest blow available, every time: that is what the bark is for
	# and the player has to see it. Someone merely recovering from a swing
	# most often does too, but not always, or every exchange ends in the
	# same kick.
	var target := _other(fighter)
	if not fighter.in_combo and time < target.exposed_until:
		return best
	if not fighter.in_combo and _is_open(target) and _rng.randf() < _balance.opening_heavy_chance:
		return best
	var total := 0.0
	var valid: Array[CombatSkillData] = []
	var weights: Array[float] = []
	# P05-07: armed, their style leans the choice (bare hands: untouched).
	var style := fighter.armed_style()
	var quickest := INF
	var biggest := 0.0
	if style != null:
		for skill in fighter.data.skills:
			if skill != null and skill.effect == CombatSkillData.Effect.ATTACK and fighter.cooldown_left(skill) <= 0.0 and _condition_met(fighter, skill):
				quickest = minf(quickest, skill.windup)
				biggest = maxf(biggest, skill.power)
	for skill in fighter.data.skills:
		if skill == null or skill.effect != CombatSkillData.Effect.ATTACK or fighter.cooldown_left(skill) > 0.0 or not _condition_met(fighter, skill):
			continue
		# A combination is thrown with the hands.
		if fighter.in_combo and not _is_hand(skill):
			continue
		var weight := float(skill.priority)
		if skill.id == fighter.last_attack:
			weight *= _balance.repeat_weight
		if style != null:
			if skill.condition == CombatSkillData.Condition.TARGET_OPEN:
				weight *= style.counter_weight
			elif skill.is_heavy() and not _is_open(target):
				weight *= style.heavy_unopened_weight
			if is_equal_approx(skill.windup, quickest):
				weight *= style.quick_weight
			if is_equal_approx(skill.power, biggest):
				weight *= style.biggest_weight
		valid.append(skill)
		weights.append(weight)
		total += weight
	if valid.is_empty():
		return null if fighter.in_combo else best
	# Only a kick reaches from here: usually they step in to use their hands.
	if valid.all(func(s: CombatSkillData) -> bool: return not _is_hand(s)) and not _is_open(target):
		if time < fighter.closing_until:
			return null
		if _rng.randf() < _balance.close_in_chance:
			fighter.closing_until = time + _balance.close_in_seconds
			return null
	var roll := _rng.randf() * total
	for i in valid.size():
		roll -= weights[i]
		if roll <= 0.0:
			return valid[i]
	return valid[-1]


## Jab and hook: what a combination is made of.
func _is_hand(skill: CombatSkillData) -> bool:
	return skill.animation_key in [&"punch", &"hook"]



func _end_combo(fighter: CombatFighter) -> void:
	fighter.in_combo = false
	fighter.combo_count = 0

## Open to a punishing blow: distracted (a bark's opening) or caught in the
## recovery after a swing.
func _is_open(target: CombatFighter) -> bool:
	return time < target.exposed_until or (target.phase == CombatFighter.Phase.RECOVERY and not target.whiff_excused)


func _condition_met(fighter: CombatFighter, skill: CombatSkillData) -> bool:
	var target := _other(fighter)
	# P05-07: what they believe the weapon reaches. Contact uses the real reach.
	var style := fighter.armed_style()
	var reach := skill.preferred_range * (1.0 + (style.reach_misjudge if style != null else 0.0))
	match skill.condition:
		CombatSkillData.Condition.TARGET_IN_RANGE:
			return time >= fighter.ready_at and distance() <= reach and distance() >= skill.min_range
		CombatSkillData.Condition.TARGET_OPEN:
			return time >= fighter.ready_at and distance() <= reach and distance() >= skill.min_range and _is_open(target)
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
	if fighter.yank_left > 0.0:
		# Being hauled back by the leash: no footwork fighting it.
		return
	if time < fighter.distracted_until:
		# Looking at the dog, not moving their feet.
		fighter.footwork = CombatFighter.Footwork.HOLD
		fighter.step_left = 0.0
		return
	var skill := choose_skill(fighter)
	if skill == null and fighter.in_combo and time >= fighter.ready_at:
		# Nothing to follow up with (out of reach, or only a kick left): the
		# combination is over.
		_end_combo(fighter)
	# A step is finished before an attack starts; a defence can still cut in.
	if skill != null and fighter.is_stepping() and skill.effect == CombatSkillData.Effect.ATTACK:
		skill = null
	# Hesitation only delays attacks; it never makes the AI scripted.
	if skill != null and skill.effect == CombatSkillData.Effect.ATTACK and not fighter.in_combo and _rng.randf() < _balance.hesitation_chance:
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
	if d > _approach_at(fighter) and _incoming(fighter):
		# Nobody walks back into a blow they can see coming (P04-10: a leash
		# pull or a dodge that got them clear must not be undone by their own
		# feet). They hold until it is spent.
		fighter.footwork = CombatFighter.Footwork.HOLD
		return
	if d > _approach_at(fighter):
		fighter.footwork = CombatFighter.Footwork.APPROACH
		if _move(fighter, fighter.move_speed * spacing.approach_speed * delta * _toward_opponent(fighter)):
			return
		# Something is in the way: go round it rather than walking into it
		# for ever.
		if not _circle(fighter, spacing.circle_speed * delta * fighter.lateral):
			fighter.lateral = -fighter.lateral
		return
	if d < fighter.ideal_min(spacing):
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
	# Circling into a wall turns them round the other way.
	if not _circle(fighter, spacing.circle_speed * delta * fighter.lateral):
		fighter.lateral = -fighter.lateral


## True while the other fighter has an attack on its way that has not landed
## and that `fighter` is currently out of reach of: stepping in now would walk
## into it. Someone already inside its reach gains nothing by holding.
func _incoming(fighter: CombatFighter) -> bool:
	var attacker := _other(fighter)
	return attacker.action != null and attacker.action.effect == CombatSkillData.Effect.ATTACK \
		and attacker.phase in [CombatFighter.Phase.WINDUP, CombatFighter.Phase.STRIKE, CombatFighter.Phase.CONTACT] \
		and not attacker.connected \
		and distance() > attacker.action.preferred_range + REACH_TOLERANCE


func _begin_step(fighter: CombatFighter, kind: CombatFighter.Footwork, distance_units: float, seconds: float) -> void:
	fighter.footwork = kind
	fighter.step_left = maxf(seconds, 0.01)
	fighter.step_speed = distance_units / fighter.step_left


func _continue_step(fighter: CombatFighter, delta: float) -> void:
	var amount := fighter.step_speed * minf(delta, fighter.step_left)
	var moved := false
	if fighter.footwork == CombatFighter.Footwork.BACKSTEP:
		moved = _move(fighter, -amount * _toward_opponent(fighter))
	else:
		moved = _circle(fighter, amount * fighter.lateral)
	# Stepping into something ends the step where they are.
	if not moved:
		fighter.step_left = 0.0
	fighter.step_left -= delta
	if fighter.step_left <= 0.0:
		fighter.step_left = 0.0
		fighter.footwork = CombatFighter.Footwork.HOLD


## Moves `fighter` `amount` units sideways round the other one, who stays
## exactly where they are. The distance between them does not change.
## Returns false, and moves nobody, when that would put them somewhere they
## cannot stand.
func _circle(fighter: CombatFighter, amount: float) -> bool:
	var was := _misplacement(fighter.side)
	var before := [line_angle, origin]
	var pivot_side := _other(fighter).side
	var pivot := world_position(pivot_side)
	line_angle += amount / maxf(distance(), 1.0)
	origin = pivot - _line_direction() * fighters[pivot_side].position
	origin = origin.limit_length(MAX_DRIFT)
	if _misplacement(fighter.side) > was + 0.0001:
		line_angle = before[0]
		origin = before[1]
		return false
	return true


## How badly placed `side` is where they stand (P04-08): 0 is fine.
func _misplacement(side: int) -> float:
	if not walkable.is_valid():
		return 0.0
	var answer: Variant = walkable.call(world_position(side))
	if answer is bool:
		return 0.0 if answer else 1.0
	return float(answer)


func _line_direction() -> Vector2:
	return Vector2(cos(line_angle), sin(line_angle))


## How far out they stop closing in: inside their shortest reach and their
## ideal distance. A move kept for being crowded (shorter than where the
## weapon wants the fight) does not count, or a pole would walk in to
## butt-strike range.
func _approach_at(fighter: CombatFighter) -> float:
	return minf(_min_attack_range(fighter), fighter.ideal_max(spacing))


func _min_attack_range(fighter: CombatFighter) -> float:
	var crowded_below := fighter.ideal_min(spacing) if fighter.data.weapon != null and not fighter.data.weapon.is_unarmed() else 0.0
	var reach := INF
	for skill in fighter.data.skills:
		if skill != null and skill.effect == CombatSkillData.Effect.ATTACK and skill.preferred_range >= crowded_below:
			reach = minf(reach, skill.preferred_range)
	return reach * 0.9 if reach < INF else 0.0


# --- Actions ------------------------------------------------------------------

func _start(fighter: CombatFighter, skill: CombatSkillData) -> void:
	fighter.action = skill
	fighter.uses[skill.id] = fighter.uses.get(skill.id, 0) + 1
	if skill.effect == CombatSkillData.Effect.ATTACK:
		fighter.last_attack = skill.id
	elif fighter.in_combo:
		# Answering a blow breaks the combination off.
		_end_combo(fighter)
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
		fighter.last_evaded_at = time
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
			# The window closed on nobody: a whiff, and they overreach. If the
			# target was getting out of the way, it was their dodge.
			fighter.whiff_excused = false
			if not fighter.connected:
				# Hauled away by the leash is not the attacker's mistake (P04-10).
				fighter.whiff_excused = time - _other(fighter).pulled_until <= DODGE_CREDIT
				var dodged := time - _other(fighter).last_evaded_at <= DODGE_CREDIT
				combat_event.emit(&"dodged" if dodged else &"missed", fighter.side, skill, 0.0)
			_enter(fighter, CombatFighter.Phase.FOLLOW_THROUGH, skill.follow_through)
		CombatFighter.Phase.FOLLOW_THROUGH:
			var whiff := 0.0 if fighter.connected or fighter.whiff_excused else skill.whiff_recovery
			# P05-07: overreach they have (or have not) learned to manage.
			var style := fighter.armed_style()
			if style != null and whiff > 0.0:
				whiff = maxf(whiff + style.whiff_extra, 0.0)
			_enter(fighter, CombatFighter.Phase.RECOVERY, skill.recovery + whiff)
		CombatFighter.Phase.ACTIVE:
			_enter(fighter, CombatFighter.Phase.RECOVERY, skill.recovery)
		CombatFighter.Phase.RECOVERY:
			fighter.phase = CombatFighter.Phase.IDLE
			fighter.action = null
			if skill != null and skill.effect == CombatSkillData.Effect.ATTACK:
				# A jab that connected may run on into the next blow, straight
				# away and without stepping off.
				if skill.animation_key == &"punch" and fighter.connected and fighter.combo_count < _balance.combo_max and _rng.randf() < _balance.combo_chance:
					fighter.combo_count += 1
					fighter.in_combo = true
					fighter.ready_at = time + _balance.combo_gap
					return
				_end_combo(fighter)
				fighter.ready_at = time + fighter.action_interval
				# Spacing reset: sometimes they come off the exchange rather
				# than staying on top of the other person.
				if _rng.randf() < spacing.reset_chance:
					_begin_step(fighter, CombatFighter.Footwork.BACKSTEP, spacing.backstep_distance, spacing.backstep_seconds)


## A leash yank in progress moves them back, and counts as getting out of the
## way: a blow it takes them clear of is reported as dodged.
func _yank(fighter: CombatFighter, delta: float) -> void:
	if fighter.yank_left <= 0.0:
		return
	var amount := fighter.yank_speed * minf(delta, fighter.yank_left)
	fighter.last_evaded_at = time
	fighter.yank_left -= delta
	if not _move(fighter, -amount * _toward_opponent(fighter)):
		fighter.yank_left = 0.0


## Seconds until `attacker`'s current attack can no longer land.
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
	# P04-06/P04-10: neither a dodge nor the leash is a shield. Someone still
	# in reach when the window opens is hit however hard they are trying to
	# get away, or being hauled away; only being out of reach (checked in
	# `_try_contact`) avoids it.
	var variance := 1.0 + _rng.randf_range(-_balance.damage_variance, _balance.damage_variance)
	var damage := attacker.attack * skill.power * variance
	if time < target.exposed_until and not target.is_guarding():
		damage *= _balance.opening_damage
		combat_event.emit(&"opening", attacker.side, skill, damage)
	if target.is_guarding():
		damage *= 1.0 - target.action.damage_reduction * (1.0 - skill.guard_break)
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


## Moves `fighter` along the line. Returns false, and leaves them where they
## were, when the ground they would move onto is not somewhere they can stand
## (a wall, a bench): a step back, a dodge or a knockback stops at it. A move
## may never make where they stand worse, so someone already caught in
## something can always get out, and nobody is ever pinned.
func _move(fighter: CombatFighter, amount: float) -> bool:
	var target := _other(fighter)
	var next := clampf(fighter.position + amount, -MAX_DRIFT, MAX_DRIFT)
	# Never walk into the opponent: two bodies need room (P-04).
	if fighter.side == PLAYER:
		next = minf(next, target.position - spacing.hard_min_separation)
	else:
		next = maxf(next, target.position + spacing.hard_min_separation)
	var was := fighter.position
	var misplaced := _misplacement(fighter.side)
	fighter.position = next
	if _misplacement(fighter.side) > misplaced + 0.0001:
		fighter.position = was
		return false
	return true


## A blow moves its target back along the line (never into anyone, and
## never through a wall: they stop against it).
func _displace(target: CombatFighter, amount: float) -> void:
	if amount > 0.0:
		_move(target, -amount * _toward_opponent(target))


func _toward_opponent(fighter: CombatFighter) -> float:
	return 1.0 if fighter.side == PLAYER else -1.0


func _other(fighter: CombatFighter) -> CombatFighter:
	return fighters[OPPONENT if fighter.side == PLAYER else PLAYER]
