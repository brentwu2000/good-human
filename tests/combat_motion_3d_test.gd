extends "res://tests/test_case.gd"
## P-03 P03-E01 in the real 3D walk: the humans are bodies in a fight, not two
## statues exchanging HP. The exit gate is that a fight reads with the combat
## text hidden, so every check here is about what the world actually does.

const TEST_SAVE: String = "user://tests/combat_motion_save.json"

var _tree: SceneTree


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_tree = get_tree()
	DirAccess.make_dir_recursive_absolute(TEST_SAVE.get_base_dir())
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(TEST_SAVE)
	SaveManager.save_path = TEST_SAVE
	var placeholder := Node.new()
	_tree.root.add_child(placeholder)
	_tree.current_scene = placeholder
	_tree.change_scene_to_file(Game.BOOT_SCENE)
	await _wait_for_scene(Game.HOME_SCENE)
	_tree.current_scene.get_node("%Walk3DButton").pressed.emit()
	await _wait_for_scene(Game.RUN_MAP_3D_SCENE)
	await _physics(5)

	var map := _tree.current_scene as RunMap3D
	var coordinator := map.coordinator
	var dog := map.dog
	var human := map.human
	var pair := map.get_node("Encounters/pair_park") as OpponentPair3D

	_test_states_are_authored()
	await _test_body_is_articulated(human.puppet)

	# Start a fight and watch it as the player would.
	dog.global_position = pair.global_position + Vector3(1.0, 0.1, 1.0)
	await _physics(6)
	pair.interact(map.run_manager)
	await _physics(6)
	check(coordinator.is_fighting(), "the fight is on")
	var ours := human.puppet
	var theirs := pair.human_puppet

	# The humans move. This is the requirement the spec states plainly:
	# they must not stand fixed and exchange HP.
	var our_start := human.global_position
	var their_start := pair.human_global_position()
	var our_travel := 0.0
	var their_travel := 0.0
	var states: Dictionary[int, bool] = {}
	var our_previous := our_start
	var their_previous := their_start
	for i in 240:
		await _tree.physics_frame
		if not coordinator.is_fighting():
			break
		our_travel += human.global_position.distance_to(our_previous)
		their_travel += pair.human_global_position().distance_to(their_previous)
		our_previous = human.global_position
		their_previous = pair.human_global_position()
		states[int(ours.motion.state)] = true
		states[int(theirs.motion.state)] = true
	check(our_travel > 0.5, "the owner moves their feet during a fight (%.2f m)" % our_travel)
	check(their_travel > 0.5, "so does the opponent (%.2f m)" % their_travel)

	# And they do recognisably different things while doing it.
	check(states.size() >= 3, "the fight passes through several body states (%d)" % states.size())
	check(states.has(int(CombatMotion3D.State.WINDUP)), "attacks are telegraphed, which is what the dog reacts to")
	var moving_states := states.has(int(CombatMotion3D.State.APPROACH)) or states.has(int(CombatMotion3D.State.CIRCLE))
	check(moving_states, "they close the distance or work for an angle, rather than only trading blows")

	await _test_dog_pov(map, coordinator, dog, human, pair)
	await _test_intervention_is_visible(map, coordinator, dog, human, pair)
	await _test_reads_without_text(map, coordinator, dog, human, pair)
	await _test_resolution_beat(coordinator, dog, human)
	finish()


