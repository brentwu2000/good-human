class_name FighterPuppet3D
extends Node3D
## Greybox 3D human for the owner and opponents. Presentation only: plays what
## the combat coordinator tells it. Same method names as FighterPuppet.

## P03-E10 / P04-11: every piece of fight text that explains the mechanics —
## the combat log, the health bars, the dog's outcome toasts and the lines
## that announce an opening or a save — is debug-only. The P-04 gate is that
## a fight reads with all of it off, so it defaults off and the bodies carry
## the meaning. Story dialogue at the start and end of a fight is not
## affected.
static var show_combat_text: bool = false

## A bump from the dog was answered (ADR-016). Presentation only.
signal bumped(from: Vector3)

## Codex's authored combat clips (P-04 + ART), by attack, reaction and footwork.
## P05-04: until Codex's D5W-02 umbrella motion, the umbrella's poke rides
## the jab (the arm thrusts out) and its swing the hook (the arm sweeps across).
const ATTACK_CLIPS := {&"punch": "Jab", &"hook": "HeavyHook", &"kick": "Kick", &"poke": "Thrust", &"swing": "HeavyHook", &"smash": "Jab"}
## The hand a weapon is held in: the lead hand, the one the jab clip drives.
const WEAPON_HAND := "hand_l"
const REACTION_CLIPS := {
	CombatMotion3D.State.HIT_LIGHT: "HitLight",
	CombatMotion3D.State.HIT_HEAVY: "HitHeavy",
	CombatMotion3D.State.STAGGER: "HitHeavy",
	CombatMotion3D.State.STUMBLE: "Stumble",
}
const FOOTWORK_CLIPS := {
	CombatMotion3D.State.APPROACH: "Approach",
	CombatMotion3D.State.CIRCLE: "Circle",
	CombatMotion3D.State.SIDESTEP: "Circle",
	CombatMotion3D.State.BACKSTEP: "Backstep",
}
## Owner, 2026-10-07 (「打鬥的方式太生硬」): fighting-game style clips —
## a bladed, bouncing stance, footwork that keeps it, blows with weight
## transfer, whole-body reactions. Each P-04 clip name maps to its fight clip
## and the other side's (the cross for a jab thrown off the rear hand, and so
## on); used when the model has the fight library, else the first-pass clips.
const FIGHT_CLIPS := {
	"Jab": ["Fight_Jab", "Fight_Cross"],
	"Thrust": ["Fight_Thrust", "Fight_Thrust"],
	"HeavyHook": ["Fight_Hook", "Fight_Hook_Rear"],
	"Kick": ["Fight_Kick", "Fight_Kick_Lead"],
	"HitLight": ["Fight_HitLight", "Fight_HitLight"],
	"HitHeavy": ["Fight_HitHeavy", "Fight_HitHeavy"],
	"Block": ["Fight_Block", "Fight_Block"],
	"Dodge": ["Fight_Dodge", "Fight_Dodge"],
	"Idle": ["Fight_Stance", "Fight_Stance"],
	"Approach": ["Fight_Step_Fwd", "Fight_Step_Fwd"],
	"Circle": ["Fight_Circle", "Fight_Circle"],
	"Backstep": ["Fight_Step_Back", "Fight_Step_Back"],
}
## How strongly the P-04 choreography's joint accents layer over the clips:
## light now, the fight clips carry the body themselves.
const COMBAT_LAYER: float = 0.2

## P02-008: how the fight is going for them, as their body shows it.
enum Condition { HEALTHY, HURT, CRITICAL, DOWN }
const HURT_AT: float = 0.6
const CRITICAL_AT: float = 0.3
## Critical: every so often they falter for a moment (hesitation).
const HESITATE_EVERY: float = 2.2
const HESITATE_SECONDS: float = 0.35

var data: FighterData

