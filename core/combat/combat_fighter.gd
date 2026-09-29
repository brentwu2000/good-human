class_name CombatFighter
extends RefCounted
## Runtime state of one human in a CombatSimulation.

## ACTIVE is a guard or a dodge being held. An attack runs WINDUP → STRIKE →
## CONTACT → FOLLOW_THROUGH → RECOVERY instead (P-04).
enum Phase { IDLE, WINDUP, ACTIVE, RECOVERY, STRIKE, CONTACT, FOLLOW_THROUGH }
## What their feet are doing while no action has them (P-04).
enum Footwork { HOLD, APPROACH, CIRCLE, SIDESTEP, BACKSTEP }

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
## When the current attack's wind-up began. An opponent reacts to a telegraph
## starting, not to it merely being under way, so making a telegraph longer
## makes it readable without handing the defender a longer free window.
var windup_started_at: float = -99.0
var cooldowns: Dictionary[StringName, float] = {}
## Dog agency (Sprint 04): no decisions until this simulation time (bark).
var distracted_until: float = -1.0
## Hits against this fighter before this time exploit an opening (bark).
var exposed_until: float = -1.0
## Last simulation time this fighter was moving out of the way in a dodge.
var last_evaded_at: float = -99.0
## Being yanked by the leash until this time (P04-10): the owner is moving,
## over `yank_left` more seconds at `yank_speed` units/s. Nothing protects
## them but the distance it puts between them and the blow.
var pulled_until: float = -1.0
var yank_left: float = 0.0
var yank_speed: float = 0.0
## The current attack missed only because its target was hauled away by the
## leash: the attacker did not overreach, so no whiff penalty and no opening.
var whiff_excused: bool = false
## P-04 footwork. `lateral` is which way round the opponent they prefer
## (+1 / -1). A step (sidestep, backstep) is a short committed move: it runs
## for `step_left` seconds at `step_speed` units/s.
var footwork: Footwork = Footwork.HOLD
var lateral: float = 1.0
var step_left: float = 0.0
var step_speed: float = 0.0
## The current attack has already landed (or been blocked or dodged): it
## never lands twice.
var connected: bool = false
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


## Released and still extended: the strike, its contact window and the follow-through.
func is_striking() -> bool:
	return phase in [Phase.STRIKE, Phase.CONTACT, Phase.FOLLOW_THROUGH]


func is_guarding() -> bool:
	return phase == Phase.ACTIVE and action != null and action.effect == CombatSkillData.Effect.BLOCK


func is_evading() -> bool:
	return phase == Phase.ACTIVE and action != null and action.effect == CombatSkillData.Effect.DODGE


func is_stepping() -> bool:
	return step_left > 0.0


func cooldown_left(skill: CombatSkillData) -> float:
	return cooldowns.get(skill.id, 0.0)
