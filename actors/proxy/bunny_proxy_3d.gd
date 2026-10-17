class_name BunnyProxy3D
extends Node3D
## Xiaomi toy proxy (docs/04_systems/XIAOMI_TOY_PROXY.md): the bunny toy robot
## that comes out of her backpack when a fight starts and is the only body on
## her side of it. CombatCoordinator3D places it from the simulation exactly as
## it places a fighting owner, and drives `puppet` the same way; this node only
## adds what a toy does around the fight — popping out, a shutdown when the
## battery runs flat, packing itself away.

## Seconds the pop-out / pack-away takes.
const DEPLOY_SECONDS: float = 0.35
const STOW_SECONDS: float = 0.45

var puppet: FighterPuppet3D
var fighter: FighterData
var _bubble: Label3D
var _bubble_left: float = 0.0
var _stowing: bool = false


func setup(data: FighterData) -> void:
	fighter = data
	puppet = FighterPuppet3D.new()
	add_child(puppet)
	puppet.apply(data)
	puppet.show_hp(false)
	_bubble = Greybox.label("", 1.45, 34, Color(1.0, 0.85, 0.92))
	add_child(_bubble)


func _process(delta: float) -> void:
	_bubble_left -= delta
	if _bubble != null and _bubble_left <= 0.0:
		_bubble.text = ""


## Pops out at full size from nothing (out of her backpack).
func deploy() -> void:
	scale = Vector3.ONE * 0.05
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ONE * 1.1, DEPLOY_SECONDS * 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector3.ONE, DEPLOY_SECONDS * 0.3)
	say("兔兔出動！", Color(1.0, 0.75, 0.88), 1.2)


## The battery ran flat: the fall the puppet already played, then the toy's
## own beat — eyes out, a spring popping loose. No hurt, no harm.
func shutdown() -> void:
	say("（嗶——電量耗盡）", Color(0.85, 0.85, 0.95), 2.2)


## Packs itself away and goes (back into her backpack), then frees itself.
func stow(delay: float = 0.0) -> void:
	if _stowing:
		return
	_stowing = true
	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(self, "scale", Vector3.ONE * 0.05, STOW_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)


func is_stowing() -> bool:
	return _stowing


func say(text: String, color: Color = Color.WHITE, seconds: float = 1.6) -> void:
	if _bubble == null:
		return
	_bubble.text = text
	_bubble.modulate = color
	_bubble_left = seconds
