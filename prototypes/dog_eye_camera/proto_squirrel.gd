class_name ProtoSquirrel
extends Node3D
## P-01 greybox squirrel: flees when the dog gets close, trees after a
## sustained chase, escapes if the dog falls behind.

enum State { IDLE, FLEEING, TREED, GONE }

const SPOT_DISTANCE: float = 5.0
const CHASE_DISTANCE: float = 3.0
const CHASE_SECONDS: float = 2.5
const LOSE_DISTANCE: float = 9.0
const LOSE_SECONDS: float = 2.0
const SPEED: float = 5.0

var state: State = State.IDLE
var dog: ProtoDog
var bounds: AABB = AABB(Vector3(-14, 0, -60), Vector3(28, 1, 28))
var home: Vector3

var _chase: float = 0.0
var _lost: float = 0.0
var _label: Label3D


func _ready() -> void:
	home = global_position
	add_child(ProtoShapes.box(Vector3(0.18, 0.2, 0.32), Color(0.55, 0.35, 0.2), Vector3(0, 0.12, 0)))
	add_child(ProtoShapes.box(Vector3(0.12, 0.3, 0.12), Color(0.6, 0.4, 0.25), Vector3(0, 0.3, 0.18)))
	_label = ProtoShapes.label("", 0.8, 40, Color(1, 0.9, 0.5))
	add_child(_label)


func _physics_process(delta: float) -> void:
	if dog == null or state == State.GONE or state == State.TREED:
		return
	var distance := dog.global_position.distance_to(global_position)
	if state == State.IDLE:
		if distance <= SPOT_DISTANCE:
			state = State.FLEEING
			_label.text = "吱！"
		return
	var away := global_position - dog.global_position
	away.y = 0.0
	var next := global_position + away.normalized() * SPEED * delta
	next.x = clampf(next.x, bounds.position.x, bounds.end.x)
	next.z = clampf(next.z, bounds.position.z, bounds.end.z)
	global_position = next
	if distance <= CHASE_DISTANCE:
		_chase += delta
		_lost = 0.0
		if _chase >= CHASE_SECONDS:
			state = State.TREED
			global_position.y = 2.2
			_label.text = "（上樹了）"
	elif distance > LOSE_DISTANCE:
		_lost += delta
		if _lost >= LOSE_SECONDS:
			state = State.GONE
			visible = false


func reset() -> void:
	state = State.IDLE
	_chase = 0.0
	_lost = 0.0
	global_position = home
	visible = true
	_label.text = ""
