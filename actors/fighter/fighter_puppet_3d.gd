class_name FighterPuppet3D
extends Node3D
## Greybox 3D human for the owner and opponents. Presentation only: plays what
## the combat coordinator tells it. Same method names as FighterPuppet.

## P03-E10: the combat log is debug-only. The exit gate is that a fight reads
## with this off, so it defaults off and the body has to carry the meaning.
## Deliberate dialogue still goes through `shout()`; this gates only the
## automatic annotations the puppet writes about its own mechanics.
static var show_combat_text: bool = false

## A bump from the dog was answered (ADR-016). Presentation only.
signal bumped(from: Vector3)

var data: FighterData

var _body: Node3D
var _hp_label: Label3D
var _popup: Label3D
var _popup_left: float = 0.0
var _pose_tween: Tween
var _down: bool = false
var _time: float = 0.0
## P03-E01: the body's continuous motion. Reactions and strikes are still
## tweened on top; this is what the fighter does the rest of the time, so a
## human at rest in a fight is never a statue.
var motion: CombatMotion3D = CombatMotion3D.new()
var _guarding: bool = false
var _footwork: float = 0.0
## P03-E07: while this is running the fighter is looking at whatever pulled
## their attention (the dog), not at the person they are fighting.
var _look_away_left: float = 0.0
var _look_away_point: Vector3 = Vector3.ZERO
## Joints, so a strike is an arm and a fall is a body folding (P-03).
var _hips: Node3D
var _torso: Node3D
var _head: Node3D
var _arms: Array[Node3D] = []
var _legs: Array[Node3D] = []


func apply(fighter: FighterData) -> void:
	data = fighter
	if _body != null:
		_body.queue_free()
	_body = HumanModular3D.build(fighter)
	# Art adds its pieces to the root in plain world coordinates; put each one
	# on the body part it sits on so limbs carry their own clothing.
	Greybox.bind_parts(_body)
	_body.scale = Vector3(fighter.body_scale.x, fighter.body_scale.y, fighter.body_scale.x)
	add_child(_body)
	_hips = Greybox.part(_body, "Hips")
	_torso = Greybox.part(_body, "Torso")
	_head = Greybox.part(_body, "Head")
	_arms = [Greybox.part(_body, "ArmL"), Greybox.part(_body, "ArmR")]
	_legs = [Greybox.part(_body, "LegL"), Greybox.part(_body, "LegR")]
	if _hp_label == null:
		_hp_label = Greybox.label("", 2.25, 36, Color(1, 0.6, 0.5))
		add_child(_hp_label)
		_popup = Greybox.label("", 2.6, 44, Color(1, 1, 0.75))
		add_child(_popup)
	_down = false
	_reset_pose()


func _process(delta: float) -> void:
	_time += delta
	_look_away_left = maxf(_look_away_left - delta, 0.0)
	_popup_left -= delta
	if _popup != null and _popup_left <= 0.0:
		_popup.text = ""


func face_towards(point: Vector3) -> void:
	var target := _look_away_point if _look_away_left > 0.0 else point
	var d := target - global_position
	if Vector2(d.x, d.z).length() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-d.x, -d.z), 0.35)


func show_hp(value: bool) -> void:
	if _hp_label != null:
		_hp_label.visible = value


## Ratio only: never numbers that reveal strength.
func set_hp_ratio(ratio: float) -> void:
	var filled := int(ceil(clampf(ratio, 0.0, 1.0) * 5.0))
	_hp_label.text = "■".repeat(filled) + "□".repeat(5 - filled)


func set_guard(active: bool) -> void:
	_guarding = active


