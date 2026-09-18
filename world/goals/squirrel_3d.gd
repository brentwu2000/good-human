class_name Squirrel3D
extends Node3D
## 3D park squirrel (same role as Squirrel): spotting it can make the dog want
## to chase; staying on its tail trees it; falling behind lets it escape.

signal spotted(squirrel: Squirrel3D)
signal treed(squirrel: Squirrel3D)
signal escaped(squirrel: Squirrel3D)

enum State { HIDDEN, IDLE, FLEEING, TREED, GONE }

@export var squirrel_id: StringName = &"squirrel"
@export var spawn_points: Array[Vector3] = []
@export var spot_distance: float = 3.25
@export var chase_distance: float = 3.0
@export var chase_seconds: float = 2.5
@export var lose_distance: float = 5.25
@export var lose_seconds: float = 2.0
@export var flee_speed: float = 2.9
## Stays inside this area while fleeing.
@export var bounds: AABB = AABB(Vector3(-28, 0, -66), Vector3(56, 2, 44))

var state: State = State.HIDDEN
var dog: Node3D

var _chase_time: float = 0.0
var _lost_time: float = 0.0
var _time: float = 0.0
var _body: Node3D
var _label: Label3D


func _enter_tree() -> void:
	add_to_group(Squirrel.GROUP)


func _ready() -> void:
	_body = GoalVisual3D.squirrel()
	add_child(_body)
	_label = Greybox.label("", 0.9, 36, Color(1, 0.9, 0.5))
	add_child(_label)
	hide()


## Called by GoalDirector at walk start with the run RNG.
func prepare(run_dog: Node, rng: RandomNumberGenerator) -> void:
	dog = run_dog as Node3D
	_chase_time = 0.0
	_lost_time = 0.0
	_label.text = ""
	if spawn_points.is_empty():
		state = State.HIDDEN
		hide()
		return
	global_position = spawn_points[rng.randi_range(0, spawn_points.size() - 1)]
	state = State.IDLE
	show()


func _process(delta: float) -> void:
	if dog == null or state == State.HIDDEN or state == State.GONE:
		return
	_time += delta
	var distance := dog.global_position.distance_to(global_position)
	match state:
		State.IDLE:
			_body.position.y = absf(sin(_time * 5.0)) * 0.05
			if distance <= spot_distance:
				state = State.FLEEING
				_label.text = "吱！"
				spotted.emit(self)
		State.FLEEING:
			_flee(delta)
			if distance <= chase_distance:
				_chase_time += delta
				_lost_time = 0.0
				if _chase_time >= chase_seconds:
					state = State.TREED
					global_position.y = 2.2
					_label.text = "（上樹了）"
					treed.emit(self)
			elif distance > lose_distance:
				_lost_time += delta
				if _lost_time >= lose_seconds:
					state = State.GONE
					hide()
					escaped.emit(self)


func _flee(delta: float) -> void:
	var away := global_position - dog.global_position
	away.y = 0.0
	if away.length() < 0.01:
		away = Vector3.FORWARD
	var next := global_position + away.normalized() * flee_speed * delta
	var clamped := Vector3(clampf(next.x, bounds.position.x, bounds.end.x), next.y, clampf(next.z, bounds.position.z, bounds.end.z))
	if clamped.distance_to(global_position) < flee_speed * delta * 0.3:
		# Cornered: run along the edge.
		var side := away.cross(Vector3.UP).normalized() * flee_speed * delta
		clamped = Vector3(clampf(global_position.x + side.x, bounds.position.x, bounds.end.x), next.y, clampf(global_position.z + side.z, bounds.position.z, bounds.end.z))
	global_position = clamped
	_body.rotation.y = atan2(-away.x, -away.z)
	_body.position.y = absf(sin(_time * 14.0)) * 0.1