var _body: Node3D
## Codex's skeletal model (P04HumanVisual) plays its authored Walk / Idle /
## Down clips outside the fight's procedural choreography; this is the one
## playing, or empty while the choreography drives the joints.
var _ambient_clip: String = ""
## Owner, 2026-10-06 (「戰鬥動作太單一」): which side an attack comes from.
## Jabs alternate hands through a combination (a jab, then the rear-hand
## cross); hooks and kicks come off either side. Presentation only.
var _mirrored_attack: bool = false
## The arm or leg (index into `_arms` / `_legs`) and the turn direction the
## choreography uses for the current attack.
var _limb: int = 1
var _turn: float = 1.0
var _last_jab_at: float = -9.0
var _side_rng := RandomNumberGenerator.new()
## P-05: what they are holding, and the prop showing it.
var held: WeaponData
var _prop: Node3D
var _hp_label: Label3D
## The fight wants the health bar shown; it only is with fight text on.
var _hp_wanted: bool = false
## 0..1 how the fighter is doing (P04-11): shown by the body, not a bar.
var _condition: float = 1.0
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
	# A dedicated model is built at its own size; body_scale shapes the shared one.
	var own_model := fighter.skeletal_model != null and _body is P04HumanVisual
	_body.scale = Vector3.ONE if own_model else Vector3(fighter.body_scale.x, fighter.body_scale.y, fighter.body_scale.x)
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
	_condition = 1.0
	_reset_pose()
	var holding := held
	held = null
	_prop = null
	hold(holding)


## P-05: puts `weapon` in their lead hand (null: empty-handed). A skeletal
## body carries it on the hand bone, so it follows every clip; the greybox
## carries it at the end of the arm.
func hold(weapon: WeaponData, condition: WeaponCondition.State = WeaponCondition.State.GOOD) -> void:
	if weapon == held and (_prop != null) == (weapon != null and not weapon.is_unarmed()):
		show_condition(condition)
		return
	held = weapon
	if _prop != null:
		var mount := _prop.get_parent()
		if mount is BoneAttachment3D:
			mount.queue_free()
		else:
			_prop.queue_free()
		_prop = null
	_prop = WeaponProp3D.build(weapon)
	if _prop == null or _body == null:
		return
	show_condition(condition)
	var skeletal := _body as P04HumanVisual
	if skeletal != null and skeletal.skeleton != null and skeletal.skeleton.find_bone(WEAPON_HAND) >= 0:
		var grip := BoneAttachment3D.new()
		grip.bone_name = WEAPON_HAND
		skeletal.skeleton.add_child(grip)
		grip.add_child(_prop)
		return
	var arm := _joint(_arms, 1)
	if arm != null:
		_prop.position = Vector3(0, -0.55, 0)
		_prop.rotation.x = -PI * 0.5
		arm.add_child(_prop)


## P05-09 (D5W-07): how worn it is reads on the object itself.
func show_condition(condition: WeaponCondition.State) -> void:
	if _prop != null:
		WeaponProp3D.show_condition(_prop, condition)


func _process(delta: float) -> void:
	_time += delta
	if _hp_label != null:
		_hp_label.visible = _hp_wanted and show_combat_text
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
	_hp_wanted = value
	if _hp_label != null:
		_hp_label.visible = value and show_combat_text


## Ratio only: never numbers that reveal strength.
func set_hp_ratio(ratio: float) -> void:
	_condition = clampf(ratio, 0.0, 1.0)
	var filled := int(ceil(clampf(ratio, 0.0, 1.0) * 5.0))
	_hp_label.text = "■".repeat(filled) + "□".repeat(5 - filled)


## 0 while they are fine, rising to 1 as they near the end: from 60 % health
## down (P04-11).
func hurt_amount() -> float:
	return clampf(inverse_lerp(0.6, 0.1, _condition), 0.0, 1.0)


## P02-008 (COMBAT_EMOTIONAL_FEEDBACK): the stage the body is showing.
func condition_state() -> Condition:
	if _down:
		return Condition.DOWN
	if _condition <= CRITICAL_AT:
		return Condition.CRITICAL
	if _condition <= HURT_AT:
		return Condition.HURT
	return Condition.HEALTHY


