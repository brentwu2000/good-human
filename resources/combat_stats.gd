class_name CombatStats
extends Resource
## A human's four base stats. Derived values use the formulas in GameBalance.

@export_range(1, 99) var strength: int = 5
@export_range(1, 99) var endurance: int = 5
@export_range(1, 99) var agility: int = 5
@export_range(1, 99) var will: int = 5


func max_hp(balance: GameBalance) -> float:
	return balance.hp_base + endurance * balance.hp_per_endurance


func attack(balance: GameBalance) -> float:
	return balance.attack_base + strength * balance.attack_per_strength


## Pause after an action before the next attack can start.
func action_interval(balance: GameBalance) -> float:
	return maxf(balance.action_interval_base - agility * balance.action_interval_per_agility, balance.action_interval_min)


func move_speed(balance: GameBalance) -> float:
	return balance.move_speed_base + agility * balance.move_speed_per_agility


## Resistance to being staggered out of a wind-up.
func stability(balance: GameBalance) -> float:
	return will * balance.stability_per_will
