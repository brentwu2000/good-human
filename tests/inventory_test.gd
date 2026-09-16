extends "res://tests/test_case.gd"
## P0-009 Inventory add/remove/move/swap/serialize; model side of P0-012 safe slots.

var ball: ItemData
var treat: ItemData
var gloves: ItemData


func _ready() -> void:
	ball = _item(&"ball", true, 3)
	treat = _item(&"treat", true, 5)
	gloves = _item(&"gloves", false, 99)

	_test_add_and_stack()
	_test_add_overflow()
	_test_remove()
	_test_move_to_empty_and_merge()
	_test_swap_between_inventories()
	_test_move_to_first_space()
	_test_serialize_round_trip()
	_test_deserialize_bad_data()
	_test_changed_signal()
	finish()


func _test_add_and_stack() -> void:
	var inv := Inventory.new(8)
	check_eq(inv.add_item(ball, 2), 0, "add 2 balls fits")
	check_eq(inv.add_item(ball, 2), 0, "add 2 more balls fits")
	check_eq(inv.used_slot_count(), 2, "balls stack to limit 3 then new slot")
	check_eq(inv.stack_at(0).quantity, 3, "first stack full")
	check_eq(inv.stack_at(1).quantity, 1, "second stack has remainder")
	inv.add_item(gloves, 2)
	check_eq(inv.used_slot_count(), 4, "non-stackable items use one slot each")
	check_eq(inv.count_item(&"ball"), 4, "count across stacks")


func _test_add_overflow() -> void:
	var inv := Inventory.new(2)
	check_eq(inv.add_item(gloves, 3), 1, "only 2 gloves fit in 2 slots")
	check(not inv.has_space(ball), "full inventory has no space")
	check_eq(inv.add_item(ball, 1), 1, "adding to full inventory returns all")
	check_eq(inv.add_item(null, 1), 1, "null item not added")


func _test_remove() -> void:
	var inv := Inventory.new(4)
	inv.add_item(ball, 5)
	check(not inv.remove_item(&"ball", 6), "cannot remove more than owned")
	check_eq(inv.count_item(&"ball"), 5, "failed remove changes nothing")
	check(inv.remove_item(&"ball", 4), "remove 4 across stacks")
	check_eq(inv.count_item(&"ball"), 1, "one ball left")
	check_eq(inv.used_slot_count(), 1, "emptied stack slot freed")
	var taken := inv.take_stack(0)
	check(taken != null and taken.quantity == 1, "take_stack returns stack")
	check(inv.is_empty(), "inventory empty after take")


func _test_move_to_empty_and_merge() -> void:
	var inv := Inventory.new(4)
	inv.add_item(ball, 2)
	check(inv.move_item(0, inv, 3), "move within inventory to empty slot")
	check(inv.is_empty_slot(0) and inv.stack_at(3).quantity == 2, "stack moved to slot 3")
	inv.add_item(ball, 2)  # tops slot 3 up to 3, remainder goes to slot 0
	check_eq(inv.stack_at(3).quantity, 3, "add merges into existing stack")
	check(inv.is_empty_slot(0) == false and inv.stack_at(0).quantity == 1, "remainder in first free slot")
	inv.clear()
	inv.slots[0] = ItemStack.new(ball, 2)
	inv.slots[1] = ItemStack.new(ball, 2)
	check(inv.move_item(0, inv, 1), "merge partial stacks")
	check_eq(inv.stack_at(1).quantity, 3, "target filled to limit")
	check_eq(inv.stack_at(0).quantity, 1, "remainder stays in source")
	check(not inv.move_item(0, inv, 0), "move onto itself is a no-op")
	check(not inv.move_item(2, inv, 1), "moving an empty slot fails")


func _test_swap_between_inventories() -> void:
	var human := Inventory.new(8)
	var dog := Inventory.new(2)
	human.add_item(gloves, 1)
	dog.add_item(treat, 1)
	check(human.move_item(0, dog, 0), "move onto different item swaps")
	check_eq(dog.stack_at(0).item_id, &"gloves", "gloves now in dog slot")
	check_eq(human.stack_at(0).item_id, &"treat", "treat now in human slot")
	check(human.swap_item(0, dog, 1), "swap with empty slot")
	check(human.is_empty_slot(0) and dog.stack_at(1).item_id == &"treat", "swap moved treat to dog slot 1")
	check(not human.swap_item(0, dog, 5), "swap to invalid index fails")


func _test_move_to_first_space() -> void:
	var human := Inventory.new(8)
	var dog := Inventory.new(2)
	human.add_item(gloves, 3)
	check(human.move_item(0, dog), "move to first space in dog bag")
	check(human.move_item(1, dog), "second item fits in dog bag")
	check(not human.move_item(2, dog), "third item does not fit in 2 safe slots")
	check_eq(human.used_slot_count(), 1, "unmoved item stays in human inventory")
	check_eq(dog.used_slot_count(), 2, "dog bag full")


func _test_serialize_round_trip() -> void:
	var inv := Inventory.new(8)
	inv.slots[2] = ItemStack.new(ball, 3)
	inv.slots[5] = ItemStack.new(gloves, 1)
	var json := JSON.stringify(inv.serialize())
	var restored := Inventory.new(8)
	restored.deserialize(JSON.parse_string(json), _lookup)
	check_eq(restored.used_slot_count(), 2, "round trip keeps stacks")
	check_eq(restored.stack_at(2).item_id, &"ball", "slot position kept")
	check_eq(restored.stack_at(2).quantity, 3, "quantity kept (and int)")
	check(restored.stack_at(2).quantity is int, "quantity restored as int")
	check_eq(restored.stack_at(5).item_id, &"gloves", "second slot kept")


func _test_deserialize_bad_data() -> void:
	var inv := Inventory.new(2)
	inv.deserialize([
		"junk",
		{"item_id": "unknown", "quantity": 1, "slot": 0},
		{"item_id": "ball", "quantity": -2, "slot": 0},
		{"item_id": "ball", "quantity": 5, "slot": 0},
		{"item_id": "gloves", "quantity": 1, "slot": 0},
		{"item_id": "gloves", "quantity": 1, "slot": 99},
	], _lookup)
	check_eq(inv.stack_at(0).item_id, &"ball", "valid entry placed in its slot")
	check_eq(inv.stack_at(0).quantity, 3, "over-limit quantity capped per slot")
	check_eq(inv.stack_at(1).item_id, &"ball", "over-limit remainder moved to free slot")
	check_eq(inv.used_slot_count(), 2, "items that no longer fit are dropped, not crashed")


func _test_changed_signal() -> void:
	var inv := Inventory.new(2)
	var hits: Array[int] = [0]
	inv.changed.connect(func() -> void: hits[0] += 1)
	inv.add_item(ball, 1)
	inv.add_item(gloves, 5)
	inv.clear()
	check_eq(hits[0], 3, "changed emitted on add, partial add, clear")
	inv.add_item(ball, 0)
	check_eq(hits[0], 3, "no signal when nothing changes")


func _lookup(id: StringName) -> ItemData:
	match id:
		&"ball":
			return ball
		&"treat":
			return treat
		&"gloves":
			return gloves
	return null


func _item(id: StringName, stackable: bool, max_stack: int) -> ItemData:
	var item := ItemData.new()
	item.id = id
	item.display_name = String(id)
	item.stackable = stackable
	item.max_stack = max_stack
	return item
