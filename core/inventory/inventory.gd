class_name Inventory
extends RefCounted
## Fixed-size slot container. One implementation for HumanRunInventory,
## DogSafeInventory and HomeStash.

signal changed

var capacity: int
## Each slot is an ItemStack or null.
var slots: Array[ItemStack] = []


func _init(p_capacity: int) -> void:
	capacity = maxi(p_capacity, 0)
	slots.resize(capacity)


func stack_at(index: int) -> ItemStack:
	return slots[index] if _valid(index) else null


func is_empty_slot(index: int) -> bool:
	return _valid(index) and slots[index] == null


func used_slot_count() -> int:
	return capacity - slots.count(null)


func is_empty() -> bool:
	return used_slot_count() == 0


func count_item(item_id: StringName) -> int:
	var total := 0
	for stack in slots:
		if stack != null and stack.item_id == item_id:
			total += stack.quantity
	return total


func total_value() -> int:
	var total := 0
	for stack in slots:
		if stack != null:
			total += stack.item.value * stack.quantity
	return total


## How many of `item` could be added right now.
func space_for(item: ItemData) -> int:
	var limit := item.get_stack_limit()
	var space := 0
	for stack in slots:
		if stack == null:
			space += limit
		elif stack.item_id == item.id:
			space += maxi(limit - stack.quantity, 0)
	return space


func has_space(item: ItemData, quantity: int = 1) -> bool:
	return space_for(item) >= quantity


## Adds as much as fits (existing stacks first). Returns the amount NOT added.
func add_item(item: ItemData, quantity: int = 1) -> int:
	if item == null or quantity <= 0:
		return maxi(quantity, 0)
	var remaining := quantity
	var limit := item.get_stack_limit()
	for stack in slots:
		if remaining == 0:
			break
		if stack != null and stack.item_id == item.id and stack.quantity < limit:
			var moved := mini(limit - stack.quantity, remaining)
			stack.quantity += moved
			remaining -= moved
	for i in capacity:
		if remaining == 0:
			break
		if slots[i] == null:
			var moved := mini(limit, remaining)
			slots[i] = ItemStack.new(item, moved)
			remaining -= moved
	if remaining != quantity:
		changed.emit()
	return remaining


## Removes `quantity` of an item across slots. All-or-nothing.
func remove_item(item_id: StringName, quantity: int = 1) -> bool:
	if quantity <= 0 or count_item(item_id) < quantity:
		return false
	var remaining := quantity
	for i in range(capacity - 1, -1, -1):
		var stack := slots[i]
		if stack == null or stack.item_id != item_id:
			continue
		var taken := mini(stack.quantity, remaining)
		stack.quantity -= taken
		remaining -= taken
		if stack.quantity == 0:
			slots[i] = null
		if remaining == 0:
			break
	changed.emit()
	return true


## Takes the whole stack out of a slot.
func take_stack(index: int) -> ItemStack:
	if not _valid(index) or slots[index] == null:
		return null
	var stack := slots[index]
	slots[index] = null
	changed.emit()
	return stack


## Moves a slot's stack into `target` at `to_index`:
## empty target → move; same item → merge (remainder stays); different item → swap.
## `to_index = -1` adds to the first space in target. Returns true if anything changed.
func move_item(from_index: int, target: Inventory, to_index: int = -1) -> bool:
	var stack := stack_at(from_index)
	if stack == null or target == null:
		return false
	if target == self and (from_index == to_index or to_index == -1):
		return false

	if to_index == -1:
		var left := target.add_item(stack.item, stack.quantity)
		if left == stack.quantity:
			return false
		_set_quantity(from_index, left)
		return true

	if not target._valid(to_index):
		return false
	var other := target.slots[to_index]
	if other == null:
		slots[from_index] = null
		target.slots[to_index] = stack
		_emit_changed(target)
		return true
	if other.item_id == stack.item_id and other.quantity < other.item.get_stack_limit():
		var moved := mini(other.item.get_stack_limit() - other.quantity, stack.quantity)
		other.quantity += moved
		_set_quantity(from_index, stack.quantity - moved, false)
		_emit_changed(target)
		return true
	return swap_item(from_index, target, to_index)


func swap_item(index_a: int, target: Inventory, index_b: int) -> bool:
	if target == null or not _valid(index_a) or not target._valid(index_b):
		return false
	if target == self and index_a == index_b:
		return false
	var a := slots[index_a]
	slots[index_a] = target.slots[index_b]
	target.slots[index_b] = a
	_emit_changed(target)
	return true


func clear() -> void:
	slots.fill(null)
	changed.emit()


## Non-empty stacks as copies, in slot order.
func get_stacks() -> Array[ItemStack]:
	var result: Array[ItemStack] = []
	for stack in slots:
		if stack != null:
			result.append(stack.duplicate_stack())
	return result


func serialize() -> Array:
	var result: Array = []
	for i in capacity:
		if slots[i] != null:
			var entry := slots[i].serialize()
			entry["slot"] = i
			result.append(entry)
	return result


## Restores from serialize() output. Unknown items and bad entries are skipped;
## `lookup` maps an item id to ItemData (usually DataRegistry.get_item).
func deserialize(data: Array, lookup: Callable) -> void:
	slots.fill(null)
	var overflow: Array[ItemStack] = []
	for raw: Variant in data:
		if not raw is Dictionary:
			continue
		var entry: Dictionary = raw
		var item := lookup.call(StringName(str(entry.get("item_id", "")))) as ItemData
		var quantity := _to_int(entry.get("quantity"), 0)
		if item == null or quantity <= 0:
			continue
		var slot := _to_int(entry.get("slot"), -1)
		if _valid(slot) and slots[slot] == null:
			var in_slot := mini(quantity, item.get_stack_limit())
			slots[slot] = ItemStack.new(item, in_slot)
			quantity -= in_slot
		if quantity > 0:
			overflow.append(ItemStack.new(item, quantity))
	for stack in overflow:
		add_item(stack.item, stack.quantity)
	changed.emit()


func _set_quantity(index: int, quantity: int, emit: bool = true) -> void:
	if quantity <= 0:
		slots[index] = null
	else:
		slots[index].quantity = quantity
	if emit:
		changed.emit()


func _emit_changed(target: Inventory) -> void:
	changed.emit()
	if target != self:
		target.changed.emit()


static func _to_int(value: Variant, fallback: int) -> int:
	return int(value) if value is int or value is float else fallback


func _valid(index: int) -> bool:
	return index >= 0 and index < capacity