## Drives the body from its motion state. Called every frame by the coordinator.
func play_motion(delta: float) -> void:
	if _body == null or _down or _pose_tween != null and _pose_tween.is_running():
		return
	var quick := motion.state in [CombatMotion3D.State.APPROACH, CombatMotion3D.State.SIDESTEP, CombatMotion3D.State.BACKSTEP]
	_footwork += delta * (7.0 if quick else 4.2)
	var bob := 0.0
	var lean := 0.0
	var guard := 0.06 if _guarding else 0.0
	match motion.state:
		CombatMotion3D.State.IDLE_COMBAT:
			bob = sin(_footwork) * 0.012
			lean = 0.03
		CombatMotion3D.State.APPROACH:
			# Weight forward and a quicker step: they are coming for you.
			bob = absf(sin(_footwork)) * 0.035
			lean = 0.10
		CombatMotion3D.State.CIRCLE:
			# Stepping round the other person, looking for an angle. The
			# simulation moves them; this is just the feet.
			bob = absf(sin(_footwork)) * 0.022
			lean = 0.05
		CombatMotion3D.State.SIDESTEP:
			# A quick step off the line, weight dropped into it.
			bob = absf(sin(_footwork)) * 0.03 - 0.03
			lean = 0.07
		CombatMotion3D.State.BACKSTEP:
			# Weight back, getting out of range.
			bob = absf(sin(_footwork)) * 0.03
			lean = -0.1
		CombatMotion3D.State.RECOVER:
			# Off balance and open — the moment a dog's bark is worth most.
			bob = sin(_footwork * 0.6) * 0.01
			lean = -0.08
		_:
			return
	_body.position.y = bob
	_body.rotation.x = lean
	_body.position.z = guard
	_body.position.x = move_toward(_body.position.x, 0.0, delta * 0.4)


## The telegraph: the limb that is about to strike draws back, and the body
## turns into it. This is what the player and the dog are reading.
func play_windup(skill: CombatSkillData) -> void:
	_log(skill.display_name)
	var tween := _new_tween()
	match skill.animation_key:
		&"kick":
			# P04-05: the leg chambers — it comes up off the ground in front
			# of them while the upper body leans back to balance it. Standing
			# on one leg is the commitment the dog can read.
			var leg := _joint(_legs, 1)
			if leg != null:
				tween.tween_property(leg, "rotation:x", -0.8, skill.windup).set_trans(Tween.TRANS_SINE)
			if _torso != null:
				tween.parallel().tween_property(_torso, "rotation:x", 0.22, skill.windup)
			if _hips != null:
				tween.parallel().tween_property(_hips, "rotation:x", 0.12, skill.windup)
		&"block":
			for arm in _arms:
				if arm != null:
					tween.parallel().tween_property(arm, "rotation:x", -1.5, 0.12)
		&"dodge":
			if _torso != null:
				tween.tween_property(_torso, "rotation:z", 0.4, 0.1)
		&"hook":
			# P04-04: the whole upper body loads up. Shoulders and hips turn
			# away and the arm comes up and out to the side — it has to be
			# readable from across a street, because it is the blow worth
			# barking at.
			var arm := _joint(_arms, 1)
			if arm != null:
				tween.tween_property(arm, "rotation:z", 1.15, skill.windup).set_trans(Tween.TRANS_SINE)
				tween.parallel().tween_property(arm, "rotation:x", 0.35, skill.windup)
			if _torso != null:
				tween.parallel().tween_property(_torso, "rotation:y", 0.55, skill.windup).set_trans(Tween.TRANS_SINE)
			if _hips != null:
				tween.parallel().tween_property(_hips, "rotation:y", 0.25, skill.windup)
		_:
			var arm := _joint(_arms, 1)
			if arm != null:
				tween.tween_property(arm, "rotation:x", 0.75, skill.windup).set_trans(Tween.TRANS_SINE)
			if _torso != null:
				tween.parallel().tween_property(_torso, "rotation:y", -0.25, skill.windup)


## The strike itself: the limb swings through, the body follows it, and only
## then does everything settle back.
func play_strike(skill: CombatSkillData) -> void:
	if skill.animation_key == &"hook":
		_play_hook_strike(skill)
		return
	if skill.animation_key == &"kick":
		_play_kick_strike(skill)
		return
	var tween := _new_tween()
	var kick := skill.animation_key == &"kick"
	var limb := _joint(_legs if kick else _arms, 1)
	if limb != null:
		tween.tween_property(limb, "rotation:x", -1.2 if kick else -1.45, 0.08).set_trans(Tween.TRANS_QUAD)
	if _torso != null:
		tween.parallel().tween_property(_torso, "rotation:y", 0.3, 0.08)
		tween.parallel().tween_property(_torso, "rotation:x", -0.12 if kick else 0.0, 0.08)
	tween.parallel().tween_property(_body, "position:z", -0.2 if kick else -0.12, 0.08)
	tween.tween_interval(0.08)
	tween.tween_callback(_reset_pose)