## P03-E10/E11: the fight has to read with the combat log off, and winning ends
## with the owner turning to the dog rather than with a number.
func _test_resolution_beat(coordinator: CombatCoordinator3D, dog: DogController3D, human: HumanFollower3D) -> void:
	check(not FighterPuppet3D.show_combat_text, "the combat log is off in normal play")

	if not coordinator.is_fighting():
		check(false, "expected a fight to finish")
		return
	coordinator.time_scale = 25.0
	# On the owner's far side from the opponent: with fighters circling (P-04)
	# a fixed offset can land inside the opponent, and the dog is then pushed
	# out of their body after the owner has already turned to where it was.
	var away_from_them := human.global_position - coordinator.engagement.pair.human_global_position()
	away_from_them.y = 0.0
	dog.global_position = human.global_position + away_from_them.normalized() * 2.0 + Vector3(0, 0.1, 0)
	coordinator.debug_force_result(CombatSimulation.Result.VICTORY)
	await _physics(10)
	check_eq(coordinator.last_result, CombatSimulation.Result.VICTORY, "the fight is won")
	check(human.puppet.is_distracted(), "the owner turns away from the fight, to the dog")
	var facing := Vector3.FORWARD.rotated(Vector3.UP, human.puppet.rotation.y)
	var to_dog := dog.global_position - human.global_position
	to_dog.y = 0.0
	check(facing.dot(to_dog.normalized()) > 0.5, "they are looking at the dog (%.2f)" % facing.dot(to_dog.normalized()))
	check_eq(coordinator.release_left > 0.0, true, "and the world holds the beat before walking resumes")

	# D4/P02-010, storyboard 09/10: the thanks happens from inside the dog's
	# head, with the dog's own muzzle in frame for the hand to land on.
	var rig := (_tree.current_scene as RunMap3D).rig
	check(coordinator.is_acknowledging(), "the owner is thanking the dog")
	check_eq(rig.context, CameraRig3D.Context.AFFECTION, "and the camera stays with the two of them")
	# Moving into the dog's eyes is a blend, so give it the moment it takes.
	await _wait_until(func() -> bool: return rig.pov > 0.9, 120)
	check(rig.pov > 0.9, "still through the dog's eyes")
	check(dog.first_person_view != null and dog.first_person_view.visible, "the dog's own muzzle is in frame")
	# Watch the whole beat at once: the hand goes out and the head dips under it
	# within the same couple of seconds, so sampling them in sequence misses one.
	var reaching := Greybox.part(human.puppet._body, "ArmL")
	var reached := 0.0
	var dipped := 0.0
	for i in 150:
		await _tree.physics_frame
		reached = maxf(reached, absf(reaching.rotation.x))
		dipped = maxf(dipped, absf(dog.first_person_view.position.y))
	check(reached > 0.5, "the owner reaches a hand out to the dog (%.2f rad)" % reached)
	check(dipped > 0.01, "and the dog's head dips under it (%.3f m)" % dipped)
	await _wait_until(func() -> bool: return rig.context == CameraRig3D.Context.EXPLORE, 400)
	check(not dog.first_person_view.visible, "afterwards the muzzle leaves the frame with the camera")


