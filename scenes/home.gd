extends Control
## Home placeholder: owner, stash/dog bag counts, start a walk.

@onready var _stash_label: Label = %StashLabel
@onready var _dog_bag_label: Label = %DogBagLabel
@onready var _walk_button: Button = %WalkButton
@onready var _view_stash_button: Button = %ViewStashButton
@onready var _stash_panel: StashPanel = %StashPanel
@onready var _controls_label: Label = %ControlsLabel
@onready var _growth_label: Label = %GrowthLabel


func _ready() -> void:
	_walk_button.pressed.connect(_on_walk_pressed)
	_view_stash_button.pressed.connect(func() -> void: _stash_panel.open(Game.home_stash))
	_refresh()


func _refresh() -> void:
	var stash := Game.home_stash
	_stash_label.text = "倉庫 %d/%d　總價值 $%d" % [stash.used_slot_count(), stash.capacity, stash.total_value()]
	# Dog Safe Inventory is run-scoped in Sprint 01, so it is empty at Home.
	_dog_bag_label.text = "狗包 0/%d" % DataRegistry.balance.dog_safe_slots
	_walk_button.disabled = not Game.can_start_run()
	_controls_label.text = preload("res://ui/hud/run_hud.gd").controls_hint()
	_growth_label.text = growth_text()


## The owner's unlocked changes, in words.
static func growth_text() -> String:
	var perks := GrowthResolver.owned_perks(Game.human_growth, DataRegistry.training)
	if perks.is_empty():
		return "主人還是那個普通的主人。"
	var names: Array[String] = []
	for perk in perks:
		names.append("「%s」" % perk.display_name)
	return "主人的變化：" + "、".join(names)


func _on_walk_pressed() -> void:
	Game.start_run()
