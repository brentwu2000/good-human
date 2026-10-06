class_name WeaponCondition
extends RefCounted
## P05-09: how worn a carried weapon is. Every blow it lands or takes wears
## it a little; it reads in the object itself (a worn umbrella sags, a
## critical one is bent) and, critical, it hits softer; at nothing it breaks
## and the human is empty-handed again. No repair or crafting (P-05 scope).

enum State { GOOD, WORN, CRITICAL, BROKEN }


## What is left in `stack` of `weapon` (a stack that never wore is as new).
static func left(weapon: WeaponData, stack: ItemStack) -> int:
	if weapon == null or weapon.condition_max <= 0:
		return -1
	return weapon.condition_max if stack == null or stack.condition < 0 else stack.condition


static func state(weapon: WeaponData, condition: int) -> State:
	if weapon == null or weapon.condition_max <= 0 or condition < 0:
		return State.GOOD
	if condition <= 0:
		return State.BROKEN
	var share := float(condition) / weapon.condition_max
	var balance := DataRegistry.balance
	if share < balance.weapon_critical_below:
		return State.CRITICAL
	if share < balance.weapon_worn_below:
		return State.WORN
	return State.GOOD


## A blow's power in hands holding something this worn.
static func power_scale(current: State) -> float:
	return DataRegistry.balance.weapon_critical_power if current == State.CRITICAL else 1.0


## Something found in the street is rarely new: somewhere between
## `weapon_found_min` of its use and all of it. Rolled from the run seed and
## where it was found, so it never moves the run's own random sequence.
static func roll_found(weapon: WeaponData, run_seed: int, place: StringName) -> int:
	if weapon == null or weapon.condition_max <= 0:
		return -1
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([run_seed, place])
	return maxi(1, roundi(weapon.condition_max * rng.randf_range(DataRegistry.balance.weapon_found_min, 1.0)))


static func label(current: State) -> String:
	return ["完好", "有點舊了", "快壞了", "壞掉了"][current]