func set_guard(active: bool) -> void:
	# P04-06: the guard comes down when the block ends, not whenever the
	# next action happens to reset the pose.
	var lowered := _guarding and not active
	_guarding = active
	if not lowered or _down:
		return
	var raised := _arms.filter(func(arm: Node3D) -> bool: return arm != null and arm.rotation.x < -0.8)
	if raised.is_empty():
		return
	var drop := create_tween().set_parallel()
	for arm: Node3D in raised:
		drop.tween_property(arm, "rotation:x", 0.0, 0.12).set_trans(Tween.TRANS_SINE)


## Outside a fight: Codex's model walks or stands with its authored clips.
## Anything the body is already doing (a bump, the win beat) finishes first.
func set_ambient(moving: bool) -> void:
	var skeletal := _body as P04HumanVisual
	if skeletal == null or _down:
		return
	if _pose_tween != null and _pose_tween.is_running():
		return
	var clip := skeletal.ambient_clip(moving)
	if _ambient_clip == clip:
		return
	_ambient_clip = clip
	skeletal.play_clip(clip)
	# A bump or a growth reaction still shows over the walk.
	skeletal.use_clip_layer(1.0)


## In a fight Codex's authored combat clips carry the body, timed by the
## simulation (`drive_combat_clip`), and the P-04 choreography layers its
## accents over them at COMBAT_LAYER.
func set_fighting() -> void:
	_ambient_clip = ""
	var skeletal := _body as P04HumanVisual
	if skeletal != null:
		skeletal.use_clip_layer(COMBAT_LAYER)


## Codex's attack clips peak exactly halfway through (authored as an out-and-
## back strike). The first half is spread over the wind-up and strike, so the
## peak lands as the contact window opens; the second half over contact,
## follow-through and recovery. Blocks, dodges, hit reactions and footwork
## follow the same state the choreography reads. Called every frame by the
## coordinator during a fight.
func drive_combat_clip(fighter: CombatFighter) -> void:
	var skeletal := _body as P04HumanVisual
	if skeletal == null or _down:
		return
	var reaction := motion.reaction_progress()
	if reaction >= 0.0:
		skeletal.pose_clip(_clip(skeletal, REACTION_CLIPS.get(motion.reacting_state(), "HitLight"), false), reaction)
		return
	var skill := fighter.action
	if skill != null and skill.effect == CombatSkillData.Effect.ATTACK and not fighter.is_idle():
		var clip: String = ATTACK_CLIPS.get(skill.animation_key, "Jab")
		skeletal.pose_clip(_clip(skeletal, clip, _mirrored_attack), _attack_progress(fighter, skill))
		return
	if fighter.is_guarding():
		skeletal.pose_clip(_clip(skeletal, "Block", false), 0.5)
		return
	if fighter.is_evading() and skill != null:
		skeletal.pose_clip(_clip(skeletal, "Dodge", false), 1.0 - fighter.phase_time_left / maxf(skill.active_time, 0.01))
		return
	var loop := _clip(skeletal, FOOTWORK_CLIPS.get(motion.state, "Idle"), false)
	if skeletal.player.current_animation != loop or skeletal.player.speed_scale == 0.0:
		skeletal.play_clip(loop)
		skeletal.use_clip_layer(COMBAT_LAYER)


## The clip to play for P-04 clip `clip`: its fight version (the other side's
## when `other_side`), else the first-pass clip, mirrored if asked.
func _clip(skeletal: P04HumanVisual, clip: String, other_side: bool) -> String:
	var pair: Array = FIGHT_CLIPS.get(clip, [])
	if not pair.is_empty():
		var fight := skeletal.fight_clip(pair[1] if other_side else pair[0])
		if not fight.is_empty():
			return fight
	# A move only the fight clips have falls back to the jab.
	if skeletal.player == null or not skeletal.player.has_animation(clip):
		clip = "Jab"
	return skeletal.mirrored(clip) if other_side else clip


