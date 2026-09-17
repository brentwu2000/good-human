extends Node2D
## Greybox run map root: camera bounds and owner reactions to run events.

@export var map_bounds: Rect2 = Rect2(-800, -5840, 1600, 6160)
@export var dog: DogController
@export var human: HumanFollower
@export var run_manager: RunManager


func _ready() -> void:
	_setup_camera()
	if human != null and run_manager != null:
		run_manager.run_started.connect(func(_seed: int) -> void: human.say("好，出去散步吧！"))
		run_manager.loot_gained.connect(_on_loot_gained)
		run_manager.loot_blocked.connect(func(_i: ItemData, _q: int) -> void: human.say("背包裝不下了啦…", Color(1.0, 0.6, 0.5)))
		run_manager.search_empty.connect(func(_p: SearchPoint) -> void: human.say("什麼都沒有嘛", Color(0.8, 0.8, 0.8)))
		run_manager.extraction_unlocked.connect(func(p: ExtractionPoint) -> void: human.say("%s 可以回家了" % p.display_label, Color(0.6, 1.0, 0.6), 2.2))


func _on_loot_gained(item: ItemData, _quantity: int) -> void:
	match item.rarity:
		ItemData.Rarity.RARE:
			human.say("哇！%s？！好狗狗！" % item.display_name, item.get_rarity_color(), 2.2)
		ItemData.Rarity.UNCOMMON:
			human.say("喔？這個不錯", item.get_rarity_color())
		_:
			human.say("嗯…收好了", Color(0.9, 0.9, 0.9), 1.0)


func _setup_camera() -> void:
	var camera := dog.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	camera.limit_left = int(map_bounds.position.x)
	camera.limit_top = int(map_bounds.position.y)
	camera.limit_right = int(map_bounds.end.x)
	camera.limit_bottom = int(map_bounds.end.y)
	camera.reset_smoothing()
