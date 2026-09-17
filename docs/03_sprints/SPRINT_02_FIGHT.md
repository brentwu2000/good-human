# Sprint 02 — FIGHT v0.2
## Non-negotiable
Combat is seamless real-time inside the current Run World. There is no BattleScene, arena/loading transition, modal Fight/Run screen, or global combat mode that disables the dog.

## Flow
Walk → see dog/human pair → approach/provoke in world → humans fight autonomously at current positions → dog remains freely controllable → victory/defeat/spatial disengagement → immediately continue the same run.

## Runtime
- DogController stays active throughout combat.
- Camera stays in Run World.
- Human actor states: FOLLOW / COMBAT / DOWN.
- Dog remains FREE.
- Search/world systems are not globally frozen by a fight.
- 3 ordinary opponent pairs + 1 Old Master pair.
- Skills: Punch, Kick, Block, Dodge.
- AI: condition + priority evaluation.
- No direct human attack controls.

## Disengagement
The dog physically runs away. After exceeding a configurable distance, the player human attempts to break combat and follow. Sprint 02 may use a simple reliable rule; keep it extensible.

## Architecture
Prefer RunWorld containing DogController, PlayerHuman/HumanCombatController, opponent pairs, and a CombatCoordinator/Registry. CombatCoordinator coordinates active conflicts; it is not a separate gameplay scene.

## Acceptance
Combat starts/ends without scene changes; dog remains controllable; humans auto-fight; moving away can disengage; victory returns immediately to exploration; defeat/loss rules work; no arena/loading transition; Codex blind QA passes.
