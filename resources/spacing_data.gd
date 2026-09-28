class_name SpacingData
extends Resource
## P-04 combat spacing and footwork (docs/05_data/P04_COMBAT_TUNING_SCHEMA.md,
## SpacingData). Distances are simulation units (100 = 1 m). Speeds that a
## fighter's own stats already set are scales on those stats, so training
## still shows in how someone moves.

## Inside this band a fighter is where they want to be: they circle and pick
## their moment. Closer is too close and they step back out.
@export var ideal_min: float = 58.0
@export var ideal_max: float = 68.0
## Two people never stand closer than this, centre to centre. It is the width
## of two bodies (2 × 0.27 m, the drawn torso) and a little air.
@export var hard_min_separation: float = 56.0
## Scale on the fighter's own move speed when closing the gap.
@export var approach_speed: float = 1.0
## Sideways speed round the opponent while circling (units/s).
@export var circle_speed: float = 30.0
## A backstep: how far and how quickly.
@export var backstep_distance: float = 30.0
@export var backstep_seconds: float = 0.3
## A sidestep: a quick step round the opponent, and how often one is taken
## (chance per second while circling).
@export var sidestep_distance: float = 35.0
@export var sidestep_seconds: float = 0.25
@export var sidestep_chance: float = 0.25
## Chance per second of switching which way they circle.
@export var lateral_flip_chance: float = 0.15
## After an attack, the chance they step back out and reset the distance
## rather than staying on top of the other person.
@export var reset_chance: float = 0.4
