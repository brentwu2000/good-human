class_name CombatCoordinator3D
extends Node
## Live fights in the 3D Run World (ADR-007 seamless real-time combat).
## Same rules and API as CombatCoordinator: nothing pauses, the dog stays
## free, the humans fight where they stand along the line between them, and
## the dog running far enough away disengages. Reuses CombatSimulation.

signal engagement_started(engagement: Engagement3D)
signal engagement_ended(engagement: Engagement3D, result: CombatSimulation.Result)

const STEP: float = 1.0 / 60.0
const DEFEAT_SECONDS: float = 1.6
## CombatSimulation works in arena units; 1 m = 100 units keeps its reach and
## speed tuning meaningful at human scale.
const UNITS_PER_METER: float = 100.0
## Dog further than this (m) from its owner breaks the fight off.
const DISENGAGE_DISTANCE: float = 9.0
## P03-E12: fighters do not step within this of the dog (m, centre to centre)…
const DOG_CLEARANCE: float = 0.9
## …unless it has kept them from closing on each other this long (s).
const DOG_BLOCK_LIMIT: float = 2.0
## Misplacement of standing inside a wall: more than any dog margin can add.
const WALL_MISPLACEMENT: float = 10.0

@export var run_manager: RunManager
## Optional: the view shakes when a hit lands nearby.
@export var camera: CameraRig3D
@export var human: HumanFollower3D
@export var dog: DogController3D
## Ordinary pairs shuffled over spots without a fixed encounter each walk.
@export var ordinary_pool: Array[EncounterData] = []
## Tests speed fights up; 1.0 in the game.
@export var time_scale: float = 1.0
## Combat feel (Core Experience Gate 02: "打架很沒有感覺"). A landed hit stops
## the fight dead for a moment so it reads as contact rather than a slide. It
## only holds the clock — the simulation decides everything, and the pause is
## short enough never to change who wins.
## P-04: every attack carries its own hit-stop (CombatSkillData.hit_stop);
## nothing ever holds longer than this, even the dog's biggest opening.
const HITSTOP_MAX: float = 0.10
## Share of an attack's hit-stop a blocked blow gets.
const BLOCKED_HITSTOP: float = 0.6
## Damage at or above this is a heavy hit (an opening, or a kick that connects).
const HEAVY_DAMAGE: float = 9.0
## After a fight resolves the world holds the beat before letting go, so a win
## or a loss lands instead of snapping straight back to walking (D4/P02-006).
const RELEASE_SECONDS: float = 1.4
## Storyboard 09/10: after a win the owner turns to the dog and puts a hand on
## it. The world holds there before letting go.
const ACKNOWLEDGE_SECONDS: float = 1.9
## How long into that beat the hand actually lands.
const PET_AT: float = 0.75

var last_result: CombatSimulation.Result = CombatSimulation.Result.NONE
## Active fight or null.
var engagement: Engagement3D

var _pairs: Array[OpponentPair3D] = []
## Where the fight began and its starting line; the simulation moves the
## line from there (P-04 footwork), this only maps it onto the ground.
var _origin: Vector3
var _axis: Vector3
var _side_axis: Vector3
## How long the fighters have been kept from closing with the dog near them.
var _kept_apart_left: float = 0.0
var _accumulator: float = 0.0
var _defeat_left: float = -1.0
var _defeated_by: String = ""
var _hitstop_left: float = 0.0
## Facts about the current fight, for presentation to read. The camera decides
## what to do with them; the coordinator never frames anything itself.
var blows_landed: int = 0
var release_left: float = 0.0
## Counting down while the owner is thanking the dog.
var acknowledge_left: float = 0.0
var _base_fighter: FighterData


func _ready() -> void:
	_base_fighter = human.fighter
	run_manager.run_started.connect(_on_run_started)


func get_pairs() -> Array[OpponentPair3D]:
	return _pairs


func is_fighting() -> bool:
	return engagement != null


func is_human_engaged() -> bool:
	return not human.is_following()


## The pair currently fighting (camera framing), or null.
var pair: OpponentPair3D:
	get:
		return engagement.pair if engagement != null else null


func can_provoke(_pair: OpponentPair3D) -> bool:
	return run_manager.is_running() and human.is_following() and _defeat_left < 0.0 and engagement == null


