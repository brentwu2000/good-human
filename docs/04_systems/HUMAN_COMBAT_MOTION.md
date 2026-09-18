# Human Combat Motion Prototype

## Problem
Damage events without physical motion cannot validate combat camera, dog intervention or atmosphere.

## Required States
IDLE_COMBAT
APPROACH
CIRCLE
WINDUP
ATTACK
BLOCK
DODGE
HIT_REACT
STAGGER
DOWN
RECOVER

## Required Attacks
### Punch
Readable windup → strike → contact window → recovery. Fast, short range, light reaction.

### Kick
Longer windup/recovery, larger body commitment and stronger reaction/knockback.

Exact timings are data-driven. Initial feel target: attacks must telegraph clearly on a mobile-sized screen.

## Spacing
Humans must not stand fixed and exchange HP. Combat AI cycles through approach, angle/circle, attack/defense, reaction and spacing reset.

## Hit Presentation
On confirmed hit:
- animation/contact pose;
- victim hit reaction;
- small positional knockback where appropriate;
- impact SFX;
- restrained camera impulse;
- short hit-stop candidate ~50–90 ms, tunable.

## Dog Agency Dependency
Heavy/meaningful attacks need readable windup so the dog can react with Bark or Leash Pull. If the player cannot visually anticipate an attack, intervention design fails.

## Debug
Combat log is debug-only. Normal prototype must remain understandable with combat text hidden.
