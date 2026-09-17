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


func apply(fighter: FighterData) -> void:
	data = fighter
	if _body != null:
		_body.queue_free()
	_body = Greybox.human(fighter.shirt_color, fighter.pants_color, fighter.hair_color, fighter.skin_color)
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
	_popup_left -= delta
	if _popup != null and _popup_left <= 0.0:
		_popup.text = ""


func face_towards(point: Vector3) -> void:
	var d := point - global_position
	if Vector2(d.x, d.z).length() > 0.01:
		rotation.y = atan2(-d.x, -d.z)


func show_hp(value: bool) -> void:
	if _hp_label != null:
		_hp_label.visible = value


## Ratio only: never numbers that reveal strength.
func set_hp_ratio(ratio: float) -> void:
	var filled := int(ceil(clampf(ratio, 0.0, 1.0) * 5.0))
	_hp_label.text = "■".repeat(filled) + "□".repeat(5 - filled)


func set_guard(active: bool) -> void:
	if _body != null and not _down:
		_body.position.z = 0.12 if active else _body.position.z


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


func play_hurt(blocked: bool) -> void:
	if blocked:
		shout("擋住！", Color(0.6, 0.85, 1.0))
	var tween := _new_tween()
	tween.tween_property(_body, "position:z", 0.25, 0.05)
	tween.tween_property(_body, "position:z", 0.0, 0.2)


func play_evade() -> void:
	shout("閃過！", Color(0.7, 1.0, 0.7))


func play_miss() -> void:
	shout("落空", Color(0.8, 0.8, 0.8))


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