## 0..1 through an attack's clip: 0.5 is the moment its contact window opens.
static func _attack_progress(fighter: CombatFighter, skill: CombatSkillData) -> float:
	var lead := maxf(skill.windup + skill.strike_time, 0.01)
	var after := maxf(skill.contact_time + skill.follow_through + skill.recovery, 0.01)
	var left := fighter.phase_time_left
	match fighter.phase:
		CombatFighter.Phase.WINDUP:
			return 0.5 * (skill.windup - left) / lead
		CombatFighter.Phase.STRIKE:
			return 0.5 * (skill.windup + skill.strike_time - left) / lead
		CombatFighter.Phase.CONTACT:
			return 0.5 + 0.5 * (skill.contact_time - left) / after
		CombatFighter.Phase.FOLLOW_THROUGH:
			return 0.5 + 0.5 * (skill.contact_time + skill.follow_through - left) / after
		CombatFighter.Phase.RECOVERY:
			# A whiff makes recovery longer than authored: never go backwards.
			var done := maxf(skill.contact_time + skill.follow_through + skill.recovery - left, skill.contact_time + skill.follow_through)
			return 0.5 + 0.5 * minf(done / after, 1.0)
	return 0.0


## Drives the body from its motion state. Called every frame by the coordinator.
func play_motion(delta: float) -> void:
	if _body == null or _down or _pose_tween != null and _pose_tween.is_running():
		return
	var quick := motion.state in [CombatMotion3D.State.APPROACH, CombatMotion3D.State.SIDESTEP, CombatMotion3D.State.BACKSTEP]
	# P04-11: a hurt fighter moves heavily, so who is losing reads without a bar.
	var hurt := hurt_amount()
	_footwork += delta * (7.0 if quick else 4.2) * lerpf(1.0, 0.65, hurt)
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
			# Hurt, they take longer to come back from it (P02-008).
			bob = sin(_footwork * 0.6) * 0.01
			lean = -0.08 - hurt * 0.1
		_:
			return
	# P02-008 / P04-11: the body shows how the fight is going for them, not a
	# bar. Hurt, they breathe hard, stoop and pull their guard in tight and
	# their feet get heavy. Critical, the guard sags with fatigue, they sway,
	# and now and then they falter for a moment before going on.
	var state := condition_state()
	var hesitating := state == Condition.CRITICAL and fmod(_time, HESITATE_EVERY) < HESITATE_SECONDS
	if hesitating:
		bob = 0.0
	lean += hurt * 0.2
	if state == Condition.CRITICAL:
		guard *= 0.4
	bob *= 1.0 + hurt * 0.6
	_body.position.y = bob
	_body.rotation.x = lean + (data.stoop if data != null else 0.0)
	_body.rotation.z = sin(_time * 2.4) * 0.07 * smoothstep(0.55, 1.0, hurt)
	_body.position.z = guard
	_body.position.x = move_toward(_body.position.x, 0.0, delta * 0.4)
	var breathing := 0.0 if state == Condition.HEALTHY else 1.0
	if _torso != null:
		_torso.rotation.x = sin(_time * lerpf(2.2, 4.6, hurt)) * 0.05 * breathing
	if _head != null:
		_head.rotation.x = 0.28 if hesitating else 0.0
	if not _guarding:
		# Arms drawn in to protect themselves while hurt; hanging once spent.
		var tucked := 1.0 if state == Condition.HURT else 0.0
		for arm in _arms:
			if arm != null:
				arm.rotation.x = -0.5 * tucked


