class_name CombatSkillData
extends Resource
## One autonomous human combat skill. The AI picks among valid skills by
## priority; nothing here is a scripted sequence.

enum Effect { ATTACK, BLOCK, DODGE }
## When the skill is allowed to start.
enum Condition {
	TARGET_IN_RANGE,  ## Opponent within preferred_range.
	INCOMING_ATTACK,  ## Opponent is winding up an attack that can reach us.
}

@export var id: StringName
@export var display_name: String
@export var effect: Effect = Effect.ATTACK
@export var condition: Condition = Condition.TARGET_IN_RANGE
## Higher wins when several skills are valid.
@export var priority: int = 10
@export var cooldown: float = 0.0
## Reach for attacks (arena units).
@export var preferred_range: float = 70.0
@export var animation_key: StringName

@export_group("Timing")
## Telegraph before the effect lands.
@export var windup: float = 0.3
## Attack: unused. Block/Dodge: how long the guard / evasion lasts.
@export var active_time: float = 0.0
@export var recovery: float = 0.3

@export_group("Effect")
## Attack damage multiplier on the attacker's Attack.
@export var power: float = 1.0
## Interrupts a target's wind-up when greater than the target's Stability.
@export var stagger: float = 0.0
## Block: fraction of damage removed.
@export_range(0.0, 1.0) var damage_reduction: float = 0.0
## Dodge: distance moved away from the opponent during active_time.
@export var reposition_distance: float = 0.0
