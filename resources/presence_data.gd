class_name PresenceData
extends Resource
## P-04 physical presence tuning (docs/05_data/P04_COMBAT_TUNING_SCHEMA.md,
## PresenceData). Body shapes are deliberately no wider than the bodies drawn:
## an oversized invisible capsule reads as a force field, not a person.

## A standing human, before the fighter's own body_scale.
@export var human_radius: float = 0.24
@export var human_height: float = 1.72
## A greybox dog lying along its own facing, before the breed's size.
@export var dog_radius: float = 0.2
@export var dog_length: float = 0.8
@export var dog_center_height: float = 0.38
## Running into someone at this speed (m/s, towards them) or faster is a bump
## they feel: a small balance or look reaction, never damage. Walking is 3.5,
## sprinting 6.2.
@export var fast_dog_contact_speed: float = 4.5
## Seconds before the same dog can bump anyone again.
@export var contact_cooldown: float = 0.6
## How far the bumped body gives (m) and how long it takes to settle (s).
@export var minor_balance_shift: float = 0.08
@export var minor_balance_seconds: float = 0.35
