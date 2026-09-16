class_name ItemStack
extends RefCounted
## A quantity of one item. Serializes as {item_id, quantity}.

var item: ItemData
var quantity: int


func _init(p_item: ItemData, p_quantity: int = 1) -> void:
	item = p_item
	quantity = p_quantity


var item_id: StringName:
	get:
		return item.id if item != null else &""


func duplicate_stack() -> ItemStack:
	return ItemStack.new(item, quantity)


func serialize() -> Dictionary:
	return {"item_id": String(item_id), "quantity": quantity}
