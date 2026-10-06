class_name ItemStack
extends RefCounted
## A quantity of one item. Serializes as {item_id, quantity[, condition]}.

var item: ItemData
var quantity: int
## P05-09: how much use is left in this one (a weapon). -1 = as new / does
## not wear. Only non-stackable items carry it, so a stack is one thing.
var condition: int = -1


func _init(p_item: ItemData, p_quantity: int = 1) -> void:
	item = p_item
	quantity = p_quantity


var item_id: StringName:
	get:
		return item.id if item != null else &""


func duplicate_stack() -> ItemStack:
	var copy := ItemStack.new(item, quantity)
	copy.condition = condition
	return copy


func serialize() -> Dictionary:
	var data := {"item_id": String(item_id), "quantity": quantity}
	if condition >= 0:
		data["condition"] = condition
	return data