## The kick extends from the chamber: the leg drives out level, the hips go
## in behind it and the upper body leans away, and it stays out through the
## follow-through before the foot comes back down.
func _play_kick_strike(skill: CombatSkillData) -> void:
	var tween := _new_tween()
	var out := skill.strike_time + skill.contact_time
	var leg := _joint(_legs, 1)
	if leg != null:
		leg.rotation.x = -0.8
		tween.tween_property(leg, "rotation:x", -1.45, out).set_trans(Tween.TRANS_QUAD)
	if _torso != null:
		_torso.rotation.x = 0.22
		tween.parallel().tween_property(_torso, "rotation:x", 0.32, out)
	if _hips != null:
		tween.parallel().tween_property(_hips, "rotation:x", 0.2, out)
	tween.parallel().tween_property(_body, "position:z", -0.2, out)
	tween.tween_interval(skill.follow_through)
	tween.tween_callback(_reset_pose)


## The hook swings across rather than out: the arm sweeps round at shoulder
## height and the shoulders and hips unwind through it, past square.
func _play_hook_strike(skill: CombatSkillData) -> void:
	var tween := _new_tween()
	# `_new_tween` squares the body up; start from the loaded wind-up pose.
	var arm := _joint(_arms, 1)
	if arm != null:
		arm.rotation = Vector3(0.35, 0.0, 1.15)
		tween.tween_property(arm, "rotation:x", -1.1, skill.strike_time + skill.contact_time).set_trans(Tween.TRANS_QUAD)
	if _torso != null:
		_torso.rotation.y = 0.55
		tween.parallel().tween_property(_torso, "rotation:y", -0.6, skill.strike_time + skill.contact_time).set_trans(Tween.TRANS_QUAD)
	if _hips != null:
		_hips.rotation.y = 0.25
		tween.parallel().tween_property(_hips, "rotation:y", -0.3, skill.strike_time + skill.contact_time)
	tween.tween_interval(skill.follow_through)
	tween.tween_callback(_reset_pose)


## `weight` is 0..1 for how hard the hit was, so a jab and a kick into an
## opening do not knock someone back the same distance (Gate 02 feel pass).
## `twist` turns them with the blow (a hook comes from the side).
func play_hurt(blocked: bool, weight: float = 0.5, twist: float = 0.0) -> void:
	if blocked:
		_log("擋住！", Color(0.6, 0.85, 1.0))
	var amount := lerpf(0.14, 0.45, clampf(weight, 0.0, 1.0))
	var tween := _new_tween()
	tween.tween_property(_body, "position:z", amount, 0.05)
	tween.tween_property(_body, "position:z", 0.0, lerpf(0.16, 0.3, weight))
	if weight >= 0.75 and not blocked:
		tween.parallel().tween_property(_body, "rotation:x", -0.22, 0.06)
		tween.tween_property(_body, "rotation:x", 0.0, 0.24)
	if twist != 0.0:
		var turn := twist * (0.4 if blocked else 1.0)
		tween.parallel().tween_property(_body, "rotation:y", turn, 0.06)
		tween.tween_property(_body, "rotation:y", 0.0, 0.3)


## P03-E07: a bark landed. They turn to look at it and their guard opens — the
## opening the owner is about to use has to be visible, not just announced.
func play_distracted(towards: Vector3, seconds: float) -> void:
	_look_away_point = towards
	_look_away_left = maxf(seconds, 0.25)
	_log("什麼？！", Color(1.0, 0.9, 0.5))
	if _body == null or _down:
		return
	var tween := _new_tween()
	tween.tween_property(_body, "rotation:x", -0.16, 0.1)
	tween.parallel().tween_property(_body, "position:z", -0.08, 0.1)
	tween.tween_interval(maxf(seconds - 0.3, 0.05))
	tween.tween_property(_body, "rotation:x", 0.0, 0.2)
	tween.parallel().tween_property(_body, "position:z", 0.0, 0.2)


## P03-E08: the leash yanked them. `saved` is a clean pull out of an attack;
## otherwise it is just a shove in that direction.
func play_pulled(saved: bool) -> void:
	if _body == null or _down:
		return
	var back := 0.42 if saved else 0.2
	var tween := _new_tween()
	tween.tween_property(_body, "position:z", back, 0.09).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(_body, "rotation:x", 0.2, 0.09)
	tween.tween_property(_body, "position:z", 0.0, 0.28)
	tween.parallel().tween_property(_body, "rotation:x", 0.0, 0.28)


