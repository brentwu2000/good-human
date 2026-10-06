class_name CombatStyleData
extends Resource
## P05-07: how a human uses what they are holding. Only applies armed — bare
## hands stay the P-04 baseline. The same umbrella is a different fight in
## different hands (D5W-10): CALM backs off, lets them whiff and counters;
## UNTRAINED stands wrong, goes for the big swing and is left open.

enum Style { UNTRAINED, SCRAPPER, CALM }

@export var style: Style = Style.UNTRAINED
## Added to the weapon's ideal distance (units): + holds further out.
@export var ideal_shift: float = 0.0
## Untrained: where they think they should stand drifts by up to this much
## (units), re-picked every `jitter_seconds`.
@export var ideal_jitter: float = 0.0
@export var jitter_seconds: float = 2.0
## Choice weights, multiplied onto priority.
## A heavy blow thrown into nothing (the target is not open).
@export var heavy_unopened_weight: float = 1.0
## A counter (TARGET_OPEN).
@export var counter_weight: float = 1.0
## The quickest attack they have.
@export var quick_weight: float = 1.0
## The biggest attack they have, whatever the moment.
@export var biggest_weight: float = 1.0
## How far past its real reach they think a weapon goes (0.15 = 15 %): they
## start a swing out of range and it whiffs. Contact still uses the real reach.
@export var reach_misjudge: float = 0.0
## Extra recovery after a whiff (s): overreach they have not learned to avoid.
@export var whiff_extra: float = 0.0
## P-05 / Sprint 05 greed revision: the kinds of weapon this style does well
## with ("a weapon fitting the current human/style"). Untrained: none.
@export var suited_archetypes: Array[WeaponData.Archetype] = []
## Who grows into this style once trained: personality tags and tendencies
## of the human (S06 backgrounds).
@export var leaning_tags: Array[StringName] = []
