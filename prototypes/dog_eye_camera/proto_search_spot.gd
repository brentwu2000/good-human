class_name ProtoSearchSpot
extends Node3D
## P-01 greybox trash can the dog can sniff (tests sniff framing).

const RANGE: float = 1.4
const DURATION: float = 1.2

var dog: ProtoDog
var searching: bool = false
var found: bool = false

var _progress: float = 0.0
var _label: Label3D


func _ready() -> void:
	add_child(ProtoShapes.cylinder(0.3, 0.8, Color(0.4, 0.5, 0.42), Vector3(0, 0.4, 0)))
	add_child(ProtoShapes.cylinder(0.33, 0.06, Color(0.3, 0.38, 0.32), Vector3(0, 0.83, 0)))
	_label = ProtoShapes.label("垃圾桶", 1.2, 32)
	add_child(_label)


func can_search() -> bool:
	return not searching and not found and dog != null and dog.global_position.distance_to(global_position) <= RANGE


func start() -> bool:
	if not can_search():
		return false
	searching = true
	_progress = 0.0
	dog.sniffing = true
	return true


func _physics_process(delta: float) -> void:
	if not searching:
		return
	_progress += delta
	_label.text = "👃" + ".".repeat(int(_progress * 4.0) % 4)
	if _progress >= DURATION:
		searching = false
		found = true
		dog.sniffing = false
		_label.text = "找到舊網球！"


func reset() -> void:
	searching = false
	found = false
	_label.text = "垃圾桶"
