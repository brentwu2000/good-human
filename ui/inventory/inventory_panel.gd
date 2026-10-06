class_name InventoryPanel
extends Control
## Human run bag + dog safe slots. Tap a slot to select it, tap another slot to
## move / merge / swap (no drag & drop required on mobile).

signal closed

var _human: Inventory
var _dog: Inventory
var _selected_inventory: Inventory
var _selected_index: int = -1
## S05-02: set by a walk, so items can be used on the owner. Null at Home.
var run_manager: RunManager

@onready var _human_grid: InventoryGrid = %HumanGrid
@onready var _dog_grid: InventoryGrid = %DogGrid
@onready var _detail_label: Label = %DetailLabel
@onready var _close_button: Button = %CloseButton
@onready var _discard_button: Button = %DiscardButton
@onready var _use_button: Button = %UseButton
## P05-10: hold a weapon from the owner's bag, or put it away.
var _hold_button: Button


func _ready() -> void:
	_human_grid.slot_pressed.connect(_on_slot_pressed)
	_dog_grid.slot_pressed.connect(_on_slot_pressed)
	_close_button.pressed.connect(close)
	_discard_button.pressed.connect(discard_selected)
	_use_button.pressed.connect(use_selected_on_owner)
	_hold_button = Button.new()
	_hold_button.name = "HoldButton"
	_hold_button.focus_mode = Control.FOCUS_NONE
	_hold_button.visible = false
	_hold_button.pressed.connect(toggle_hold_selected)
	_use_button.get_parent().add_child(_hold_button)


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
		_detail_label.text = "%s（$%d）：%s\n%s\n再點一格移動，或按「丟掉」" % [WeaponCondition.name_of(stack), stack.item.value, stack.item.description, safe_line(stack.item)]
		_discard_button.disabled = false
		_use_button.visible = run_manager != null and stack.item.owner_recovery > 0.0
		_use_button.disabled = run_manager == null or not run_manager.can_use_on_owner(inventory, index)
		var weapon := DataRegistry.weapon_for_item(stack.item_id)
		_hold_button.visible = run_manager != null and weapon != null and inventory == _human
		_hold_button.text = "放下不拿" if run_manager != null and run_manager.equipped_stack == stack else "讓主人拿著"
		if weapon != null:
			_detail_label.text += "\n" + WeaponCompare.describe(weapon, stack.condition, run_manager.equipped_weapon if run_manager != null else null, Game.owner_fighter().skills)
		_update_highlight()
		return

	if inventory != _selected_inventory or index != _selected_index:
		var moving := _selected_inventory.stack_at(_selected_index)
		if not _selected_inventory.move_item(_selected_index, inventory, index) and moving != null and not inventory.accepts_item(moving.item):
			_clear_selection()
			# P05-01: said, not silently refused.
			_detail_label.text = "%s太大了，狗狗的背包裝不下。只能讓主人拿著。" % moving.item.display_name
			return
	_clear_selection()


## P05-12: whether it can be kept safe in the dog's backpack, said plainly.
static func safe_line(item: ItemData) -> String:
	if item.is_safe_eligible():
		return "🐾 小東西：放進狗狗背包，就算主人被打倒也帶得回家。"
	return "🧍 太大了，狗狗背包裝不下：只能讓主人拿著，打輸了就會丟。"


## Throws away the selected stack (frees a slot for better loot).
func discard_selected() -> void:
	if _selected_inventory == null:
		return
	_selected_inventory.take_stack(_selected_index)
	_clear_selection()


## S05-02: a bandage or a drink for the owner. Uses one of the stack.
func use_selected_on_owner() -> void:
	if _selected_inventory == null or run_manager == null:
		return
	run_manager.use_on_owner(_selected_inventory, _selected_index)
	_clear_selection()


## P05-10: the owner holds the selected weapon, or puts it away.
func toggle_hold_selected() -> void:
	if _selected_inventory == null or run_manager == null:
		return
	var stack := _selected_inventory.stack_at(_selected_index)
	if run_manager.equipped_stack == stack:
		run_manager.unequip()
	else:
		run_manager.equip(stack)
	_clear_selection()


func _clear_selection() -> void:
	_selected_inventory = null
	_selected_index = -1
	if is_node_ready():
		_detail_label.text = "點一格選取物品，再點目標格移動。狗包的東西失敗也不會遺失。"
		_discard_button.disabled = true
		_use_button.visible = false
		if _hold_button != null:
			_hold_button.visible = false
		_update_highlight()


func _update_highlight() -> void:
	if _human == null:
		return
	_human_grid.set_selected(_selected_index if _selected_inventory == _human else -1)
	_dog_grid.set_selected(_selected_index if _selected_inventory == _dog else -1)
