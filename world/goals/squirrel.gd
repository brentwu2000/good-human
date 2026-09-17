class_name Squirrel
extends Node2D
## A park squirrel. Spotting it can make the dog want to chase; chasing it
## long enough trees it, losing it lets it escape. Emits semantic events only.

signal spotted(squirrel: Squirrel)
signal treed(squirrel: Squirrel)
signal escaped(squirrel: Squirrel)

enum State { HIDDEN, IDLE, FLEEING, TREED, GONE }

const GROUP: StringName = &"squirrels"

@export var squirrel_id: StringName = &"squirrel"
## Places the squirrel may appear (one is picked per walk).
@export var spawn_points: Array[Vector2] = []
@export var spot_distance: float = 260.0
@export var chase_distance: float = 240.0
## Staying on its tail this long trees it.
@export var chase_seconds: float = 2.5
## Falling this far behind for this long lets it escape.
@export var lose_distance: float = 420.0
@export var lose_seconds: float = 2.0
@export var flee_speed: float = 230.0
## Keeps fleeing inside this box (map area).
@export var bounds: Rect2 = Rect2(-780, -5820, 1560, 1880)

var state: State = State.HIDDEN
var dog: Node2D

var _chase_time: float = 0.0
var _lost_time: float = 0.0
var _time: float = 0.0

@onready var _visual: Label = %Visual


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	hide()


## Called by GoalDirector at walk start with the run RNG.
func prepare(run_dog: Node2D, rng: RandomNumberGenerator) -> void:
	dog = run_dog
	_chase_time = 0.0
	_lost_time = 0.0
	if spawn_points.is_empty():
		state = State.HIDDEN
		hide()
		return
	global_position = spawn_points[rng.randi_range(0, spawn_points.size() - 1)]
	state = State.IDLE
	_visual.text = "🐿"
	show()


func _process(delta: float) -> void:
	if dog == null or state == State.HIDDEN or state == State.GONE:
		return
	_time += delta
	var distance := dog.global_position.distance_to(global_position)
	match state:
		State.IDLE:
			_visual.position.y = -30.0 + absf(sin(_time * 5.0)) * -6.0
			if distance <= spot_distance:
				state = State.FLEEING
				spotted.emit(self)
		State.FLEEING:
			_flee(delta)
			if distance <= chase_distance:
				_chase_time += delta
				_lost_time = 0.0
				if _chase_time >= chase_seconds:
					state = State.TREED
					_visual.text = "🌳🐿"
					treed.emit(self)
			elif distance > lose_distance:
				_lost_time += delta
				if _lost_time >= lose_seconds:
					state = State.GONE
					hide()
					escaped.emit(self)
		State.TREED:
			_visual.position.y = -60.0 + sin(_time * 8.0) * 3.0


func _flee(delta: float) -> void:
	var away := global_position - dog.global_position
	if away.length() < 1.0:
		away = Vector2.UP
	var next := global_position + away.normalized() * flee_speed * delta
	# Slide along the edges instead of leaving the park.
	next.x = clampf(next.x, bounds.position.x, bounds.end.x)
	next.y = clampf(next.y, bounds.position.y, bounds.end.y)
	if next.distance_to(global_position) < flee_speed * delta * 0.3:
		next = global_position + away.orthogonal().normalized() * flee_speed * delta
		next.x = clampf(next.x, bounds.position.x, bounds.end.x)
		next.y = clampf(next.y, bounds.position.y, bounds.end.y)
	global_position = next
	_visual.position.y = -30.0 + absf(sin(_time * 14.0)) * -10.0
