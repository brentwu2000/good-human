extends Node
## Read-only lookup for data-driven content. Holds no runtime state.

const ITEMS_DIR: String = "res://data/items"
const BALANCE_PATH: String = "res://data/game_balance/game_balance.tres"

var balance: GameBalance

var _items: Dictionary[StringName, ItemData] = {}


func _ready() -> void:
	balance = load(BALANCE_PATH) as GameBalance
	_load_items()


func get_item(item_id: StringName) -> ItemData:
	return _items.get(item_id)


func has_item(item_id: StringName) -> bool:
	return _items.has(item_id)


func get_all_item_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_items.keys())
	return ids


func _load_items() -> void:
	# ResourceLoader.list_directory handles exported (remapped) resources.
	for file_name in ResourceLoader.list_directory(ITEMS_DIR):
		if not file_name.ends_with(".tres"):
			continue
		var item := load(ITEMS_DIR.path_join(file_name)) as ItemData
		if item == null:
			push_error("DataRegistry: %s is not an ItemData" % file_name)
			continue
		if _items.has(item.id):
			push_error("DataRegistry: duplicate item id %s in %s" % [item.id, file_name])
			continue
		_items[item.id] = item