## P03-E08: dragged the wrong way and off balance. Deliberately uglier than a
## pull — a bad pull should look like a mistake.
func play_stumble() -> void:
	if _body == null or _down:
		return
	var tween := _new_tween()
	tween.tween_property(_body, "rotation:z", 0.4, 0.12)
	tween.parallel().tween_property(_body, "position:x", 0.28, 0.12)
	tween.parallel().tween_property(_body, "position:y", -0.1, 0.12)
	tween.tween_property(_body, "rotation:z", 0.0, 0.34)
	tween.parallel().tween_property(_body, "position:x", 0.0, 0.34)
	tween.parallel().tween_property(_body, "position:y", 0.0, 0.34)


## ADR-016: the dog ran into them. They give a little, away from the dog, and
## glance down at it, then settle. Never a fall and never damage, and it gives
## way to anything the fight is already doing with this body.
func play_bumped(from: Vector3) -> void:
	if _body == null or _down or motion.is_committed():
		return
	if _pose_tween != null and _pose_tween.is_running():
		return
	var presence := DataRegistry.presence
	var shift := presence.minor_balance_shift if presence != null else 0.08
	var settle := presence.minor_balance_seconds if presence != null else 0.35
	var away := global_position - from
	away.y = 0.0
	away = away.normalized() if away.length_squared() > 0.0001 else -global_basis.z
	# `_body` hangs off this node, so the give is expressed in its own space.
	var local := global_basis.inverse() * away
	var tween := _new_tween()
	tween.tween_property(_body, "position", Vector3(local.x, 0.0, local.z) * shift, 0.07).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(_body, "rotation:z", -local.x * 0.14, 0.07)
	if _head != null:
		tween.parallel().tween_property(_head, "rotation:x", -0.3, 0.07)
	tween.tween_property(_body, "position", Vector3.ZERO, settle)
	tween.parallel().tween_property(_body, "rotation:z", 0.0, settle)
	if _head != null:
		tween.parallel().tween_property(_head, "rotation:x", 0.0, settle)
	bumped.emit(from)


## True while this fighter is looking away from the fight (P03-E07).
func is_distracted() -> bool:
	return _look_away_left > 0.0


## A dodge is a body moving out of the way, not a word on the screen.
func play_evade() -> void:
	_log("閃過！", Color(0.7, 1.0, 0.7))
	var tween := _new_tween()
	tween.tween_property(_body, "position:x", 0.32, 0.09).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(_body, "rotation:z", 0.22, 0.09)
	tween.tween_property(_body, "position:x", 0.0, 0.2)
	tween.parallel().tween_property(_body, "rotation:z", 0.0, 0.2)


## A swing that hits nothing still travels, and overreaches.
func play_miss() -> void:
	_log("落空", Color(0.8, 0.8, 0.8))
	var tween := _new_tween()
	tween.tween_property(_body, "rotation:y", 0.34, 0.1)
	tween.tween_property(_body, "rotation:y", 0.0, 0.26)


func play_stagger() -> void:
	_log("被打斷！", Color(1.0, 0.7, 0.3))
	var tween := _new_tween()
	tween.tween_property(_body, "rotation:x", -0.3, 0.08)
	tween.tween_property(_body, "rotation:x", 0.0, 0.25)


## Storyboard 08: they go down, and stay down on the ground. The legs give way
## first and the body folds over them, rather than the whole figure tipping
## like a board.
func play_down() -> void:
	_down = true
	var tween := _new_tween()
	for leg in _legs:
		if leg != null:
			tween.parallel().tween_property(leg, "rotation:x", 1.35, 0.22).set_trans(Tween.TRANS_QUAD)
	if _hips != null:
		# Towards the ground, not below it: this is the joint's height, not a delta.
		tween.parallel().tween_property(_hips, "position:y", Greybox.HIP_HEIGHT - 0.46, 0.3).set_trans(Tween.TRANS_QUAD)
		tween.parallel().tween_property(_hips, "rotation:x", -1.15, 0.34).set_trans(Tween.TRANS_SINE)
	if _torso != null:
		tween.parallel().tween_property(_torso, "rotation:x", -0.35, 0.36)
	if _head != null:
		tween.parallel().tween_property(_head, "rotation:x", 0.55, 0.4)
	# One arm out towards the dog, which is what frame 08 is actually about.
	var arm := _joint(_arms, 0)
	if arm != null:
		tween.parallel().tween_property(arm, "rotation:x", -2.1, 0.4).set_trans(Tween.TRANS_SINE)


