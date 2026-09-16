class_name InventoryGrid
extends GridContainer
## Renders one Inventory as tappable slot buttons.

signal slot_pressed(inventory: Inventory, index: int)

@export var slot_size: Vector2 = Vector2(150, 110)

var inventory: Inventory

var _buttons: Array[Button] = []
var _selected_index: int = -1


func bind(p_inventory: Inventory) -> void:
	if inventory != null and inventory.changed.is_connected(refresh):
		inventory.changed.disconnect(refresh)
	inventory = p_inventory
	inventory.changed.connect(refresh)
	_build_buttons()
	refresh()


func set_selected(index: int) -> void:
	_selected_index = index
	refresh()


func refresh() -> void:
	if inventory == null:
		return
	for i in _buttons.size():
		var button := _buttons[i]
		var stack := inventory.stack_at(i)
		if stack == null:
			button.text = "—"
		elif stack.quantity > 1:
			button.text = "%s\nx%d" % [stack.item.display_name, stack.quantity]
		else:
			button.text = stack.item.display_name
		var text_color := Color(0.6, 0.6, 0.6) if stack == null else stack.item.get_rarity_color()
		button.add_theme_color_override("font_color", text_color)
		button.add_theme_color_override("font_hover_color", text_color)
		button.add_theme_color_override("font_pressed_color", text_color)
		button.modulate = Color(1.0, 0.85, 0.3) if i == _selected_index else Color.WHITE


func get_slot_button(index: int) -> Button:
	return _buttons[index]


func _build_buttons() -> void:
	for button in _buttons:
		button.queue_free()
	_buttons.clear()
	for i in inventory.capacity:
		var button := Button.new()
		button.custom_minimum_size = slot_size
		button.focus_mode = Control.FOCUS_NONE
		button.clip_text = true
		button.add_theme_font_size_override("font_size", 20)
		button.pressed.connect(func() -> void: slot_pressed.emit(inventory, i))
		add_child(button)
		_buttons.append(button)
