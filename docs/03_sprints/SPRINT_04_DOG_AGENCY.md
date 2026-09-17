# Sprint 04 — DOG AGENCY

## Status
DESIGN MAY START NOW. ENGINEERING WAITS FOR P-01 CAMERA GATE.

## Goal
During seamless autonomous human combat, the player remains meaningfully active as the dog.

Core fantasy:
“My human fights for me, but I can still run around and cause useful, funny, risky things to happen.”

## P0 Prototype
- Free dog movement remains active.
- Bark intervention.
- Leash Pull intervention.
- Nearby Interactable remains usable during conflict.
- Opponent dog has basic reactions.
- Spatial disengagement remains valid.
- DOG AGENCY integrates with TRAINING events.

## Do Not Build Yet
Dog direct combat, biting humans, combo systems, large dog skill tree, item-weapon system, complex opponent-dog AI, multiplayer combat.

## Camera Dependency
Implementation parameters depend on P-01 result:
A Top-down: direction/range/vector based.
B/C Dog Eye: facing, spatial position, camera readability and physical movement become more important.

Do not lock final input/UI until Camera Gate.

## Acceptance
Player is never reduced to watching two humans auto-fight.
Bark and Leash Pull create understandable consequences.
Bad timing/position can be neutral or harmful.
Player can ignore the fight and interact/move where intentionally allowed.
Actions can emit TrainingEvents.
No BattleScene or modal combat UI is introduced.