## The telegraph: the limb that is about to strike draws back, and the body
## turns into it. This is what the player and the dog are reading.
func play_windup(skill: CombatSkillData) -> void:
	_log(skill.display_name)
	_choose_side(skill)
	var tween := _new_tween()
	match skill.animation_key:
		&"kick":
			# P04-05: the leg chambers — it comes up off the ground in front
			# of them while the upper body leans back to balance it. Standing
			# on one leg is the commitment the dog can read.
			var leg := _joint(_legs, _limb)
			if leg != null:
				tween.tween_property(leg, "rotation:x", -0.8, skill.windup).set_trans(Tween.TRANS_SINE)
			if _torso != null:
				tween.parallel().tween_property(_torso, "rotation:x", 0.22, skill.windup)
			if _hips != null:
				tween.parallel().tween_property(_hips, "rotation:x", 0.12, skill.windup)
		&"block", &"umbrella_guard":
			for arm in _arms:
				if arm != null:
					tween.parallel().tween_property(arm, "rotation:x", -1.5, 0.12)
		&"dodge":
			if _torso != null:
				tween.tween_property(_torso, "rotation:z", 0.4 * _turn, 0.1)
		&"smash":
			# P05-06: the dumbbell goes up over the head and the body leans
			# back under it — the longest, plainest telegraph in the game.
			var arm := _joint(_arms, _limb)
			if arm != null:
				tween.tween_property(arm, "rotation:x", -2.6, skill.windup).set_trans(Tween.TRANS_SINE)
			if _torso != null:
				tween.parallel().tween_property(_torso, "rotation:x", -0.25, skill.windup)
		&"hook", &"swing":
			# P04-04: the whole upper body loads up. Shoulders and hips turn
			# away and the arm comes up and out to the side — it has to be
			# readable from across a street, because it is the blow worth
			# barking at.
			var arm := _joint(_arms, _limb)
			if arm != null:
				tween.tween_property(arm, "rotation:z", 1.15 * _turn, skill.windup).set_trans(Tween.TRANS_SINE)
				tween.parallel().tween_property(arm, "rotation:x", 0.35, skill.windup)
			if _torso != null:
				tween.parallel().tween_property(_torso, "rotation:y", 0.55 * _turn, skill.windup).set_trans(Tween.TRANS_SINE)
			if _hips != null:
				tween.parallel().tween_property(_hips, "rotation:y", 0.25 * _turn, skill.windup)
		_:
			var arm := _joint(_arms, _limb)
			if arm != null:
				tween.tween_property(arm, "rotation:x", 0.75, skill.windup).set_trans(Tween.TRANS_SINE)
			if _torso != null:
				tween.parallel().tween_property(_torso, "rotation:y", -0.25 * _turn, skill.windup)


## Which side this attack comes off. A jab soon after another is the other
## hand, so a combination reads as one-two; otherwise the lead hand. Hooks and
## kicks come off either side.
func _choose_side(skill: CombatSkillData) -> void:
	var armed := held != null and not held.is_unarmed()
	match skill.animation_key if not armed or skill.animation_key == &"kick" else &"":
		&"punch":
			_mirrored_attack = not _mirrored_attack if _time - _last_jab_at < 1.5 else false
			_last_jab_at = _time
		&"hook", &"kick":
			# Holding something, the hook is thrown with it, from its side.
			_mirrored_attack = _side_rng.randf() < 0.5
		_:
			# Weapon moves come from the hand that holds it.
			_mirrored_attack = false
	_limb = 0 if _mirrored_attack else 1
	_turn = -1.0 if _mirrored_attack else 1.0


## The strike itself: the limb swings through, the body follows it, and only
## then does everything settle back.
func play_strike(skill: CombatSkillData) -> void:
	if skill.animation_key in [&"hook", &"swing"]:
		_play_hook_strike(skill)
		return
	if skill.animation_key == &"smash":
		_play_smash_strike(skill)
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
		tween.parallel().tween_property(_torso, "rotation:y", 0.3 * _turn, 0.08)
		tween.parallel().tween_property(_torso, "rotation:x", -0.12 if kick else 0.0, 0.08)
	tween.parallel().tween_property(_body, "position:z", -0.2 if kick else -0.12, 0.08)
	tween.tween_interval(0.08)
	tween.tween_callback(_reset_pose)


