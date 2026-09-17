extends "res://tests/test_case.gd"
## P0-008 ItemData .tres + DataRegistry, P0-010 LootTable weighted roll.

const SPRINT_ITEMS: Array[StringName] = [
	&"tennis_ball", &"dog_treat", &"sports_drink", &"bandage", &"old_running_shoes", &"umbrella",
	&"jump_rope", &"hand_grip", &"dog_toy", &"old_sports_watch", &"boxing_gloves", &"mysterious_item",
	&"half_tennis_ball",
]
const TABLE_PATHS: Array[String] = [
	"res://data/loot_tables/residential_trash.tres",
	"res://data/loot_tables/park_search.tres",
]


func _ready() -> void:
	_test_registry()
	_test_balance()
	for path in TABLE_PATHS:
		_test_table_data(path)
	_test_roll_is_deterministic()
	_test_roll_distribution()
	_test_edge_tables()
	finish()


func _test_registry() -> void:
	check_eq(DataRegistry.get_all_item_ids().size(), SPRINT_ITEMS.size(), "registry has exactly the known items")
	for id in SPRINT_ITEMS:
		var item := DataRegistry.get_item(id)
		check(item != null, "item %s loaded" % id)
		if item == null:
			continue
		check(not item.display_name.is_empty(), "%s has display name" % id)
		check(item.get_stack_limit() >= 1, "%s stack limit >= 1" % id)
		check(item.value >= 0, "%s value >= 0" % id)
	check(DataRegistry.get_item(&"no_such_item") == null, "unknown id returns null")
	check_eq(DataRegistry.get_item(&"boxing_gloves").get_stack_limit(), 1, "equipment is non-stackable")


func _test_balance() -> void:
	var balance := DataRegistry.balance
	check(balance != null, "balance loaded")
	if balance != null:
		check_eq(balance.human_run_slots, 8, "human run slots = 8")
		check_eq(balance.dog_safe_slots, 2, "dog safe slots = 2")
		check_eq(balance.home_stash_slots, 30, "home stash slots = 30")


func _test_table_data(path: String) -> void:
	var table := load(path) as LootTableData
	check(table != null, "%s loads as LootTableData" % path)
	if table == null:
		return
	check(not table.entries.is_empty(), "%s has entries" % table.id)
	for entry in table.entries:
		check(entry.item != null and DataRegistry.has_item(entry.item.id), "%s entry item registered" % table.id)
		check(entry.weight > 0, "%s entry weight > 0" % table.id)
		check(entry.min_quantity <= entry.max_quantity, "%s entry quantity range valid" % table.id)
		if entry.item != null:
			check(entry.max_quantity <= entry.item.get_stack_limit(), "%s max quantity fits one stack" % entry.item.id)


func _test_roll_is_deterministic() -> void:
	var table := load(TABLE_PATHS[0]) as LootTableData
	check_eq(_roll_sequence(table, 12345), _roll_sequence(table, 12345), "same seed → same loot sequence")
	check(_roll_sequence(table, 12345) != _roll_sequence(table, 999), "different seed → different sequence")


func _test_roll_distribution() -> void:
	var table := load(TABLE_PATHS[1]) as LootTableData
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var rolls := 20000
	var total_weight := table.nothing_weight
	for entry in table.entries:
		total_weight += entry.weight
	var nothing := 0
	var counts: Dictionary[StringName, int] = {}
	for i in rolls:
		var stack := table.roll(rng)
		if stack == null:
			nothing += 1
			continue
		counts[stack.item_id] = counts.get(stack.item_id, 0) + 1
		var entry := _entry_for(table, stack.item_id)
		if stack.quantity < entry.min_quantity or stack.quantity > entry.max_quantity:
			check(false, "quantity %d out of range for %s" % [stack.quantity, stack.item_id])
	_check_ratio(nothing, rolls, float(table.nothing_weight) / total_weight, "nothing")
	for entry in table.entries:
		_check_ratio(counts.get(entry.item.id, 0), rolls, float(entry.weight) / total_weight, String(entry.item.id))


func _test_edge_tables() -> void:
	var rng := RandomNumberGenerator.new()
	var empty := LootTableData.new()
	check(empty.roll(rng) == null, "empty table rolls nothing")
	var only_nothing := LootTableData.new()
	only_nothing.nothing_weight = 5
	check(only_nothing.roll(rng) == null, "nothing-only table rolls nothing")
	var sure := LootTableData.new()
	var entry := LootEntry.new()
	entry.item = DataRegistry.get_item(&"tennis_ball")
	entry.weight = 1
	sure.entries = [entry]
	var stack := sure.roll(rng)
	check(stack != null and stack.item_id == &"tennis_ball", "single-entry table always rolls it")


func _check_ratio(count: int, total: int, expected: float, label: String) -> void:
	var actual := float(count) / total
	check(absf(actual - expected) < 0.015, "%s ratio %.3f ≈ %.3f" % [label, actual, expected])


func _entry_for(table: LootTableData, item_id: StringName) -> LootEntry:
	for entry in table.entries:
		if entry.item.id == item_id:
			return entry
	return null


func _roll_sequence(table: LootTableData, seed_value: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var result: Array = []
	for i in 30:
		var stack := table.roll(rng)
		result.append("-" if stack == null else "%s x%d" % [stack.item_id, stack.quantity])
	return result