func _on_run_started(_seed: int) -> void:
	engagement = null
	_apply_owner_condition()
	_defeat_left = -1.0
	last_result = CombatSimulation.Result.NONE
	human.set_state(HumanFollower3D.State.FOLLOW)
	if _base_fighter != null:
		human.fighter = GrowthResolver.apply_to_fighter(_base_fighter, Game.human_growth, DataRegistry.training)
	_pairs.clear()
	for node in get_tree().get_nodes_in_group(OpponentPair3D.GROUP):
		var p := node as OpponentPair3D
		if owner == null or owner.is_ancestor_of(p):
			_pairs.append(p)
	_pairs.sort_custom(func(a: OpponentPair3D, b: OpponentPair3D) -> bool: return String(a.spot_id) < String(b.spot_id))
	# After loot rolls (run_started), so encounters don't change loot seeds.
	var pool := ordinary_pool.duplicate()
	for i in range(pool.size() - 1, 0, -1):
		var j := run_manager.run_rng.randi_range(0, i)
		var swap: EncounterData = pool[i]
		pool[i] = pool[j]
		pool[j] = swap
	for p in _pairs:
		var data := p.fixed_encounter
		if data == null and not pool.is_empty():
			data = pool.pop_back()
		p.coordinator = self
		p.setup(data)
		if not p.provoked.is_connected(start_engagement):
			p.provoked.connect(start_engagement)


func start_engagement(opponent: OpponentPair3D) -> void:
	if not can_provoke(opponent) or opponent.state != OpponentPair3D.State.IDLE:
		return
	var a := human.global_position
	var b := opponent.human_global_position()
	var gap := Vector3(b.x - a.x, 0, b.z - a.z)
	_origin = (a + b) / 2.0
	_axis = gap.normalized() if gap.length() > 0.01 else Vector3.FORWARD
	_side_axis = Vector3.UP.cross(_axis)
	var lateral := 1.0 if run_manager.run_rng.randf() < 0.5 else -1.0
	var sim := CombatSimulation.new(human.fighter, opponent.encounter.human, run_manager.run_rng.randi(), null, gap.length() * UNITS_PER_METER)
	sim.set_lateral(lateral)
	# S05-02: the owner starts the fight in whatever state the walk left them.
	var owner_fighter := sim.fighters[CombatSimulation.PLAYER]
	owner_fighter.hp = maxf(owner_fighter.max_hp * run_manager.owner_condition, 1.0)
	run_manager.owner_busy = true
	sim.walkable = _walkable
	engagement = Engagement3D.new(sim, opponent)
	_accumulator = 0.0
	last_result = CombatSimulation.Result.NONE
	human.set_state(HumanFollower3D.State.COMBAT)
	human.puppet.show_hp(true)
	human.puppet.set_hp_ratio(owner_fighter.hp_ratio())
	opponent.begin_combat()
	opponent.human_puppet.shout("你家的狗在叫什麼？！", Color(1.0, 0.8, 0.5))
	human.say("欸欸欸，不是我…", Color(1.0, 0.9, 0.6))
	blows_landed = 0
	release_left = 0.0
	acknowledge_left = 0.0
	_kept_apart_left = 0.0
	sim.combat_event.connect(_on_combat_event)
	sim.finished.connect(_on_finished)
	_sync()
	engagement_started.emit(engagement)


func _process(delta: float) -> void:
	release_left = maxf(release_left - delta, 0.0)
	if acknowledge_left > 0.0:
		var was := acknowledge_left
		acknowledge_left = maxf(acknowledge_left - delta, 0.0)
		var landed := ACKNOWLEDGE_SECONDS - PET_AT
		if was > landed and acknowledge_left <= landed:
			dog.play_petted()
	if _defeat_left >= 0.0:
		_defeat_left -= delta * time_scale
		if _defeat_left < 0.0:
			run_manager.defeat_run(_defeated_by)
	if engagement == null:
		_walk_owner_condition(delta)
		return
	var sim := engagement.simulation
	if dog.global_position.distance_to(human.global_position) > DISENGAGE_DISTANCE:
		sim.disengage()
		return
	if _hitstop_left > 0.0:
		_hitstop_left -= delta
		_sync()
		return
	_update_dog_block(delta)
	_accumulator += delta * time_scale
	while _accumulator >= STEP and engagement != null and not sim.is_finished():
		_accumulator -= STEP
		sim.step(STEP)
	if engagement != null:
		_update_motion(delta)
		_sync()


