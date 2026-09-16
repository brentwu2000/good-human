class_name LootTableData
extends Resource
## Weighted roll: one entry (or nothing) per roll.

@export var id: StringName
@export var entries: Array[LootEntry] = []
@export_range(0, 1000) var nothing_weight: int = 0


## Returns the rolled stack, or null for "nothing". Uses the caller's RNG so
## results follow the run seed.
func roll(rng: RandomNumberGenerator) -> ItemStack:
	var total := nothing_weight
	for entry in entries:
		if entry.item != null:
			total += maxi(entry.weight, 0)
	if total <= 0:
		return null

	var pick := rng.randi_range(0, total - 1)
	if pick < nothing_weight:
		return null
	pick -= nothing_weight
	for entry in entries:
		if entry.item == null or entry.weight <= 0:
			continue
		if pick < entry.weight:
			var low := mini(entry.min_quantity, entry.max_quantity)
			var high := maxi(entry.min_quantity, entry.max_quantity)
			return ItemStack.new(entry.item, rng.randi_range(low, high))
		pick -= entry.weight
	return null
