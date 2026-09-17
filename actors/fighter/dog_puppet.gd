class_name DogPuppet
extends Node2D
## Placeholder opponent dog. The pair's dog is its social identity.

var _time: float = 0.0
var _excited: bool = false

@onready var _visual: Node2D = %Visual
@onready var _body: Polygon2D = %Body


func apply(color: Color, size: float, facing: float) -> void:
	_body.color = color
	_visual.scale = Vector2(size * signf(facing), size)


## Bounces while its human is fighting.
func set_excited(value: bool) -> void:
	_excited = value
	_visual.position.y = 0.0


func _process(delta: float) -> void:
	if not _excited:
		return
	_time += delta
	_visual.position.y = -absf(sin(_time * 9.0)) * 10.0