## S05-02: between fights the owner gets a little back on their own, never past
## `owner_regen_cap`, and a hurt owner walks heavier.
func _walk_owner_condition(delta: float) -> void:
	if not run_manager.is_running() or _defeat_left >= 0.0:
		return
	if human.is_following():
		var balance := DataRegistry.balance
		run_manager.recover_owner(balance.owner_regen_per_second * delta, balance.owner_regen_cap)
	_apply_owner_condition()


func _apply_owner_condition() -> void:
	var condition := run_manager.owner_condition
	human.puppet.set_hp_ratio(condition)
	human.condition_speed = 1.0 - DataRegistry.balance.owner_hurt_slowdown * human.puppet.hurt_amount()


## 0..1 weight of one hit, so a jab and a kick into an opening do not land the
## same way.
func _impact_weight(damage: float) -> float:
	return clampf(damage / HEAVY_DAMAGE, 0.25, 1.0)


## Hooks and kicks move the body they land on; a jab does not.
func _is_heavy(skill: CombatSkillData, weight: float) -> bool:
	return weight >= 0.75 or (skill != null and skill.animation_key in [&"hook", &"kick"])


## The blow's own hold, capped.
func _hit_stop(skill: CombatSkillData) -> float:
	return minf(skill.hit_stop if skill != null else 0.05, HITSTOP_MAX)


## The visual accent belongs where bodies meet, not at the encounter marker.
func _contact_point() -> Vector3:
	if engagement == null:
		return Vector3.ZERO
	return (human.global_position + engagement.pair.human_global_position()) * 0.5


## Freezes the fight for `stop` seconds and shakes the view, scaled by the hit.
func _punch_landed(weight: float, stop: float) -> void:
	blows_landed += 1
	_hitstop_left = maxf(_hitstop_left, minf(stop, HITSTOP_MAX))
	if camera != null:
		camera.add_trauma(weight)


## How the player's human is doing, 0..1, or -1 when there is no fight. Read by
## presentation so the owner's state can be shown through them rather than a bar.
func owner_condition() -> float:
	return engagement.simulation.fighters[CombatSimulation.PLAYER].hp_ratio() if engagement != null else -1.0


## True while the owner is thanking the dog (storyboard 09/10).
func is_acknowledging() -> bool:
	return acknowledge_left > 0.0


## True while the owner is down and the dog can still move around them.
func is_owner_down() -> bool:
	return _defeat_left >= 0.0


## Motion states from the simulation's footwork. Where they stand is the
## simulation's too (`_world_position`); nothing here moves anyone.
func _update_motion(delta: float) -> void:
	var sim := engagement.simulation
	var puppets := [human.puppet, engagement.pair.human_puppet]
	for side in 2:
		var fighter: CombatFighter = sim.fighters[side]
		var puppet: FighterPuppet3D = puppets[side]
		var closing := fighter.footwork == CombatFighter.Footwork.APPROACH
		puppet.motion.update(delta, fighter, closing, fighter.is_defeated())
		puppet.drive_combat_clip(fighter)
		puppet.play_motion(delta)


## P04-08: how badly placed a fighter would be at `ground` (simulation units
## from where the fight began); 0 is fine. Inside a wall, bench or tree is
## WALL_MISPLACEMENT. The other fighter is kept apart by the simulation.
##
## P03-E12 (captures): the dog too, by a margin — how far inside it they are.
## A fight that walks onto a dog standing beside it buries the dog's eyes in
## clothing, and P-04 asks that a fighter adjusts its path round the dog rather
## than through it. The simulation never lets a move make this worse, so a
## fighter inside the margin can still step out or round but not further in,
## and nobody is pinned; and a dog that keeps them from closing for
## DOG_BLOCK_LIMIT stops counting until they are back in range, so it can never
## jam the fight either.
func _walkable(ground: Vector2) -> float:
	var space := get_viewport().get_world_3d().direct_space_state if is_inside_tree() else null
	if space == null:
		return 0.0
	var at := _ground_to_world(ground)
	var misplaced := 0.0
	if _dog_counts():
		var from_dog := Vector2(at.x - dog.global_position.x, at.z - dog.global_position.z).length()
		misplaced += maxf(DOG_CLEARANCE - from_dog, 0.0)
	return misplaced + (0.0 if _clear_of_world(at) else WALL_MISPLACEMENT)


