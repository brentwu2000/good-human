# ADR-008 — Seamless Real-Time Combat
> Delivered as ADR-007 in Update 002 Patch 01; renumbered because ADR-007 is Portrait 720×1280 in DECISIONS.md.
## Status
ACCEPTED
## Decision
GOOD HUMAN! has no separate Battle Scene. Exploration, encounters, human combat, dog movement, future dog interventions, disengagement and post-combat continuation all occur in the same Run World.
## Consequences
DogController remains active; human combat is autonomous actor behavior; camera stays in world; avoid a global COMBAT state that disables exploration; disengagement is spatial; future Bark/Leash Pull operate directly in world space; combat coordination must not assume the whole game pauses around one fight.
