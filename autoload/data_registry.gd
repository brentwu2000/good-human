extends Node
## Read-only lookup for data-driven content. Holds no runtime state.

const ITEMS_DIR: String = "res://data/items"
const BALANCE_PATH: String = "res://data/game_balance/game_balance.tres"
const TRAINING_BALANCE_PATH: String = "res://data/training/training_balance.tres"
const TRAINING_EVENTS_DIR: String = "res://data/training/events"
const GOAL_CATALOG_PATH: String = "res://data/goals/goal_catalog.tres"
const TEMPTATIONS_DIR: String = "res://data/greed/temptations"
const TERRITORIES_DIR: String = "res://data/territory"
const PRESENCE_PATH: String = "res://data/presence/presence.tres"
const SPACING_PATH: String = "res://data/combat/spacing.tres"
const DOG_BREEDS_DIR: String = "res://data/identity/breeds"
const DOG_TRAITS_DIR: String = "res://data/identity/dog_traits"
const HUMAN_BACKGROUNDS_DIR: String = "res://data/identity/human_backgrounds"
const HABITS_DIR: String = "res://data/identity/habits"
const MEMORY_KINDS_DIR: String = "res://data/identity/memories"
const WEAPONS_DIR: String = "res://data/combat/weapons"

var balance: GameBalance
var training: TrainingBalance
var goals: GoalCatalog
## Body sizes and bump response for physical presence (P-04, ADR-016).
var presence: PresenceData
## How fighters hold distance and move their feet (P-04).
var spacing: SpacingData
## Reasons to stay out after going home became possible (Sprint 05).
var temptations: Array[TemptationData] = []
## Sprint 06: what a shelter dog can look like and be like, in id order.
var dog_breeds: Array[DogBreedData] = []
var dog_traits: Array[DogTraitData] = []
var human_backgrounds: Array[HumanBackgroundData] = []
var habits: Array[HabitData] = []
var memory_kinds: Array[MemoryKindData] = []

var _territories: Dictionary[StringName, TerritoryData] = {}

var _items: Dictionary[StringName, ItemData] = {}
## P-05: what a human can fight with, by id (unarmed included).
var _weapons: Dictionary[StringName, WeaponData] = {}
var _training_events: Dictionary[StringName, TrainingEventData] = {}


func _ready() -> void:
	balance = load(BALANCE_PATH) as GameBalance
	training = load(TRAINING_BALANCE_PATH) as TrainingBalance
	goals = load(GOAL_CATALOG_PATH) as GoalCatalog
	presence = load(PRESENCE_PATH) as PresenceData
	spacing = load(SPACING_PATH) as SpacingData
	_load_items()
	_load_weapons()
	_load_training_events()
	_load_temptations()
	_load_territories()
	dog_breeds.assign(_load_dir(DOG_BREEDS_DIR))
	dog_traits.assign(_load_dir(DOG_TRAITS_DIR))
	human_backgrounds.assign(_load_dir(HUMAN_BACKGROUNDS_DIR))
	habits.assign(_load_dir(HABITS_DIR))
	memory_kinds.assign(_load_dir(MEMORY_KINDS_DIR))


func get_training_event(event_id: StringName) -> TrainingEventData:
	if not _training_events.has(event_id):
		push_error("DataRegistry: unknown training event %s" % event_id)
	return _training_events.get(event_id)


func get_weapon(weapon_id: StringName) -> WeaponData:
	return _weapons.get(weapon_id)


## The weapon a carried item is, or null if it is not one.
func weapon_for_item(item_id: StringName) -> WeaponData:
	for weapon: WeaponData in _weapons.values():
		if weapon.item != null and weapon.item.id == item_id:
			return weapon
	return null


func get_all_weapon_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_weapons.keys())
	return ids


func _load_weapons() -> void:
	for file_name in ResourceLoader.list_directory(WEAPONS_DIR):
		if not file_name.ends_with(".tres"):
			continue
		var weapon := load(WEAPONS_DIR.path_join(file_name)) as WeaponData
		if weapon == null or _weapons.has(weapon.id):
			push_error("DataRegistry: bad or duplicate weapon %s" % file_name)
			continue
		_weapons[weapon.id] = weapon


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


func _load_temptations() -> void:
	var seen: Dictionary[StringName, bool] = {}
	for file_name in ResourceLoader.list_directory(TEMPTATIONS_DIR):
		if not file_name.ends_with(".tres"):
			continue
		var data := load(TEMPTATIONS_DIR.path_join(file_name)) as TemptationData
		if data == null or seen.has(data.id):
			push_error("DataRegistry: bad or duplicate temptation %s" % file_name)
			continue
		seen[data.id] = true
		temptations.append(data)
	temptations.sort_custom(func(a: TemptationData, b: TemptationData) -> bool: return String(a.id) < String(b.id))


func get_dog_breed(breed_id: StringName) -> DogBreedData:
	for breed in dog_breeds:
		if breed.id == breed_id:
			return breed
	return null


func get_human_background(background_id: StringName) -> HumanBackgroundData:
	for bg in human_backgrounds:
		if bg.id == background_id:
			return bg
	return null


func get_memory_kind(kind_id: StringName) -> MemoryKindData:
	for kind in memory_kinds:
		if kind.id == kind_id:
			return kind
	return null


func get_habit(habit_id: StringName) -> HabitData:
	for habit in habits:
		if habit.id == habit_id:
			return habit
	return null


func get_dog_trait(trait_id: StringName) -> DogTraitData:
	for t in dog_traits:
		if t.id == trait_id:
			return t
	return null


## Every resource in `dir` that has a unique `id`, sorted by id so anything
## rolled from the list follows its seed.
func _load_dir(dir: String) -> Array[Resource]:
	var found: Array[Resource] = []
	var ids: Dictionary[StringName, bool] = {}
	for file_name in ResourceLoader.list_directory(dir):
		if not file_name.ends_with(".tres"):
			continue
		var res := load(dir.path_join(file_name))
		var id: StringName = res.get(&"id") if res != null else &""
		if id.is_empty() or ids.has(id):
			push_error("DataRegistry: bad or duplicate %s in %s" % [file_name, dir])
			continue
		ids[id] = true
		found.append(res)
	found.sort_custom(func(a: Resource, b: Resource) -> bool: return String(a.get(&"id")) < String(b.get(&"id")))
	return found


func get_territory(territory_id: StringName) -> TerritoryData:
	return _territories.get(territory_id)


func get_all_territories() -> Array[TerritoryData]:
	var result: Array[TerritoryData] = []
	result.assign(_territories.values())
	return result


func _load_territories() -> void:
	for file_name in ResourceLoader.list_directory(TERRITORIES_DIR):
		if not file_name.ends_with(".tres"):
			continue
		var data := load(TERRITORIES_DIR.path_join(file_name)) as TerritoryData
		if data == null or _territories.has(data.id):
			push_error("DataRegistry: bad or duplicate territory %s" % file_name)
			continue
		_territories[data.id] = data


func _load_training_events() -> void:
	for file_name in ResourceLoader.list_directory(TRAINING_EVENTS_DIR):
		if not file_name.ends_with(".tres"):
			continue
		var data := load(TRAINING_EVENTS_DIR.path_join(file_name)) as TrainingEventData
		if data == null or _training_events.has(data.id):
			push_error("DataRegistry: bad or duplicate training event %s" % file_name)
			continue
		_training_events[data.id] = data
