class_name StashPanel
extends Control
## Read-only view of the Home Stash.

@onready var _title_label: Label = %TitleLabel
@onready var _grid: InventoryGrid = %StashGrid
@onready var _detail_label: Label = %DetailLabel
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	_close_button.pressed.connect(hide)
	_grid.slot_pressed.connect(_on_slot_pressed)


func open(stash: Inventory) -> void:
	if _grid.inventory != stash:
		_grid.bind(stash)
	_grid.set_selected(-1)
	_title_label.text = "倉庫 %d/%d" % [stash.used_slot_count(), stash.capacity]
	_detail_label.text = "點物品看說明"
	show()


func _on_slot_pressed(inventory: Inventory, index: int) -> void:
	var stack := inventory.stack_at(index)
	_grid.set_selected(index if stack != null else -1)
	_detail_label.text = "點物品看說明" if stack == null else "%s x%d：%s" % [stack.item.display_name, stack.quantity, stack.item.description]
