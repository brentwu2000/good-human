# Leash Gameplay v0.1

## Purpose
Make the physical connection between dog and owner one of GOOD HUMAN!'s signature systems.

## Prototype Model
Track:
- dog-owner distance
- slack length
- tension
- pull direction
- owner movement state
- conflict state

## Principle
Leash behavior should emerge from movement where possible.

Dog accelerates beyond slack distance → tension rises → owner reacts.

## Combat
Pull can influence owner position without direct human control.

## Exploration / TRAIN
The same system should support:
- dragging a weak/untrained owner;
- improved following as human grows;
- comedy/stumble;
- RUN/STRAIN TrainingEvents.

Avoid building separate “combat leash” and “exploration leash” systems unless technically necessary.
