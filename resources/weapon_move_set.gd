class_name WeaponMoveSet
extends Resource
## P-05 (P05-02): what a human can do holding something. Attacks and defences
## are ordinary CombatSkillData, so contact, reach, phases and the AI's choice
## all work exactly as they do for fists (P-04 stays authoritative); the
## weapon also moves where the fighter wants to stand.

@export var id: StringName
@export var attacks: Array[CombatSkillData] = []
@export var defenses: Array[CombatSkillData] = []
## Where this weapon wants the fight, in arena units (100 = 1 m). Below 0:
## the ordinary hand-to-hand spacing (`SpacingData`).
@export var ideal_min: float = -1.0
@export var ideal_max: float = -1.0


func skills() -> Array[CombatSkillData]:
	var all: Array[CombatSkillData] = []
	all.append_array(attacks)
	all.append_array(defenses)
	return all