## P03-E07/E08: from inside the dog's head, the player has to be able to SEE
## that barking and pulling did something. Text on the screen does not count.
func _test_intervention_is_visible(map: RunMap3D, coordinator: CombatCoordinator3D, dog: DogController3D, human: HumanFollower3D, pair: OpponentPair3D) -> void:
	if not coordinator.is_fighting():
		dog.global_position = pair.global_position + Vector3(1.0, 0.1, 1.0)
		await _physics(6)
		pair.interact(map.run_manager)
		await _physics(6)
	check(coordinator.is_fighting(), "a fight to intervene in")
	coordinator.time_scale = 0.0
	var sim := coordinator.engagement.simulation
	var theirs := pair.human_puppet
	var ours := human.puppet

	# A bark turns the opponent's head away from the fight, towards the dog.
	# Beside the fight, square to the line between them: the line turns as they
	# circle (P-04), so a fixed offset can land where they already face.
	var to_owner := human.global_position - pair.human_global_position()
	to_owner.y = 0.0
	var beside := to_owner.normalized().cross(Vector3.UP)
	dog.global_position = pair.human_global_position() + beside * 2.5 + Vector3(0, 0.1, 0)
	await _physics(4)
	check(not theirs.is_distracted(), "they are watching the person they are fighting")
	var facing_before := theirs.rotation.y
	sim.distract(CombatSimulation.OPPONENT, 0.9)
	await _physics(20)
	check(theirs.is_distracted(), "the bark takes their attention")
	check(absf(angle_difference(theirs.rotation.y, facing_before)) > 0.1, "and their body turns towards the dog")
	var towards_dog := (dog.global_position - pair.human_global_position()).normalized()
	var their_facing := Vector3.FORWARD.rotated(Vector3.UP, theirs.rotation.y)
	check(their_facing.dot(towards_dog) > 0.5, "they are looking at the dog, not past it")
	await _physics(70)
	check(not theirs.is_distracted(), "and then they go back to the fight")

	# A leash pull that saves the owner moves the owner's body.
	var them := sim.fighters[CombatSimulation.OPPONENT]
	them.action = preload("res://data/combat/skills/skill_kick.tres")
	them.phase = CombatFighter.Phase.WINDUP
	them.phase_time_left = 5.0
	# P04-10: the owner is really hauled back across the ground, and leans into
	# being dragged while it happens.
	var owner_at := human.global_position
	check(sim.pull(CombatSimulation.PLAYER, DogAgency.PULL_DISTANCE * CombatCoordinator3D.UNITS_PER_METER), "the pull catches the wind-up")
	var scale_before := coordinator.time_scale
	coordinator.time_scale = 1.0
	var leaned := 0.0
	var hauled := 0.0
	# The lean is a tween, and tweens advance on process frames: sample those,
	# or its short peak can fall between two physics frames.
	for i in 30:
		await _tree.process_frame
		leaned = maxf(leaned, ours._body.rotation.x)
		hauled = maxf(hauled, _flat(human.global_position - owner_at).length())
	coordinator.time_scale = scale_before
	check(hauled > 0.5, "the owner is hauled back across the ground (%.2f m)" % hauled)
	check(leaned > 0.15, "leaning into being dragged (%.2f rad)" % leaned)
	them.phase = CombatFighter.Phase.IDLE
	them.action = null
	await _physics(30)

	# A bad pull looks like a mistake, not like a save.
	sim.stumble(CombatSimulation.PLAYER, 0.6)
	var lurched := 0.0
	var staggered := false
	for i in 30:
		await _tree.physics_frame
		lurched = maxf(lurched, absf(ours._body.rotation.z))
		# The stagger hold is shorter than this window, so record it as it
		# happens rather than asking once it is already over.
		staggered = staggered or ours.motion.state == CombatMotion3D.State.STUMBLE
	check(lurched > 0.05, "a bad pull throws the owner off balance sideways (%.3f rad)" % lurched)
	check(staggered, "and reads as the worse outcome while it lasts")
	coordinator.time_scale = 25.0


## P04-11: with fight text off (normal play) nothing explains the fight in
## words — no health bars, no outcome toasts, no line announcing an opening —
## and how each fighter is doing shows in their body instead.
func _test_reads_without_text(map: RunMap3D, coordinator: CombatCoordinator3D, dog: DogController3D, human: HumanFollower3D, pair: OpponentPair3D) -> void:
	if not coordinator.is_fighting():
		dog.global_position = pair.global_position + Vector3(1.0, 0.1, 1.0)
		await _physics(6)
		pair.interact(map.run_manager)
		await _physics(6)
	check(coordinator.is_fighting(), "a fight to read")
	check(not FighterPuppet3D.show_combat_text, "fight text is off in normal play")
	coordinator.time_scale = 0.0
	await _physics(2)
	var ours := human.puppet
	var theirs := pair.human_puppet
	check(not ours._hp_label.visible and not theirs._hp_label.visible, "no health bars over the fighters")

	# A bark that lands: it shows in their bodies, not in words.
	var agency := map.get_node("DogAgency") as DogAgency
	var hud := map.get_node("RunHUD")
	var to_owner := human.global_position - pair.human_global_position()
	to_owner.y = 0.0
	dog.global_position = pair.human_global_position() + to_owner.normalized().cross(Vector3.UP) * 2.0 + Vector3(0, 0.1, 0)
	dog.facing = (pair.human_global_position() - dog.global_position).normalized()
	agency.recent_barks.clear()
	agency.barks_heard = 0
	var toasts_before: int = hud._toast_queue.size()
	human._bubble.text = ""
	check_eq(agency.bark(), DogAgency.BarkResult.DISTRACTED, "the bark lands")
	check(human._bubble.text.is_empty(), "the owner does not announce the opening")
	check_eq(hud._toast_queue.size(), toasts_before, "and no toast explains it")
	await _physics(10)
	check(theirs.is_distracted(), "their body turns to the dog instead")

	# The debug switch puts it all back, without changing the fight.
	FighterPuppet3D.show_combat_text = true
	await _physics(2)
	check(ours._hp_label.visible and theirs._hp_label.visible, "debug: health bars come back with fight text on")
	FighterPuppet3D.show_combat_text = false
	await _physics(2)

	# How they are doing, in the body: hurt, they stoop and their guard drops;
	# near the end they sway.
	if ours._pose_tween != null:
		ours._pose_tween.kill()
	ours._reset_pose()
	ours.set_guard(false)
	ours.motion.state = CombatMotion3D.State.CIRCLE
	ours.set_hp_ratio(1.0)
	var fresh_lean := 0.0
	for i in 20:
		ours.play_motion(1.0 / 60.0)
		fresh_lean = maxf(fresh_lean, ours._body.rotation.x)
	ours.set_hp_ratio(0.12)
	var hurt_lean := 0.0
	var sway := 0.0
	for i in 60:
		ours._time += 1.0 / 60.0
		ours.play_motion(1.0 / 60.0)
		hurt_lean = maxf(hurt_lean, ours._body.rotation.x)
		sway = maxf(sway, absf(ours._body.rotation.z))
	check(hurt_lean > fresh_lean + 0.12, "a badly hurt fighter stoops (%.2f against %.2f rad)" % [hurt_lean, fresh_lean])
	check(sway > 0.03, "and sways on their feet (%.2f rad)" % sway)
	ours.set_hp_ratio(1.0)
	coordinator.time_scale = 25.0