## P05-06: the smash comes down from over the head, the body folding after
## it, and stays down through the long follow-through.
func _play_smash_strike(skill: CombatSkillData) -> void:
	var tween := _new_tween()
	var out := skill.strike_time + skill.contact_time
	var arm := _joint(_arms, _limb)
	if arm != null:
		arm.rotation.x = -2.6
		tween.tween_property(arm, "rotation:x", -0.6, out).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if _torso != null:
		_torso.rotation.x = -0.25
		tween.parallel().tween_property(_torso, "rotation:x", 0.35, out)
	tween.parallel().tween_property(_body, "position:z", -0.12, out)
	tween.tween_interval(skill.follow_through)
	tween.tween_callback(_reset_pose)


## The kick extends from the chamber: the leg drives out level, the hips go
## in behind it and the upper body leans away, and it stays out through the
## follow-through before the foot comes back down.
func _play_kick_strike(skill: CombatSkillData) -> void:
	var tween := _new_tween()
	var out := skill.strike_time + skill.contact_time
	var leg := _joint(_legs, _limb)
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
	var arm := _joint(_arms, _limb)
	if arm != null:
		arm.rotation = Vector3(0.35, 0.0, 1.15 * _turn)
		tween.tween_property(arm, "rotation:x", -1.1, skill.strike_time + skill.contact_time).set_trans(Tween.TRANS_QUAD)
	if _torso != null:
		_torso.rotation.y = 0.55 * _turn
		tween.parallel().tween_property(_torso, "rotation:y", -0.6 * _turn, skill.strike_time + skill.contact_time).set_trans(Tween.TRANS_QUAD)
	if _hips != null:
		_hips.rotation.y = 0.25 * _turn
		tween.parallel().tween_property(_hips, "rotation:y", -0.3 * _turn, skill.strike_time + skill.contact_time)
	tween.tween_interval(skill.follow_through)
	tween.tween_callback(_reset_pose)


## `weight` is 0..1 for how hard the hit was, so a jab and a kick into an
## opening do not knock someone back the same distance (Gate 02 feel pass).
## `blow` is the attack's animation key: each blow is answered differently
## (P04-07) — a jab snaps the head back, a hook turns the body with it, a
## kick folds them over it.
func play_hurt(blocked: bool, weight: float = 0.5, blow: StringName = &"") -> void:
	if blocked:
		_log("擋住！", Color(0.6, 0.85, 1.0))
	var amount := lerpf(0.14, 0.45, clampf(weight, 0.0, 1.0))
	var settle := lerpf(0.16, 0.3, weight)
	var tween := _new_tween().set_parallel()
	# The impact, all at once: pushed back, plus what this blow does.
	tween.tween_property(_body, "position:z", amount, 0.05)
	if blocked:
		# P04-06: the guard stays up through the blow. The forearms take it
		# and are knocked back towards the face, then set again.
		for arm in _arms:
			if arm != null:
				arm.rotation.x = -1.5
				tween.tween_property(arm, "rotation:x", -1.15, 0.05)
		if blow == &"hook":
			tween.tween_property(_body, "rotation:y", 0.2, 0.06)
	else:
		match blow:
			&"hook":
				# From the side: the body turns with it and the head further.
				tween.tween_property(_body, "rotation:y", 0.5, 0.06)
				if _head != null:
					tween.tween_property(_head, "rotation:y", 0.45, 0.06)
			&"kick":
				# Into the body: they fold over it, hips driven back.
				if _torso != null:
					tween.tween_property(_torso, "rotation:x", 0.38, 0.06)
				if _hips != null:
					tween.tween_property(_hips, "rotation:x", -0.15, 0.06)
			_:
				# A jab: the head snaps back.
				if _head != null:
					tween.tween_property(_head, "rotation:x", -0.35, 0.04)
				if weight >= 0.75:
					tween.tween_property(_body, "rotation:x", -0.22, 0.06)
	# Then they come back from it, a heavier blow taking longer.
	tween.chain().tween_property(_body, "position:z", 0.0, settle)
	if blocked:
		for arm in _arms:
			if arm != null:
				tween.tween_property(arm, "rotation:x", -1.5, settle)
	tween.tween_property(_body, "rotation:y", 0.0, maxf(settle, 0.3))
	# Back to their own posture, not bolt upright.
	tween.tween_property(_body, "rotation:x", data.stoop if data != null else 0.0, maxf(settle, 0.24))
	if _head != null:
		tween.tween_property(_head, "rotation", Vector3.ZERO, maxf(settle, 0.18))
	if _torso != null:
		tween.tween_property(_torso, "rotation:x", 0.0, maxf(settle, 0.34))
	if _hips != null:
		tween.tween_property(_hips, "rotation:x", 0.0, maxf(settle, 0.34))


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
	# Saved: the simulation hauls them back for real (P04-10), so the body
	# only leans into being dragged. Braced: they do not move, so the jolt is
	# all body.
	var back := 0.0 if saved else 0.2
	var tween := _new_tween()
	tween.tween_property(_body, "position:z", back, 0.09).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(_body, "rotation:x", 0.3 if saved else 0.2, 0.09)
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


