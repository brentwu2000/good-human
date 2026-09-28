# P-04 — HUMAN BRAWL FEEL + PHYSICAL PRESENCE

## Goal
Turn state/text-driven combat into a physically readable 30–60 second street brawl through Dog POV.

## Hard Rules
- No primary character may visibly pass through another.
- Damage only during a valid contact window and spatial reach.
- Humans use footwork; no stationary alternating attacks.
- Dog remains freely controllable.
- Dog POV keeps the active fight readable.
- With HP, damage numbers, combat text and debug hidden, attacks, misses, blocks, dodges, heavy hits, knockdowns and dog intervention must be understandable.

Obvious Dog↔Human or Human↔Human penetration = Critical Fail.

## Loop
ASSESS → APPROACH/CIRCLE → WINDUP → STRIKE → CONTACT or MISS/BLOCK/DODGE → FOLLOW_THROUGH → RECOVERY → REPOSITION.

## P0
Movement: APPROACH, CIRCLE L/R, SIDESTEP, BACKSTEP, REPOSITION.
Offense: JAB, HEAVY_HOOK, KICK.
Defense: BLOCK, DODGE.
Reaction: HIT_LIGHT, HIT_HEAVY, STUMBLE, DOWN.

## Spacing
TOO_FAR → approach.
IDEAL → circle/attack.
TOO_CLOSE → backstep/separate.

## Dog
Dog can circle, move behind opponent, Bark, Pull and disengage. Collision affects navigation but does not become direct dog combat.
