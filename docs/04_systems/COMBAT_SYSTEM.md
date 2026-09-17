# Human Combat System v0.1

## Intent
The dog raises and configures the human; the human fights autonomously.

The player should feel ownership of the outcome without becoming the direct fighter.

## MVP Stats
- STR — damage contribution
- END — HP / resilience
- AGI — action speed / movement contribution
- WIL — stability / resistance to pressure

Derived values may include:
- MaxHP
- Attack
- ActionInterval
- Stability

Keep formulas simple and centralized.

## Skill Model
Each active skill should support:
- id
- display_name
- cooldown
- preferred_range
- conditions
- priority
- effect
- animation_key

Sprint 02 active skills:
1. Punch — reliable close-range attack.
2. Kick — stronger/slower attack.
3. Block — defensive response.
4. Dodge — avoidance/reposition response.

## AI
Use a small priority evaluator:
1. Collect skills whose conditions are currently valid.
2. Remove skills on cooldown.
3. Score/compare priority.
4. Choose one valid action.
5. Execute.
6. Re-evaluate after action/recovery.

Do not hardcode a scripted sequence such as Punch → Kick → Block.

## Player Agency
Sprint 02 intentionally exposes the weakness of passive spectating.
Do NOT solve this yet with direct controls.

Observe during QA whether the player wants to intervene. Sprint 04 will use that evidence to tune dog QTE frequency/impact.

## Combat Presentation
The dog remains visually present during the fight.
Camera/framing should preserve the fiction that the player is watching their human fight another human.

## Defeat
On player-human defeat:
- combat ends;
- current run ends;
- normal unbanked run inventory is lost;
- dog safe inventory survives;
- permanent progression survives;
- minimal hospital/result state is shown.

No permanent Game Over.