## A dodge is a body moving out of the way, not a word on the screen. The
## simulation has already moved them clear (P04-06); this is the body
## snapping back and away from the blow as it goes past.
func play_evade() -> void:
	_log("閃過！", Color(0.7, 1.0, 0.7))
	var tween := _new_tween()
	tween.tween_property(_body, "rotation:x", -0.28, 0.08).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(_body, "rotation:z", 0.18, 0.08)
	if _head != null:
		tween.parallel().tween_property(_head, "rotation:x", -0.2, 0.08)
	tween.tween_property(_body, "rotation:x", 0.0, 0.24)
	tween.parallel().tween_property(_body, "rotation:z", 0.0, 0.24)
	if _head != null:
		tween.parallel().tween_property(_head, "rotation:x", 0.0, 0.24)


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
	# The adapter maps joint rotations only, so the fall (which drops the hips)
	# is Codex's authored Down clip on the skeletal model.
	if _play_down_clip():
		return
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
## P05-10: a quick crouch towards something on the ground and back up with
## it in hand.
func play_pick_up(at: Vector3) -> void:
	if _body == null or _down:
		return
	var to := at - global_position
	if Vector2(to.x, to.z).length() > 0.01:
		rotation.y = atan2(-to.x, -to.z)
	var tween := _new_tween()
	if _hips != null:
		tween.tween_property(_hips, "position:y", Greybox.HIP_HEIGHT - 0.35, 0.22).set_trans(Tween.TRANS_SINE)
		tween.parallel().tween_property(_hips, "rotation:x", -0.45, 0.22)
	var arm := _joint(_arms, 1)
	if arm != null:
		tween.parallel().tween_property(arm, "rotation:x", -0.9, 0.22)
	tween.tween_interval(0.12)
	tween.tween_callback(_reset_pose)


func play_acknowledge(towards: Vector3) -> void:
	_look_away_point = towards
	_look_away_left = 2.2
	if _body == null or _down:
		return
	# The crouch and the reach are the choreography's: over the standing clip,
	# at full strength.
	var skeletal := _body as P04HumanVisual
	if skeletal != null:
		_ambient_clip = ""
		skeletal.play_clip("Idle")
		skeletal.use_clip_layer(1.0)
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
	if beaten and _play_down_clip():
		return
	_body.rotation.x = -PI / 2.0 if beaten else 0.0
	_body.position.y = 0.2 if beaten else 0.0
	if not beaten:
		set_fighting()


func revive() -> void:
	_down = false
	if _pose_tween != null:
		_pose_tween.kill()
	set_fighting()
	_reset_pose()


## Plays Codex's Down clip and holds its last frame; false for the greybox.
func _play_down_clip() -> bool:
	var skeletal := _body as P04HumanVisual
	if skeletal == null:
		return false
	if _pose_tween != null:
		_pose_tween.kill()
	_ambient_clip = "Down"
	skeletal.play_clip("Down", false)
	return true


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
