# Physical Presence System v0.1

Required:
Dog↔PlayerHuman collision
Dog↔EnemyHuman collision
Dog↔EnemyDog collision
Dog↔World collision
Human↔World collision
Human↔Human collision-safe combat separation

Use:
- Hard Collision for world.
- Character Presence to prevent penetration and allow stable slide/deflection.
- Combat Separation for fighters; avoid two capsules continuously pushing.
- Soft Avoidance for ambient agents.

Dog slow contact: blocked, slides naturally around body.
Dog fast contact: blocked/deflected; human may show small balance/look reaction, never dog attack damage.
Human knockback: controlled displacement validated against world/characters.

Avoid an oversized invisible human capsule. Full per-limb physics is not required.

Out of scope: ragdoll, dog biting, collision damage, rope wrapping, leash-pole collision, crowd simulation.
