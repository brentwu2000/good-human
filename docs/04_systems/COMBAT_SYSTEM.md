# Human Combat System v0.2 — Seamless Real-Time
Human combat is live world simulation inside the current Run World.

## Rules
- No BattleScene or arena teleport.
- No global exploration freeze.
- DogController remains active.
- Camera remains in Run World.
- Combat is actor state, not a separate game mode.

Human states: FOLLOW / COMBAT / DOWN. Dog: FREE.

Stats: STR, END, AGI, WIL. Derived: MaxHP, Attack, ActionInterval, Stability.

Skills are data-driven: id, display_name, cooldown, preferred_range, conditions, priority, effect, animation_key. Sprint 02 uses Punch, Kick, Block, Dodge.

AI: collect valid off-cooldown skills → evaluate conditions/priority → execute → recover/re-evaluate.

Do not deeply implement group combat yet, but avoid architecture that assumes only one global fight can ever exist. A CombatCoordinator/Registry may track active engagements.

Player-human defeat ends the run; normal unbanked inventory is lost; dog-safe inventory and permanent progression survive.
