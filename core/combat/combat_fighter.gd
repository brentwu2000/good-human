class_name CombatFighter
extends RefCounted
## Runtime state of one human in a CombatSimulation.

enum Phase { IDLE, WINDUP, ACTIVE, RECOVERY }

var data: FighterData
## 0 = player side, 1 = opponent side.
var side: int = 0
## Position on the arena line. Player starts left (negative).
var position: float = 0.0
var max_hp: float = 1.0
var hp: float = 1.0
var attack: float = 1.0
var action_interval: float = 1.0
var move_speed: float = 100.0
var stability: float = 0.0

var phase: Phase = Phase.IDLE
var action: CombatSkillData
var phase_time_left: float = 0.0
## Attacks wait until this simulation time.
var ready_at: float = 0.0
var cooldowns: Dictionary[StringName, float] = {}
## Dog agency (Sprint 04): no decisions until this simulation time (bark).
var distracted_until: float = -1.0
## A leash pull moved this fighter out of the way until this time.
var pulled_until: float = -1.0
## Skill usage count, for tests / debug.
var uses: Dictionary[StringName, int] = {}


func _init(fighter_data: FighterData, fighter_side: int, balance: GameBalance) -> void:
	data = fighter_data
	side = fighter_side
	max_hp = data.stats.max_hp(balance)
	hp = max_hp
	attack = data.stats.attack(balance)
	action_interval = data.stats.action_interval(balance)
	move_speed = data.stats.move_speed(balance)
	stability = data.stats.stability(balance)


func is_defeated() -> bool:
	return hp <= 0.0


func is_idle() -> bool:
	return phase == Phase.IDLE


func hp_ratio() -> float:
	return clampf(hp / max_hp, 0.0, 1.0)


func is_winding_up_attack() -> bool:
	return phase == Phase.WINDUP and action != null and action.effect == CombatSkillData.Effect.ATTACK


func is_guarding() -> bool:
	return phase == Phase.ACTIVE and action != null and action.effect == CombatSkillData.Effect.BLOCK


func is_evading() -> bool:
	return phase == Phase.ACTIVE and action != null and action.effect == CombatSkillData.Effect.DODGE


func cooldown_left(skill: CombatSkillData) -> float:
	return cooldowns.get(skill.id, 0.0)