## P03-E04/E05/E06: the Combat Snap drops the camera into the dog's eyes, tracks
## the fight from there, and comes back out afterwards (ADR-015).
func _test_dog_pov(map: RunMap3D, coordinator: CombatCoordinator3D, dog: DogController3D, human: HumanFollower3D, pair: OpponentPair3D) -> void:
	var rig := map.rig
	if not coordinator.is_fighting():
		dog.global_position = pair.global_position + Vector3(1.0, 0.1, 1.0)
		await _physics(6)
		pair.interact(map.run_manager)
		await _physics(6)
	check(coordinator.is_fighting(), "a fight to watch")
	coordinator.time_scale = 0.0

	# Before the first blow the camera is still the chase shot.
	coordinator.blows_landed = 0
	await _physics(60)
	check_eq(rig.context, CameraRig3D.Context.TENSION, "tension first")
	check(rig.pov < 0.2, "the dog is still on screen while the fight builds (pov %.2f)" % rig.pov)
	var chase_position := rig.global_position

	# The snap: blows land, and the camera moves into the dog's head.
	coordinator.blows_landed = 1
	await _physics(90)
	check_eq(rig.context, CameraRig3D.Context.ACTIVE, "blows landing means the fight proper")
	check(rig.pov > 0.9, "the camera is looking through the dog's eyes (pov %.2f)" % rig.pov)
	check(rig.global_position.distance_to(dog.eye_position()) < 0.25, "and it sits at the dog's eye, not behind it")
	check(rig.global_position.distance_to(chase_position) > 0.5, "which is somewhere else entirely from the chase shot")
	check(not dog._visual.visible, "the dog's own body is not filling the lens")

	# It watches the fight, biased towards the owner, without being told to.
	var centre := rig.combat_center()
	var owner_head := human.global_position + Vector3(0, 1.1, 0)
	var opponent_head := pair.human_global_position() + Vector3(0, 1.1, 0)
	# The point the camera watches is at the height of the people fighting, not
	# floating above their heads.
	check(absf(centre.y - owner_head.y) < 0.3, "the fight is watched at head height (%.2f vs %.2f)" % [centre.y, owner_head.y])
	check(centre.distance_to(owner_head) < centre.distance_to(opponent_head), "the fight is watched from the owner's side")
	var aim := -rig.global_basis.z
	var to_centre := centre - rig.global_position
	var flat_aim := Vector3(aim.x, 0, aim.z).normalized()
	var flat_centre := Vector3(to_centre.x, 0, to_centre.z).normalized()
	check(flat_aim.dot(flat_centre) > 0.9, "the camera is pointed at the fight")
	# P03-E12: close up it looks no higher than the cap, so it sees bodies and
	# not sky and chins (shake adds a little).
	check(rad_to_deg(asin(clampf(aim.y, -1.0, 1.0))) <= rig.pov_max_look_up + 3.0, "and does not crane up at the sky (%.0f°)" % rad_to_deg(asin(clampf(aim.y, -1.0, 1.0))))

	# Pushing forward must go where the player is looking. In first person the
	# boom is behind their eyes and means nothing; reading the stick against it
	# sends the dog somewhere else and the player backs away without meaning to.
	var view := rig.view_yaw()
	var screen_forward := Vector3.FORWARD.rotated(Vector3.UP, view)
	check(absf(angle_difference(view, rig.yaw)) > 0.15, "in first person the view has left the boom behind")
	var to_fight := rig.combat_center() - dog.global_position
	to_fight.y = 0.0
	check(screen_forward.dot(to_fight.normalized()) > 0.6, "and the view is pointed at the fight")
	# The fighters are bodies (ADR-016), so walking at them from a metre away
	# can end against one of them. Step back along the view so there is room.
	var before := dog.global_position
	dog.global_position = before - to_fight.normalized() * 2.5
	dog.velocity = Vector3.ZERO
	await _physics(20)
	view = rig.view_yaw()
	screen_forward = Vector3.FORWARD.rotated(Vector3.UP, view)
	var start := dog.global_position
	Input.action_press(&"move_up")
	for i in 30:
		await _tree.physics_frame
	Input.action_release(&"move_up")
	var travelled := dog.global_position - start
	travelled.y = 0.0
	check(travelled.length() > 0.2, "the dog actually moves")
	check(travelled.normalized().dot(screen_forward) > 0.7, "pushing forward walks into the screen, not away from it")
	dog.global_position = before
	dog.velocity = Vector3.ZERO
	await _physics(4)

	# The snap is a blend, not a cut: it never jumps.
	coordinator.blows_landed = 0
	var largest := 0.0
	var previous := rig.global_position
	for i in 90:
		await _tree.physics_frame
		largest = maxf(largest, rig.global_position.distance_to(previous))
		previous = rig.global_position
	check(largest < 0.3, "coming back out is a blend, not a cut (largest step %.3f m)" % largest)
	check(rig.pov < 0.2, "and the camera is back behind the dog")
	check(dog._visual.visible, "which means the dog can be seen again")
	coordinator.time_scale = 25.0


