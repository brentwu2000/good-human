class_name ProtoOpponent
extends Node3D
## P-01 greybox opponent pair with a seamless fight proxy: the dog provokes,
## the humans fight where they stand, the dog stays free, running far enough
## away disengages. Numbers are placeholders; only framing is under test.

signal fight_started
signal fight_ended(result: StringName)

enum State { IDLE, COMBAT, RETURNING, BEATEN }

const PROVOKE_DISTANCE: float = 1.8
const STRIKE_RANGE: float = 1.1
const STRIKE_INTERVAL: float = 0.75
const DISENGAGE_DISTANCE: float = 9.0

var state: State = State.IDLE
var owner_actor: ProtoOwner
var dog: ProtoDog
var home: Vector3
var owner_hp: float = 100.0
var opponent_hp: float = 100.0

var _human: Node3D
var _small_dog: Node3D
var _hp_label: Label3D
var _pop: Label3D
var _pop_left: float = 0.0
var _strike_left: float = 0.0
var _turn: int = 0


func _ready() -> void:
	home = global_position
	_human = ProtoShapes.human(Color(0.95, 0.75, 0.15), Color(0.3, 0.3, 0.3), Color(0.1, 0.1, 0.1))
	add_child(_human)
	_small_dog = Node3D.new()
	_small_dog.add_child(ProtoShapes.box(Vector3(0.3, 0.28, 0.6), Color(0.15, 0.15, 0.17), Vector3(0, 0.34, 0)))
	_small_dog.add_child(ProtoShapes.box(Vector3(0.24, 0.24, 0.26), Color(0.18, 0.18, 0.2), Vector3(0, 0.54, -0.36)))
	_small_dog.position = Vector3(0.7, 0, 0.3)
	add_child(_small_dog)
	add_child(ProtoShapes.label("外送員和阿黑", 2.1, 36))
	_hp_label = ProtoShapes.label("", 2.45, 40, Color(1, 0.6, 0.5))
	add_child(_hp_label)
	_pop = ProtoShapes.label("", 2.8, 56, Color(1, 1, 0.7))
	add_child(_pop)


func human_position() -> Vector3:
	return _human.global_position


func can_provoke() -> bool:
	return state == State.IDLE and dog != null and owner_actor != null and owner_actor.state == ProtoOwner.State.FOLLOW \
		and dog.global_position.distance_to(human_position()) <= PROVOKE_DISTANCE


func provoke() -> bool:
	if not can_provoke():
		return false
	state = State.COMBAT
	owner_hp = 100.0
	opponent_hp = 100.0
	_turn = 0
	_strike_left = STRIKE_INTERVAL
	owner_actor.set_state(ProtoOwner.State.COMBAT)
	owner_actor.say("欸欸欸，不是我…")
	_popup("你家狗在叫什麼？！")
	fight_started.emit()
	return true


func _physics_process(delta: float) -> void:
	_pop_left -= delta
	if _pop_left <= 0.0:
		_pop.text = ""
	match state:
		State.COMBAT:
			_fight(delta)
		State.RETURNING:
			var to_home := home - _human.global_position
			to_home.y = 0.0
			if to_home.length() < 0.05:
				_human.global_position = Vector3(home.x, _human.global_position.y, home.z)
				state = State.IDLE
			else:
				_human.global_position += to_home.normalized() * minf(2.0 * delta, to_home.length())
	_small_dog.global_position = _human.global_position + Vector3(0.7, 0, 0.3)
	_hp_label.global_position = _human.global_position + Vector3(0, 2.45, 0)
	_pop.global_position = _human.global_position + Vector3(0, 2.8, 0)


func _fight(delta: float) -> void:
	if dog.global_position.distance_to(owner_actor.global_position) > DISENGAGE_DISTANCE:
		_end(&"disengaged")
		return
	# Humans close in on each other where they stand.
	var a := owner_actor.global_position
	var b := _human.global_position
	var gap := Vector3(b.x - a.x, 0, b.z - a.z)
	if gap.length() > STRIKE_RANGE:
		var step := gap.normalized() * 2.4 * delta * 0.5
		owner_actor.global_position += step
		_human.global_position -= step
	owner_actor.face_towards(_human.global_position)
	_human.rotation.y = atan2(gap.x, gap.z)
	_strike_left -= delta
	if _strike_left > 0.0 or gap.length() > STRIKE_RANGE + 0.2:
		_hp_label.text = _bars(opponent_hp)
		return
	_strike_left = STRIKE_INTERVAL
	var moves := ["出拳", "踢腿", "格擋", "閃避"]
	var move: String = moves[_turn % moves.size()]
	if _turn % 2 == 0:
		opponent_hp -= 14.0 if move != "格擋" else 4.0
		owner_actor.say(move + "！", 0.6)
	else:
		owner_hp -= 11.0 if move != "閃避" else 0.0
		_popup(move + "！")
	_turn += 1
	_hp_label.text = _bars(opponent_hp)
	if opponent_hp <= 0.0:
		_end(&"victory")
	elif owner_hp <= 0.0:
		_end(&"defeat")


func _end(result: StringName) -> void:
	_hp_label.text = ""
	match result:
		&"victory":
			state = State.BEATEN
			_human.rotation.z = PI / 2.0
			owner_actor.set_state(ProtoOwner.State.FOLLOW)
			owner_actor.say("贏了！")
		&"defeat":
			state = State.RETURNING
			owner_actor.set_state(ProtoOwner.State.DOWN)
		_:
			state = State.RETURNING
			owner_actor.set_state(ProtoOwner.State.FOLLOW)
			owner_actor.say("等等我啊！")
	fight_ended.emit(result)


## Debug / QA reset.
func reset() -> void:
	state = State.IDLE
	_human.rotation.z = 0.0
	_human.global_position = home
	_hp_label.text = ""


func _popup(text: String) -> void:
	_pop.text = text
	_pop_left = 1.0


static func _bars(hp: float) -> String:
	var filled := int(ceil(clampf(hp, 0.0, 100.0) / 20.0))
	return "■".repeat(filled) + "□".repeat(5 - filled)
