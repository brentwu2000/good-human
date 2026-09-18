class_name RunValue
extends RefCounted
## Sprint 05 (P4-001, GREED_RISK_SYSTEM): what a walk is worth right now, split
## into the layers the player is actually deciding between.
##
## SAFE      — the dog's own bag. Comes home even when the walk goes wrong.
## UNBANKED  — what the owner carries. Lost on defeat or a failed walk.
## PERMANENT — the Home stash. A walk never touches it, so it is not here.
##
## Pure reading of the two run inventories: it owns no state and decides
## nothing. Presentation (P4-002) and temptation (P4-003) read it; the rules
## for what is lost stay in RunManager.

var safe_value: int = 0
var unbanked_value: int = 0
var safe_slots: int = 0
var unbanked_slots: int = 0
var unbanked_capacity: int = 0


static func of(safe: Inventory, unbanked: Inventory) -> RunValue:
	var value := RunValue.new()
	if safe != null:
		value.safe_value = safe.total_value()
		value.safe_slots = safe.used_slot_count()
	if unbanked != null:
		value.unbanked_value = unbanked.total_value()
		value.unbanked_slots = unbanked.used_slot_count()
		value.unbanked_capacity = unbanked.capacity
	return value


func total() -> int:
	return safe_value + unbanked_value


## 0..1 of the walk's value that a defeat would take. 0 when there is nothing
## to lose, so an empty walk never reads as risky.
func at_risk_share() -> float:
	var sum := total()
	return 0.0 if sum <= 0 else float(unbanked_value) / float(sum)


## Nothing gained yet: worth saying nothing about.
func is_empty() -> bool:
	return total() <= 0 and safe_slots == 0 and unbanked_slots == 0


## The owner's bag is full, so searching on can only trade one thing for another.
func is_bag_full() -> bool:
	return unbanked_capacity > 0 and unbanked_slots >= unbanked_capacity


func equals(other: RunValue) -> bool:
	return other != null \
		and safe_value == other.safe_value and unbanked_value == other.unbanked_value \
		and safe_slots == other.safe_slots and unbanked_slots == other.unbanked_slots
