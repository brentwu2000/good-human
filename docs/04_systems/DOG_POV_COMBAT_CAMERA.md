# Dog POV Combat Camera v0.1

## Camera Grammar
EXPLORE: dog-height third person, dog visible.
TENSION: push closer/lower; focus weight shifts toward encounter.
COMBAT_SNAP: smooth 0.35–0.8s transition to dog-eye first person.
COMBAT: first person at dog eye height; auto-frame CombatCenter.
CRISIS: modest tightening only; never sacrifice navigation.
RESOLUTION: hold emotional beat.
RELEASE: smooth pull-back; dog re-enters frame; Explore resumes.

## CombatCenter
Primary framing target is a dynamic point between PlayerHuman and active OpponentHuman, biased slightly toward PlayerHuman. Do not hard-code final weights; expose them for tuning.

Camera position follows PlayerDog. Camera orientation automatically tracks CombatCenter using a soft screen-space dead zone and damped rotation. Player does not need manual camera aiming during combat.

## Dog Movement
Movement input remains world-relative/camera-relative according to the selected prototype control scheme. Camera tracking must not forcibly rotate the dog's locomotion vector. Test circling both directions, backing away, approaching, flanking and disengaging.

## Framing Rules
- both fighting humans should remain visible whenever practical;
- prioritize owner if both cannot fit;
- preserve enough peripheral vision for dog intervention;
- leash may enter lower frame when tension is relevant;
- avoid constant micro-corrections;
- cap angular velocity/acceleration to reduce nausea;
- handle wall/character occlusion without violent camera jumps.

## First-person Body
P-03 does not require full visible dog body. Optional lower-frame muzzle/ears/leash can be tested only if they improve identity without obscuring combat.

## Debug Tuning
Show current camera phase, CombatCenter, target/current yaw-pitch, angular velocity, dog→owner distance, dog→combat-center distance, FOV/distance profile and occlusion state.
