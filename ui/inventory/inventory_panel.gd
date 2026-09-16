class_name InventoryPanel
extends Control
## Human run bag + dog safe slots. Tap a slot to select it, tap another slot to
## move / merge / swap (no drag & drop required on mobile).

signal closed

var _human: Inventory
var _dog: Inventory
var _selected_inventory: Inventory
var _selected_index: int = -1

@onready var _human_grid: InventoryGrid = %HumanGrid
@onready var _dog_grid: InventoryGrid = %DogGrid
@onready var _detail_label: Label = %DetailLabel
@onready var _close_button: Button = %CloseButton
@onready var _discard_button: Button = %DiscardButton


func _ready() -> void:
	_human_grid.slot_pressed.connect(_on_slot_pressed)
	_dog_grid.slot_pressed.connect(_on_slot_pressed)
	_close_button.pressed.connect(close)
	_discard_button.pressed.connect(discard_selected)


func setup(human: Inventory, dog: Inventory) -> void:
	_human = human
	_dog = dog
	_human_grid.bind(human)
	_dog_grid.bind(dog)
	_clear_selection()


func open() -> void:
	_clear_selection()
	show()


func close() -> void:
	_clear_selection()
	hide()
	closed.emit()


func select_slot(inventory: Inventory, index: int) -> void:
	_on_slot_pressed(inventory, index)


func _on_slot_pressed(inventory: Inventory, index: int) -> void:
	if _selected_inventory == null:
		var stack := inventory.stack_at(index)
		if stack == null:
			return
		_selected_inventory = inventory
		_selected_index = index
		_detail_label.text = "%s（$%d）：%s\n再點一格移動，或按「丟掉」" % [stack.item.display_name, stack.item.value, stack.item.description]
		_discard_button.disabled = false
		_update_highlight()
		return

	if inventory != _selected_inventory or index != _selected_index:
		_selected_inventory.move_item(_selected_index, inventory, index)
	_clear_selection()


## Throws away the selected stack (frees a slot for better loot).
func discard_selected() -> void:
	if _selected_inventory == null:
		return
	_selected_inventory.take_stack(_selected_index)
	_clear_selection()


func _clear_selection() -> void:
	_selected_inventory = null
	_selected_index = -1
	if is_node_ready():
		_detail_label.text = "點一格選取物品，再點目標格移動。狗包的東西失敗也不會遺失。"
		_discard_button.disabled = true
		_update_highlight()


func _update_highlight() -> void:
	if _human == null:
		return
	_human_grid.set_selected(_selected_index if _selected_inventory == _human else -1)
	_dog_grid.set_selected(_selected_index if _selected_inventory == _dog else -1)
