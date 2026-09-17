class_name FighterPuppet
extends Node2D
## Placeholder human figure used by the owner and opponent pairs. Presentation
## only: it plays what CombatCoordinator tells it and never decides anything.

const HIT_COLOR: Color = Color(1.0, 0.35, 0.3)

var data: FighterData
var facing: float = 1.0

var _time: float = 0.0
var _down: bool = false
var _pose_tween: Tween
var _popup_tween: Tween

@onready var _visual: Node2D = %Visual
@onready var _front_leg: Polygon2D = %FrontLeg
@onready var _back_leg: Polygon2D = %BackLeg
@onready var _body: Polygon2D = %Body
@onready var _head: Polygon2D = %Head
@onready var _hair: Polygon2D = %Hair
@onready var _arm: Polygon2D = %Arm
@onready var _guard: Polygon2D = %Guard
@onready var _hp_bar: ProgressBar = %HPBar
@onready var _popup: Label = %Popup


func _ready() -> void:
	_popup.hide()
	if data != null:
		apply(data)


func apply(fighter: FighterData) -> void:
	data = fighter
	if not is_node_ready():
		return
	_head.color = fighter.skin_color
	_arm.color = fighter.skin_color
	_hair.color = fighter.hair_color
	_body.color = fighter.shirt_color
	_front_leg.color = fighter.pants_color
	_back_leg.color = fighter.pants_color
	set_facing(facing)


func set_facing(direction: float) -> void:
	facing = signf(direction) if direction != 0.0 else 1.0
	if not is_node_ready() or data == null:
		return
	_visual.scale = Vector2(data.body_scale.x * facing, data.body_scale.y)
	_reset_pose()


func show_hp(value: bool) -> void:
	_hp_bar.visible = value


## Ratio only: never show numbers that reveal strength.
func set_hp_ratio(ratio: float) -> void:
	_hp_bar.value = ratio
	if ratio > 0.5:
		_hp_bar.modulate = Color(0.5, 1.0, 0.5)
	elif ratio > 0.25:
		_hp_bar.modulate = Color(1.0, 0.85, 0.3)
	else:
		_hp_bar.modulate = Color(1.0, 0.4, 0.35)


func set_guard(active: bool) -> void:
	_guard.visible = active and not _down
	if _guard.visible:
		_arm.rotation = -2.2


func _process(delta: float) -> void:
	_time += delta
	if not _down and (_pose_tween == null or not _pose_tween.is_running()):
		_visual.position.y = sin(_time * 6.0) * 1.5


# --- Skill animations (keyed by CombatSkillData.animation_key) ---------------

func play_windup(skill: CombatSkillData) -> void:
	_popup_text(skill.display_name, Color.WHITE)
	var tween := _new_pose_tween()
	match skill.animation_key:
		&"punch":
			tween.tween_property(_visual, "position:x", -8.0 * facing, skill.windup)
			tween.parallel().tween_property(_arm, "rotation", -1.0, skill.windup)
		&"kick":
			tween.tween_property(_visual, "rotation", _lean() - 0.25 * facing, skill.windup)
			tween.parallel().tween_property(_front_leg, "rotation", -0.6, skill.windup)
		&"block":
			tween.tween_property(_arm, "rotation", -2.2, 0.05)
		&"dodge":
			tween.tween_property(_visual, "rotation", _lean() - 0.35 * facing, 0.08)


func play_strike(skill: CombatSkillData) -> void:
	var tween := _new_pose_tween()
	match skill.animation_key:
		&"kick":
			tween.tween_property(_visual, "position:x", 22.0 * facing, 0.08)
			tween.parallel().tween_property(_front_leg, "rotation", -1.6, 0.08)
			tween.tween_interval(0.15)
		_:
			tween.tween_property(_visual, "position:x", 16.0 * facing, 0.06)
			tween.parallel().tween_property(_arm, "rotation", -1.57, 0.06)
			tween.tween_interval(0.08)
	tween.tween_callback(_reset_pose)


func play_hurt(blocked: bool) -> void:
	var tween := _new_pose_tween()
	_visual.modulate = Color(0.6, 0.8, 1.0) if blocked else HIT_COLOR
	tween.tween_property(_visual, "position:x", -10.0 * facing, 0.05)
	tween.tween_property(_visual, "modulate", Color.WHITE, 0.2)
	tween.parallel().tween_property(_visual, "position:x", 0.0, 0.2)
	if blocked:
		_popup_text("擋住！", Color(0.6, 0.85, 1.0))


func play_evade() -> void:
	_popup_text("閃過！", Color(0.7, 1.0, 0.7))


func play_miss() -> void:
	_popup_text("落空", Color(0.8, 0.8, 0.8))


func play_stagger() -> void:
	_popup_text("被打斷！", Color(1.0, 0.7, 0.3))
	var tween := _new_pose_tween()
	tween.tween_property(_visual, "rotation", _lean() - 0.3 * facing, 0.08)
	tween.tween_property(_visual, "rotation", _lean(), 0.25)


func play_down() -> void:
	_down = true
	_guard.hide()
	var tween := _new_pose_tween()
	tween.tween_property(_visual, "rotation", -1.45 * facing, 0.35).set_trans(Tween.TRANS_BOUNCE)
	tween.parallel().tween_property(_visual, "position:y", -6.0, 0.35)


func play_victory() -> void:
	var tween := _new_pose_tween()
	tween.tween_property(_arm, "rotation", -2.9, 0.2)
	tween.tween_property(_visual, "position:y", -18.0, 0.15)
	tween.tween_property(_visual, "position:y", 0.0, 0.15)


## Sitting on the ground after losing (world pair).
func set_beaten(beaten: bool) -> void:
	_down = beaten
	_visual.rotation = -0.5 * facing if beaten else _lean()
	modulate = Color(0.7, 0.7, 0.7) if beaten else Color.WHITE


func is_down() -> bool:
	return _down


## Back on their feet (after a fight or a new walk).
func revive() -> void:
	_down = false
	modulate = Color.WHITE
	if _pose_tween != null:
		_pose_tween.kill()
	_reset_pose()


func shout(text: String, color: Color = Color.WHITE) -> void:
	_popup_text(text, color)


func _reset_pose() -> void:
	if _down:
		return
	_visual.position = Vector2.ZERO
	_visual.rotation = _lean()
	_visual.modulate = Color.WHITE
	_arm.rotation = 0.0
	_front_leg.rotation = 0.0
	_guard.hide()


## Resting forward lean (older people stoop), mirrored with facing.
func _lean() -> float:
	return data.stoop * facing if data != null else 0.0


func _new_pose_tween() -> Tween:
	if _pose_tween != null:
		_pose_tween.kill()
	_reset_pose()
	_pose_tween = create_tween()
	return _pose_tween


func _popup_text(text: String, color: Color) -> void:
	if _popup_tween != null:
		_popup_tween.kill()
	_popup.text = text
	_popup.modulate = color
	_popup.position.y = -190.0
	_popup.self_modulate.a = 1.0
	_popup.show()
	_popup_tween = create_tween()
	_popup_tween.tween_property(_popup, "position:y", -220.0, 0.6).set_ease(Tween.EASE_OUT)
	_popup_tween.parallel().tween_property(_popup, "self_modulate:a", 0.0, 0.4).set_delay(0.35)
	_popup_tween.tween_callback(_popup.hide)
