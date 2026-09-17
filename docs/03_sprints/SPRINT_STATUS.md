# Sprint Status

Allowed states: `TODO`, `IN_PROGRESS`, `BLOCKED`, `REVIEW`, `DONE`

## Sprint 01 — WALK

| ID | Task | Status |
|---|---|---|
| P0-001 | Project structure | REVIEW |
| P0-002 | Game Autoload / scene flow | REVIEW |
| P0-003 | SaveManager | REVIEW |
| P0-004 | DogController | REVIEW |
| P0-005 | Mobile input | REVIEW |
| P0-006 | Greybox map | REVIEW |
| P0-007 | Interactable | REVIEW |
| P0-008 | ItemData | REVIEW |
| P0-009 | Inventory | REVIEW |
| P0-010 | LootTable | REVIEW |
| P0-011 | SearchPoint | REVIEW |
| P0-012 | Dog safe slots | REVIEW |
| P0-013 | RunManager | REVIEW |
| P0-014 | ExtractionPoint | REVIEW |
| P0-015 | Run Result | REVIEW |
| P0-016 | Home Stash | REVIEW |
| P0-017 | Second Run reset | REVIEW |
| P0-018 | Debug Panel | REVIEW |
| P0-019 | Android export | TODO |
| P0-020 | Sprint playtest readiness | REVIEW |

Claude owns engineering status. Codex QA does not change implementation task states; QA produces reports.

## Engineering Notes (Claude)
- Validation: `tests/run_all.sh` (8 headless scene tests incl. automated golden path).
- Builds (gitignored, rebuilt by Claude): owner/debug `build/windows/GoodHuman.exe`; blind QA release (no debug panel) `build/windows_qa/GoodHuman.exe`.
- Debug panel (debug builds only) is hidden: F1, or tap the run timer 5 times quickly.
- P0-019 deferred by owner decision (2026-09-17): Android is not validated for now. When resumed, it needs JDK 17 + Android SDK on the dev machine.
- P0-020: owner playtest #1 → "沒感覺"; tuning pass applied (owner on leash, loot value/rarity feedback, pre-rolled scent hints, discard). Playtest #2 → "好多了". Tuned values (3:00 / 5:00 extraction, 16 search points) approved and written into SPRINT_01_WALK.md. Codex blind QA deferred by owner (2026-09-17): the Codex environment could not operate the game window. Validation so far = owner playtests + automated `golden_path_test`.

## Sprint 02 — FIGHT
Do not begin until Sprint 01 is implementation-complete and has completed independent Codex QA.

> Owner decision (2026-09-17): start Sprint 02 now. Sprint 01 is implementation-complete (REVIEW); its Codex blind QA remains deferred and P0-019 Android stays deferred.

| ID | Task | Status |
|---|---|---|
| P1-001 | Combat foundation | REVIEW |
| P1-002 | Human combat stats | REVIEW |
| P1-003 | Combat skill data model | REVIEW |
| P1-004 | Punch | REVIEW |
| P1-005 | Kick | REVIEW |
| P1-006 | Block | REVIEW |
| P1-007 | Dodge | REVIEW |
| P1-008 | Condition + priority AI | REVIEW |
| P1-009 | Combat presentation | REVIEW |
| P1-010 | Encounter trigger | REVIEW |
| P1-011 | Provoke / Leave | REVIEW |
| P1-012 | Ordinary opponents | REVIEW |
| P1-013 | Old Master encounter | REVIEW |
| P1-014 | Victory reward | REVIEW |
| P1-015 | Defeat resolution | REVIEW |
| P1-016 | Loss / dog-safe preservation | REVIEW |
| P1-017 | Minimal hospital/result | REVIEW |
| P1-018 | Debug/test hooks | REVIEW |
| P1-019 | Android combat validation | TODO |
| P1-020 | Sprint 02 QA readiness | REVIEW |

## Sprint 02 Engineering Notes (Claude)
- Reworked for Patch 01 / seamless real-time combat: removed the arena teleport, Provoke/Leave modal, walk-timer pause, dog input lock and bag lock.
- Validation: `tests/run_all.sh` (10 headless scene tests). `combat_sim_test` = stats, 4 skills, AI, win-rate bands; `combat_world_test` = in-world provoke, dog free during combat, spatial disengagement, 3 fights, Old Master defeat, hospital result, loss rules.
- Architecture: `CombatSimulation` (pure logic, seeded from run RNG) laid along the line between the two humans by `Engagement`; `CombatCoordinator` (scene-scoped node, list of engagements) drives actors; `RunManager.grant_reward` / `defeat_run` apply run rules. Player human `HumanFollower` has FOLLOW / COMBAT / DOWN; DogController is unchanged.
- Flow: dog interacts with a pair (prompt 😤 挑釁) → humans fight where they stand → dog stays controllable, timer keeps running → victory (reward roll, owner follows again) / defeat (owner DOWN ~1.6 s → run ends as DEFEATED, hospital result) / dog runs further than `disengage_distance` (GameBalance, 480) → DISENGAGED, owner follows, pair walks back and can be provoked again. Walking past a pair is avoidance.
- Map: 4 pairs in `Actors`. The 3 ordinary pairs are shuffled over 3 spots each run; the Old Master is fixed under the big tree.
- Placeholder balance (40 seeds): player wins roughly 85% vs Jogger, 70% vs Delivery Worker, 70% vs Gym Regular, ~0% vs Old Master. Player HP resets each fight.
- Debug panel: put dog at next pair, force win / force lose.
- Owner decisions (2026-09-17): Sprint 02 Codex blind QA not run for now (tasks stay REVIEW, not DONE); player HP resets per fight and the bag stays usable during combat for now; Patch 01's ADR-007 renumbered to ADR-008 (ADR-007 = Portrait).
- P1-019 deferred with P0-019 (owner decision 2026-09-17: Android not validated for now).
- Builds: owner/debug `build/windows/GoodHuman.exe`; blind QA release `build/windows_qa/GoodHuman.exe`. Blind QA brief: `docs/07_qa/SPRINT_02_QA_BRIEF.md` (its Provoke-vs-Leave question now means provoking vs walking past).
