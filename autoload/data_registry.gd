extends Node
## Read-only lookup for data-driven content. Holds no runtime state.

const ITEMS_DIR: String = "res://data/items"
const BALANCE_PATH: String = "res://data/game_balance/game_balance.tres"
const TRAINING_BALANCE_PATH: String = "res://data/training/training_balance.tres"
const TRAINING_EVENTS_DIR: String = "res://data/training/events"

var balance: GameBalance
var training: TrainingBalance

var _items: Dictionary[StringName, ItemData] = {}
var _training_events: Dictionary[StringName, TrainingEventData] = {}


func _ready() -> void:
	balance = load(BALANCE_PATH) as GameBalance
	training = load(TRAINING_BALANCE_PATH) as TrainingBalance
	_load_items()
	_load_training_events()


func get_training_event(event_id: StringName) -> TrainingEventData:
	if not _training_events.has(event_id):
		push_error("DataRegistry: unknown training event %s" % event_id)
	return _training_events.get(event_id)


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
	if _items.is_empty():
		push_error("DataRegistry: no items found in %s" % ITEMS_DIR)


func _load_training_events() -> void:
	for file_name in ResourceLoader.list_directory(TRAINING_EVENTS_DIR):
		if not file_name.ends_with(".tres"):
			continue
		var data := load(TRAINING_EVENTS_DIR.path_join(file_name)) as TrainingEventData
		if data == null or _training_events.has(data.id):
			push_error("DataRegistry: bad or duplicate training event %s" % file_name)
			continue
		_training_events[data.id] = data