## The states the spec asks for, and the reaction hold that makes a hit read.
func _test_states_are_authored() -> void:
	for required: String in ["IDLE_COMBAT", "APPROACH", "CIRCLE", "WINDUP", "ATTACK", "BLOCK", "DODGE", "HIT_LIGHT", "HIT_HEAVY", "STAGGER", "STUMBLE", "DOWN", "RECOVER"]:
		check(CombatMotion3D.State.keys().has(required), "the spec's %s state exists" % required)

	var motion := CombatMotion3D.new()
	var balance := DataRegistry.balance
	var fighter := CombatFighter.new(preload("res://data/combat/fighters/opp01_jogger.tres"), 0, balance)
	motion.update(0.1, fighter, true, false)
	check_eq(motion.state, CombatMotion3D.State.APPROACH, "far away and free: they close in")
	motion.update(0.1, fighter, false, false)
	check_eq(motion.state, CombatMotion3D.State.CIRCLE, "in range and free: they work for an angle")

	# A hit holds the body for its own moment rather than flickering back.
	motion.react(CombatMotion3D.State.HIT_LIGHT)
	motion.update(0.01, fighter, false, false)
	check_eq(motion.state, CombatMotion3D.State.HIT_LIGHT, "a hit reads as a hit")
	motion.update(CombatMotion3D.REACT_SECONDS, fighter, false, false)
	motion.update(0.01, fighter, false, false)
	check_eq(motion.state, CombatMotion3D.State.CIRCLE, "and then the fight takes the body back")
	motion.react(CombatMotion3D.State.STAGGER)
	motion.update(0.01, fighter, false, false)
	check_eq(motion.state, CombatMotion3D.State.STAGGER, "a stagger reads as worse than a hit")
	check(CombatMotion3D.STAGGER_SECONDS > CombatMotion3D.REACT_SECONDS, "and holds longer")
	# P04-07: a heavy blow holds the body longer than a jab, and a stumble
	# longest of all.
	for pair: Array in [[CombatMotion3D.State.HIT_HEAVY, CombatMotion3D.HEAVY_SECONDS], [CombatMotion3D.State.STUMBLE, CombatMotion3D.STUMBLE_SECONDS]]:
		motion.update(1.0, fighter, false, false)
		motion.react(pair[0])
		motion.update(0.01, fighter, false, false)
		check_eq(motion.state, pair[0], "%s is a state the body shows" % CombatMotion3D.State.keys()[pair[0]])
		check(motion.is_committed(), "and the fight does not take the body back during it")
	check(CombatMotion3D.REACT_SECONDS < CombatMotion3D.HEAVY_SECONDS and CombatMotion3D.HEAVY_SECONDS < CombatMotion3D.STUMBLE_SECONDS, "light < heavy < stumble")
	motion.update(1.0, fighter, false, false)

	motion.update(0.01, fighter, false, true)
	check_eq(motion.state, CombatMotion3D.State.DOWN, "being defeated overrides everything")
	check(motion.is_committed(), "and the body is not free")


