extends Node2D
## Greybox run map root: clamps the dog camera to the map bounds.

@export var map_bounds: Rect2 = Rect2(-2000, -14600, 4000, 15400)
@export var dog: DogController


func _ready() -> void:
	var camera := dog.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	camera.limit_left = int(map_bounds.position.x)
	camera.limit_top = int(map_bounds.position.y)
	camera.limit_right = int(map_bounds.end.x)
	camera.limit_bottom = int(map_bounds.end.y)
	camera.reset_smoothing()
