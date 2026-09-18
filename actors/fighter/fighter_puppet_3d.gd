class_name FighterPuppet3D
extends Node3D
## Greybox 3D human for the owner and opponents. Presentation only: plays what
## the combat coordinator tells it. Same method names as FighterPuppet.

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


func apply(fighter: FighterData) -> void:
	data = fighter
	if _body != null:
		_body.queue_free()
	_body = HumanModular3D.build(fighter)
	_body.scale = Vector3(fighter.body_scale.x, fighter.body_scale.y, fighter.body_scale.x)
	add_child(_body)
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
	_footwork += delta * (7.0 if motion.state == CombatMotion3D.State.APPROACH else 4.2)
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
			# Side-to-side footwork while they look for an angle.
			bob = absf(sin(_footwork)) * 0.022
			lean = 0.05
			_body.position.x = sin(_footwork * 0.5) * 0.06
		CombatMotion3D.State.RECOVER:
			# Off balance and open — the moment a dog's bark is worth most.
			bob = sin(_footwork * 0.6) * 0.01
			lean = -0.08
		_:
			return
	_body.position.y = bob
	_body.rotation.x = lean
	_body.position.z = guard
	if motion.state != CombatMotion3D.State.CIRCLE:
		_body.position.x = move_toward(_body.position.x, 0.0, delta * 0.4)


func play_windup(skill: CombatSkillData) -> void:
	shout(skill.display_name)
	var tween := _new_tween()
	match skill.animation_key:
		&"kick":
			tween.tween_property(_body, "rotation:x", 0.2, skill.windup)
		&"dodge":
			tween.tween_property(_body, "position:z", 0.4, 0.08)
		_:
			tween.tween_property(_body, "position:z", 0.12, skill.windup)


func play_strike(skill: CombatSkillData) -> void:
	var tween := _new_tween()
	var lunge := -0.45 if skill.animation_key == &"kick" else -0.3
	tween.tween_property(_body, "position:z", lunge, 0.07)
	tween.tween_interval(0.1)
	tween.tween_callback(_reset_pose)


## `weight` is 0..1 for how hard the hit was, so a jab and a kick into an
## opening do not knock someone back the same distance (Gate 02 feel pass).
func play_hurt(blocked: bool, weight: float = 0.5) -> void:
	if blocked:
		shout("擋住！", Color(0.6, 0.85, 1.0))
	var amount := lerpf(0.14, 0.45, clampf(weight, 0.0, 1.0))
	var tween := _new_tween()
	tween.tween_property(_body, "position:z", amount, 0.05)
	tween.tween_property(_body, "position:z", 0.0, lerpf(0.16, 0.3, weight))
	if weight >= 0.75 and not blocked:
		tween.parallel().tween_property(_body, "rotation:x", -0.22, 0.06)
		tween.tween_property(_body, "rotation:x", 0.0, 0.24)


## P03-E07: a bark landed. They turn to look at it and their guard opens — the
## opening the owner is about to use has to be visible, not just announced.
func play_distracted(towards: Vector3, seconds: float) -> void:
	_look_away_point = towards
	_look_away_left = maxf(seconds, 0.25)
	shout("什麼？！", Color(1.0, 0.9, 0.5))
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


## True while this fighter is looking away from the fight (P03-E07).
func is_distracted() -> bool:
	return _look_away_left > 0.0


## A dodge is a body moving out of the way, not a word on the screen.
func play_evade() -> void:
	shout("閃過！", Color(0.7, 1.0, 0.7))
	var tween := _new_tween()
	tween.tween_property(_body, "position:x", 0.32, 0.09).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(_body, "rotation:z", 0.22, 0.09)
	tween.tween_property(_body, "position:x", 0.0, 0.2)
	tween.parallel().tween_property(_body, "rotation:z", 0.0, 0.2)


## A swing that hits nothing still travels, and overreaches.
func play_miss() -> void:
	shout("落空", Color(0.8, 0.8, 0.8))
	var tween := _new_tween()
	tween.tween_property(_body, "rotation:y", 0.34, 0.1)
	tween.tween_property(_body, "rotation:y", 0.0, 0.26)


func play_stagger() -> void:
	shout("被打斷！", Color(1.0, 0.7, 0.3))
	var tween := _new_tween()
	tween.tween_property(_body, "rotation:x", -0.3, 0.08)
	tween.tween_property(_body, "rotation:x", 0.0, 0.25)


func play_down() -> void:
	_down = true
	var tween := _new_tween()
	tween.tween_property(_body, "rotation:x", -PI / 2.0, 0.35).set_trans(Tween.TRANS_BOUNCE)
	tween.parallel().tween_property(_body, "position:y", 0.2, 0.35)


func play_victory() -> void:
	var tween := _new_tween()
	tween.tween_property(_body, "position:y", 0.3, 0.15)
	tween.tween_property(_body, "position:y", 0.0, 0.15)


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


func shout(text: String, color: Color = Color(1, 1, 0.75)) -> void:
	_popup.text = text
	_popup.modulate = color
	_popup_left = 0.9


func set_faded(faded: bool) -> void:
	Greybox.set_faded(_body, faded, 0.28)


func _reset_pose() -> void:
	if _down or _body == null:
		return
	_body.position = Vector3.ZERO
	_body.rotation = Vector3(data.stoop if data != null else 0.0, 0, 0)


func _new_tween() -> Tween:
	if _pose_tween != null:
		_pose_tween.kill()
	_reset_pose()
	_pose_tween = create_tween()
	return _pose_tween