func _clear_of_world(at: Vector3) -> bool:
	var space := get_viewport().get_world_3d().direct_space_state
	var presence := DataRegistry.presence
	var capsule := CapsuleShape3D.new()
	capsule.radius = presence.human_radius if presence != null else 0.24
	capsule.height = presence.human_height if presence != null else 1.72
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	# Clear of the ground itself: only what they would walk into counts.
	query.transform = Transform3D(Basis.IDENTITY, Vector3(at.x, human.global_position.y + capsule.height * 0.5 + 0.05, at.z))
	query.collision_mask = Greybox.WORLD_LAYER
	return space.intersect_shape(query, 1).is_empty()


func _dog_counts() -> bool:
	return _kept_apart_left < DOG_BLOCK_LIMIT


## Counts how long the fighters have wanted to close and not been able to:
## past DOG_BLOCK_LIMIT the dog is walked round no longer, until they are in
## range again.
func _update_dog_block(delta: float) -> void:
	var sim := engagement.simulation
	var want_to_close := sim.distance() > sim.spacing.ideal_max
	if not want_to_close:
		_kept_apart_left = 0.0
		return
	var dog_near := Vector2(dog.global_position.x - _fight_centre().x, dog.global_position.z - _fight_centre().z).length() < sim.distance() / UNITS_PER_METER
	_kept_apart_left = _kept_apart_left + delta * time_scale if dog_near else 0.0


func _fight_centre() -> Vector3:
	return (human.global_position + engagement.pair.human_global_position()) * 0.5


func _ground_to_world(ground: Vector2) -> Vector3:
	var metres := ground / UNITS_PER_METER
	return _origin + _axis * metres.x + _side_axis * metres.y


func _world_position(side: int) -> Vector3:
	var ground := engagement.simulation.world_position(side) / UNITS_PER_METER
	var p := _origin + _axis * ground.x + _side_axis * ground.y
	var y := human.global_position.y if side == CombatSimulation.PLAYER else engagement.pair.human_global_position().y
	return Vector3(p.x, y, p.z)


func _sync() -> void:
	var sim := engagement.simulation
	var opponent := engagement.pair
	var player_fighter := sim.fighters[CombatSimulation.PLAYER]
	var opponent_fighter := sim.fighters[CombatSimulation.OPPONENT]
	human.global_position = _world_position(CombatSimulation.PLAYER)
	opponent.set_human_global_position(_world_position(CombatSimulation.OPPONENT))
	human.puppet.face_towards(opponent.human_global_position())
	opponent.human_puppet.face_towards(human.global_position)
	human.puppet.set_hp_ratio(player_fighter.hp_ratio())
	opponent.human_puppet.set_hp_ratio(opponent_fighter.hp_ratio())
	human.puppet.set_guard(player_fighter.is_guarding())
	opponent.human_puppet.set_guard(opponent_fighter.is_guarding())


func _on_combat_event(kind: StringName, side: int, skill: CombatSkillData, amount: float) -> void:
	var own := human.puppet
	var theirs := engagement.pair.human_puppet
	var actor := own if side == CombatSimulation.PLAYER else theirs
	var other := theirs if side == CombatSimulation.PLAYER else own
	match kind:
		&"skill_started":
			actor.play_windup(skill)
		&"strike":
			# P-04: the limb goes out when the strike is released, before
			# anyone knows whether it lands. Contact events only add the
			# other body's answer.
			actor.play_strike(skill)
		&"hit":
			var weight := _impact_weight(amount)
			other.play_hurt(false, weight, skill.animation_key if skill != null else &"")
			other.motion.react(CombatMotion3D.State.HIT_HEAVY if _is_heavy(skill, weight) else CombatMotion3D.State.HIT_LIGHT)
			engagement.pair.show_combat_impact(false, weight, _contact_point())
			_punch_landed(weight, _hit_stop(skill))
		&"blocked":
			var block_weight := _impact_weight(amount) * 0.5
			other.play_hurt(true, block_weight, skill.animation_key if skill != null else &"")
			engagement.pair.show_combat_impact(true, block_weight, _contact_point())
			_punch_landed(0.35, _hit_stop(skill) * BLOCKED_HITSTOP)
		&"dodged":
			other.play_evade()
			actor.play_miss()
		&"missed":
			actor.play_miss()
		&"distracted":
			# P03-E07: a bark landed. They turn to look at the dog and open up,
			# so the opening the owner is about to take is visible in the world.
			actor.play_distracted(dog.global_position, amount)
		&"pulled":
			# P03-E08: the leash yanked the owner. `amount` is how far.
			actor.play_pulled(amount > 0.0)
			actor.motion.react(CombatMotion3D.State.HIT_LIGHT)
		&"stumbled":
			actor.play_stumble()
			actor.motion.react(CombatMotion3D.State.STUMBLE)
		&"opening":
			# The dog made this happen: the biggest hit of the fight should
			# look like the biggest hit of the fight. Replace the ordinary coral
			# pulse from the hit event with the warm dog-agency payoff.
			engagement.pair.show_combat_impact(false, 1.0, _contact_point(), true)
			_punch_landed(1.0, HITSTOP_MAX)
		&"staggered":
			actor.play_stagger()
			actor.motion.react(CombatMotion3D.State.STAGGER)
		&"defeated":
			actor.play_down()
			other.play_victory()


