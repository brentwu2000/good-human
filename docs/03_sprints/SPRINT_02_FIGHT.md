# Sprint 02 — FIGHT

## Goal
Add the first playable dog-led human-vs-human encounter loop without turning the player into the human fighter.

Walk → encounter dog/human pair → choose provoke or leave → humans auto-fight → result → continue or defeat.

## Scope
- 1 player human
- 3 ordinary opponent dog/human pairs
- 1 intentionally overpowered hidden/optional opponent
- 4 human combat skills: Punch, Kick, Block, Dodge
- Autonomous skill selection
- Basic HP / Attack / Action Speed / Stability
- Encounter UI: Provoke / Leave
- Victory reward
- Defeat run resolution
- Dog Safe Inventory survives defeat
- Normal run inventory is lost on defeat
- Minimal hospital/result presentation
- No player-controlled attacks
- No dog combat QTE yet
- No deep human skill tree yet

## Required Flow
1. Start run.
2. Search and collect loot.
3. Encounter another dog/human pair.
4. Choose Leave; encounter ends without combat.
5. Encounter another pair.
6. Choose Provoke.
7. Humans enter autonomous combat.
8. Skills execute according to conditions/priorities.
9. One human reaches defeat.
10. Victory grants a reward and run continues.
11. Later challenge the overpowered opponent.
12. Player human is defeated.
13. Normal run inventory is lost.
14. Dog safe slots survive.
15. Return to result/home flow.

## Engineering Constraints
- Human combat logic must not live in DogController.
- Combat should be independently testable from the world scene.
- Skills should be data-driven Resources where practical.
- AI begins as a simple condition + priority evaluator.
- Avoid Behavior Trees in this sprint.
- Combat result must be explicit: victory / defeat / aborted.
- Opponent data must allow future persistent identity without implementing persistence now.

## Acceptance
- Three ordinary fights can complete without blocking errors.
- Player can leave an encounter without combat.
- Player cannot directly command attacks.
- Four skills visibly produce different behavior.
- Defeat loss rules are correct.
- Overpowered opponent is clearly difficult through outcome/behavior, not a visible “Lv.99” label.
- Sprint must pass Codex blind QA before DONE.
