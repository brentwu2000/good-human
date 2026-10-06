# P-05 Weapon + Loot Systems

## Archetypes
UNARMED: close, mobile; Jab/Hook/Kick/Block/Dodge.
UMBRELLA: medium reach, precision/defense; Poke/Quick Swing/Umbrella Guard/Counter Poke.
LONG_OBJECT: medium-long range control; Thrust/Sweep/Heavy Swing/Keep-Distance Guard; weak when crowded.
HEAVY_BLUNT: high commitment/impact; Heavy Swing/Overhead Smash/Shove-Guard; slow recovery.

## Loot Classes
WEAPON — changes moveset.
HUMAN_GEAR — movement/defense/recovery.
DOG_GEAR — search/leash/safe-carry utility.
VALUABLE — primarily economic/collection value.

## Ownership
WORLD → HUMAN_CARRIED_UNBANKED → HOME_STASH/BANKED.
Eligible small loot may move to DOG_SAFE. Large weapons cannot disappear into a tiny dog backpack.

## Pickup
Dog discovers via search/world cues. Human approaches and picks/equips when context permits. Prefer physical presentation over magical inventory teleport.

## Swap
Compare Reach / Speed / Defense / Impact / Condition, not only DPS.

## AI Integration
Action choice uses combat style + weapon archetype + range + opponent state + obstacles + dog interference.
Example CALM+UMBRELLA: backstep → enemy whiff → counter poke → sidestep.
UNTRAINED+UMBRELLA: bad spacing → large swing → miss → exposed recovery.

## Contact
Weapon effects only through P-04 CONTACT_WINDOW + spatial validation. No invisible range.

## Condition
Prototype: GOOD / WORN / CRITICAL / BROKEN. Data-driven. No crafting/repair tree in P-05.
