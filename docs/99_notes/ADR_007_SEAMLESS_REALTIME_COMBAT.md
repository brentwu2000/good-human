# ADR-007 — Seamless Real-Time Combat
## Status
ACCEPTED
## Decision
GOOD HUMAN! has no separate Battle Scene. Exploration, encounters, human combat, dog movement, future dog interventions, disengagement and post-combat continuation all occur in the same Run World.
## Consequences
DogController remains active; human combat is autonomous actor behavior; camera stays in world; avoid a global COMBAT state that disables exploration; disengagement is spatial; future Bark/Leash Pull operate directly in world space; combat coordination must not assume the whole game pauses around one fight.