func play_victory() -> void:
	var tween := _new_tween()
	tween.tween_property(_body, "position:y", 0.3, 0.15)
	tween.tween_property(_body, "position:y", 0.0, 0.15)


## P03-E11 (storyboard 09/10): the owner turns to the dog and crouches to it.
## The fight is over; the point of the beat is that it was for the dog.
func play_acknowledge(towards: Vector3) -> void:
	_look_away_point = towards
	_look_away_left = 2.2
	if _body == null or _down:
		return
	# The fight is over, so nothing else turns them any more: they turn round
	# to the dog themselves, whichever side of them it ended up on.
	var to_dog := towards - global_position
	if Vector2(to_dog.x, to_dog.z).length() > 0.01:
		var yaw := atan2(-to_dog.x, -to_dog.z)
		var turn := create_tween()
		turn.tween_property(self, "rotation:y", rotation.y + angle_difference(rotation.y, yaw), 0.12).set_trans(Tween.TRANS_SINE)
	var tween := _new_tween()
	tween.tween_property(_body, "position:y", 0.22, 0.14).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_body, "position:y", 0.0, 0.16)
	# Down onto their haunches, and a hand out towards the dog. From inside the
	# dog's head that hand is the whole beat (storyboard 09/10).
	if _hips != null:
		tween.tween_property(_hips, "position:y", Greybox.HIP_HEIGHT - 0.3, 0.3).set_trans(Tween.TRANS_SINE)
		tween.parallel().tween_property(_hips, "rotation:x", -0.3, 0.3)
	for leg in _legs:
		if leg != null:
			tween.parallel().tween_property(leg, "rotation:x", 0.7, 0.3)
	var arm := _joint(_arms, 0)
	if arm != null:
		tween.parallel().tween_property(arm, "rotation:x", -1.7, 0.36).set_trans(Tween.TRANS_SINE)
	if _head != null:
		tween.parallel().tween_property(_head, "rotation:x", -0.2, 0.3)
	tween.tween_interval(0.9)
	tween.tween_callback(_reset_pose)


func set_beaten(beaten: bool) -> void:
	_down = beaten
	if _pose_tween != null:
		_pose_tween.kill()
	_body.rotation.x = -PI / 2.0 if beaten else 0.0
	_body.position.y = 0.2 if beaten else 0.0


func revive() -> void:
	_down = false
	if _pose_tween != null:
		_pose_tween.kill()
	_reset_pose()


## An automatic note about this fighter's own mechanics: shown only when the
## combat log is turned on in the debug panel.
func _log(text: String, color: Color = Color(1, 1, 0.75)) -> void:
	if show_combat_text:
		shout(text, color)


func shout(text: String, color: Color = Color(1, 1, 0.75)) -> void:
	_popup.text = text
	_popup.modulate = color
	_popup_left = 0.9


func set_faded(faded: bool) -> void:
	Greybox.set_faded(_body, faded, 0.28)


## A named limb, or null when the body has not been built with joints.
func _joint(limbs: Array[Node3D], index: int) -> Node3D:
	return limbs[index] if index < limbs.size() else null


func _reset_pose() -> void:
	if _down or _body == null:
		return
	_body.position = Vector3.ZERO
	_body.rotation = Vector3(data.stoop if data != null else 0.0, 0, 0)
	# Limbs too, or each action starts from wherever the last one left them.
	for joint: Node3D in _arms + _legs:
		if joint != null:
			joint.rotation = Vector3.ZERO
	if _torso != null:
		_torso.rotation = Vector3.ZERO
	if _head != null:
		_head.rotation = Vector3.ZERO
	if _hips != null:
		_hips.rotation = Vector3.ZERO
		_hips.position.y = Greybox.HIP_HEIGHT


func _new_tween() -> Tween:
	if _pose_tween != null:
		_pose_tween.kill()
	_reset_pose()
	_pose_tween = create_tween()
	return _pose_tween