## The body has joints, and a strike moves a limb rather than sliding the whole
## figure. Without this a fall can only ever tip the figure over like a plank.
func _test_body_is_articulated(puppet: FighterPuppet3D) -> void:
	var body := puppet._body
	for joint_name: String in ["Hips", "Torso", "Head", "ArmL", "ArmR", "LegL", "LegR"]:
		check(Greybox.part(body, joint_name) != null, "the body has a %s joint" % joint_name)
	var head := Greybox.part(body, "Head")
	var torso := Greybox.part(body, "Torso")
	var hips := Greybox.part(body, "Hips")
	if body is P04HumanVisual:
		# Codex's skeletal model: the joints are controls that drive its bones
		# (the face and hair are part of the mesh). A control has to move its
		# bone, or the fight's choreography would pose nothing. Checked on a
		# model of its own: the walking owner is playing its Idle clip.
		var probe := P04HumanVisual.new()
		add_child(probe)
		probe.use_legacy_controls()
		var bone := probe.skeleton.find_bone("head")
		var rest := probe.skeleton.get_bone_pose_rotation(bone)
		(probe.controls["Head"] as Node3D).rotation.x = 0.5
		probe._process(1.0 / 60.0)
		var turned := probe.skeleton.get_bone_pose_rotation(bone).angle_to(rest)
		check(turned > 0.2, "Codex's model: turning the Head control turns the head bone (%.2f rad)" % turned)
		probe.queue_free()
		check(Greybox.part(body, "Head") != null and hips != null and torso != null, "and the choreography's joints are all reachable")
	else:
		check(torso.is_ancestor_of(head), "the head hangs off the torso")
		check(torso.is_ancestor_of(Greybox.part(body, "ArmR")), "and so do the arms")
		check(is_equal_approx(hips.position.y, Greybox.HIP_HEIGHT), "the hips sit at hip height")
		# Art decoration added in plain world coordinates ends up on the right
		# part, so the face and hair travel with the head instead of staying behind.
		check(head.get_child_count() >= 4, "the head carries its own face and hair (%d pieces)" % head.get_child_count())

	# A punch swings an arm; it does not just shove the whole body forward.
	var arm := Greybox.part(body, "ArmR")
	arm.rotation = Vector3.ZERO
	puppet.play_windup(preload("res://data/combat/skills/skill_jab.tres"))
	await _physics(20)
	check(absf(arm.rotation.x) > 0.1, "the wind-up draws the arm back (%.2f rad)" % arm.rotation.x)
	puppet._reset_pose()
	var jab_turn := absf(torso.rotation.y)

	# P04-04: a hook loads the whole upper body — shoulders and hips turn away
	# and the arm comes up and out — so it reads from across a street.
	var hook: CombatSkillData = preload("res://data/combat/skills/skill_heavy_hook.tres")
	puppet.play_windup(hook)
	await _physics(int(hook.windup * 60.0) + 2)
	check(torso.rotation.y > 0.4, "a hook wind-up turns the shoulders away (%.2f rad)" % torso.rotation.y)
	check(hips.rotation.y > 0.15, "and the hips with them (%.2f rad)" % hips.rotation.y)
	check(arm.rotation.z > 0.8, "and the arm comes up and out to the side (%.2f rad)" % arm.rotation.z)
	check(torso.rotation.y > jab_turn + 0.2, "far more than a jab's wind-up")
	puppet.play_strike(hook)
	await _physics(int((hook.strike_time + hook.contact_time) * 60.0) + 1)
	check(torso.rotation.y < -0.3, "the strike unwinds the body through and past square (%.2f rad)" % torso.rotation.y)
	check(arm.rotation.x < -0.8, "and the arm sweeps across (%.2f rad)" % arm.rotation.x)
	await _physics(30)
	puppet._reset_pose()

	# P04-05: a kick chambers the leg up in front of them, then drives it out.
	var kick: CombatSkillData = preload("res://data/combat/skills/skill_kick.tres")
	var leg := Greybox.part(body, "LegR")
	puppet.play_windup(kick)
	await _physics(int(kick.windup * 60.0) + 2)
	check(leg.rotation.x < -0.6, "a kick wind-up lifts the leg up in front (%.2f rad)" % leg.rotation.x)
	check(torso.rotation.x > 0.15, "while the upper body leans back to balance it (%.2f rad)" % torso.rotation.x)
	puppet.play_strike(kick)
	await _physics(int((kick.strike_time + kick.contact_time) * 60.0) + 1)
	check(leg.rotation.x < -1.2, "the strike drives the leg out level (%.2f rad)" % leg.rotation.x)
	await _physics(int(kick.follow_through * 60.0) - 2)
	check(leg.rotation.x < -1.2, "and it stays out through the follow-through")
	await _physics(30)
	puppet._reset_pose()

	# P04-06: the guard stays up through a blow, and comes down when it ends.
	var block: CombatSkillData = preload("res://data/combat/skills/skill_block.tres")
	var arm_l := Greybox.part(body, "ArmL")
	puppet.play_windup(block)
	puppet.set_guard(true)
	await _physics(10)
	check(arm.rotation.x < -1.2 and arm_l.rotation.x < -1.2, "a guard puts both forearms up")
	puppet.play_hurt(true, 0.8)
	await _physics(2)
	check(arm.rotation.x < -1.0, "a blocked blow knocks the guard back, it does not drop it (%.2f rad)" % arm.rotation.x)
	await _physics(25)
	check(arm.rotation.x < -1.2, "and the guard sets again (%.2f rad)" % arm.rotation.x)
	puppet.set_guard(false)
	await _physics(12)
	check(arm.rotation.x > -0.3, "when the block ends the guard comes down (%.2f rad)" % arm.rotation.x)

	# P04-07: each blow gets its own answer.
	puppet.play_hurt(false, 0.3, &"punch")
	await _physics(2)
	check(head.rotation.x < -0.2, "a jab snaps the head back (%.2f rad)" % head.rotation.x)
	await _physics(30)
	puppet.play_hurt(false, 0.8, &"hook")
	await _physics(4)
	check(absf(puppet._body.rotation.y) > 0.3, "a hook turns the body with it (%.2f rad)" % puppet._body.rotation.y)
	check(absf(head.rotation.y) > 0.25, "and the head further (%.2f rad)" % head.rotation.y)
	await _physics(30)
	puppet.play_hurt(false, 0.9, &"kick")
	await _physics(4)
	check(torso.rotation.x > 0.25, "a kick folds them over it (%.2f rad)" % torso.rotation.x)
	await _physics(30)

	# A dodge's body answer leans away; it does not slide the figure sideways
	# (the simulation has already moved them for real).
	puppet.play_evade()
	await _physics(5)
	check(absf(puppet._body.position.x) < 0.01, "a dodge does not fake a sideways slide")
	check(puppet._body.rotation.x < -0.1, "it snaps back from the blow (%.2f rad)" % puppet._body.rotation.x)
	await _physics(30)
	puppet._reset_pose()


func _wait_until(done: Callable, max_frames: int) -> void:
	for i in max_frames:
		if done.call():
			return
		await _tree.physics_frame
	check(false, "timed out waiting")


func _physics(frames: int) -> void:
	for i in frames:
		await _tree.physics_frame


func _wait_for_scene(path: String) -> void:
	for i in 300:
		await _tree.process_frame
		if _tree.current_scene != null and _tree.current_scene.scene_file_path == path:
			await _tree.process_frame
			return
	check(false, "timed out waiting for scene %s" % path)


func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)