func _on_finished(result: CombatSimulation.Result) -> void:
	var ended := engagement
	var opponent := ended.pair
	var encounter := opponent.encounter
	# S05-02: what the fight took stays taken.
	run_manager.owner_busy = false
	run_manager.set_owner_condition(0.0 if result == CombatSimulation.Result.DEFEAT else ended.simulation.fighters[CombatSimulation.PLAYER].hp_ratio())
	engagement = null
	last_result = result
	_hitstop_left = 0.0
	release_left = RELEASE_SECONDS
	opponent.end_combat(result)
	match result:
		CombatSimulation.Result.VICTORY:
			human.set_state(HumanFollower3D.State.FOLLOW)
			var reward := run_manager.grant_reward(encounter.reward_table)
			# P03-E11: the resolution beat is not the reward, it is the owner
			# turning round to the dog. Said sparingly, as the spec asks.
			human.puppet.play_acknowledge(dog.global_position)
			acknowledge_left = ACKNOWLEDGE_SECONDS
			human.say("好狗狗。" + ("（撿到%s）" % reward.item.display_name if reward != null else ""), Color(0.6, 1.0, 0.6), 2.0)
		CombatSimulation.Result.DEFEAT:
			# The owner stays in the world and the dog can still reach them
			# (`_defeat_left`); the camera holds on them through CRISIS.
			human.set_state(HumanFollower3D.State.DOWN)
			human.puppet.show_hp(false)
			opponent.human_puppet.shout("哼。")
			_defeated_by = encounter.human.display_name
			_defeat_left = DEFEAT_SECONDS
		CombatSimulation.Result.DISENGAGED:
			human.set_state(HumanFollower3D.State.FOLLOW)
			human.say("等等我啊！", Color(0.85, 0.85, 0.85))
		_:
			human.set_state(HumanFollower3D.State.FOLLOW)
	engagement_ended.emit(ended, result)


# --- Debug (Debug Panel / tests only) --------------------------------------------

func debug_force_result(result: CombatSimulation.Result) -> void:
	if engagement != null:
		engagement.simulation.force_result(result)


## D4/P02-011: put the owner at `ratio` of their health mid-fight, to tune how
## HURT and CRITICAL read (and the CRISIS framing) without waiting for it.
func debug_set_owner_condition(ratio: float) -> void:
	if engagement != null:
		var fighter := engagement.simulation.fighters[CombatSimulation.PLAYER]
		fighter.hp = maxf(fighter.max_hp * ratio, 1.0)
	else:
		# S05-02: between fights, the condition the walk carries.
		run_manager.set_owner_condition(ratio)
		_apply_owner_condition()


## Debug overlay line: the camera's framing and the owner's condition.
func debug_text() -> String:
	var rig_text := "camera %s pov %.2f %s" % [CameraRig3D.Context.keys()[camera.context], camera.pov, "DOG-POV" if CameraRig3D.combat_pov else "P-02 3rd"] if camera != null else "camera -"
	var owner_text := "owner %s %.0f%%" % [FighterPuppet3D.Condition.keys()[human.puppet.condition_state()], owner_condition() * 100.0] if engagement != null else "owner -"
	return "Combat: %s  %s" % [rig_text, owner_text]


## Puts the dog (and owner) next to the nearest pair that can be provoked.
func debug_goto_next_pair() -> void:
	if is_human_engaged():
		return
	var best: OpponentPair3D = null
	for p in _pairs:
		if p.is_idle() and p.is_present():
			if best == null or dog.global_position.distance_to(p.global_position) < dog.global_position.distance_to(best.global_position):
				best = p
	if best != null:
		dog.global_position = best.global_position + Vector3(0.7, 0.2, 0.9)
		dog.velocity = Vector3.ZERO
		human.global_position = best.global_position + Vector3(1.6, 0.2, 2.0)
