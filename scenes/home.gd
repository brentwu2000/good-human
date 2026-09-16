extends Control
## Home placeholder: owner, stash/dog bag counts, start a walk.

const STASH_CAPACITY: int = 30
const DOG_SAFE_CAPACITY: int = 2

@onready var _stash_label: Label = %StashLabel
@onready var _dog_bag_label: Label = %DogBagLabel
@onready var _walk_button: Button = %WalkButton


func _ready() -> void:
	_walk_button.pressed.connect(_on_walk_pressed)
	_refresh()


func _refresh() -> void:
	# TODO(P0-016): read counts from the HomeStash Inventory once it exists.
	var stash: Array = SaveManager.data["stash"]
	_stash_label.text = "Stash %d/%d" % [stash.size(), STASH_CAPACITY]
	# Dog Safe Inventory is run-scoped in Sprint 01, so it is empty at Home.
	_dog_bag_label.text = "狗包 0/%d" % DOG_SAFE_CAPACITY
	_walk_button.disabled = not Game.can_start_run()


func _on_walk_pressed() -> void:
	Game.start_run()
