extends Control
## Home placeholder: owner, stash/dog bag counts, start a walk.

@onready var _stash_label: Label = %StashLabel
@onready var _dog_bag_label: Label = %DogBagLabel
@onready var _walk_button: Button = %WalkButton
@onready var _view_stash_button: Button = %ViewStashButton
@onready var _stash_panel: StashPanel = %StashPanel


func _ready() -> void:
	_walk_button.pressed.connect(_on_walk_pressed)
	_view_stash_button.pressed.connect(func() -> void: _stash_panel.open(Game.home_stash))
	_refresh()


func _refresh() -> void:
	var stash := Game.home_stash
	_stash_label.text = "倉庫 %d/%d" % [stash.used_slot_count(), stash.capacity]
	# Dog Safe Inventory is run-scoped in Sprint 01, so it is empty at Home.
	_dog_bag_label.text = "狗包 0/%d" % DataRegistry.balance.dog_safe_slots
	_walk_button.disabled = not Game.can_start_run()


func _on_walk_pressed() -> void:
	Game.start_run()
