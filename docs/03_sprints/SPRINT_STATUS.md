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
| P1-009 | Combat presentation | TODO |
| P1-010 | Encounter trigger | TODO |
| P1-011 | Provoke / Leave | TODO |
| P1-012 | Ordinary opponents | TODO |
| P1-013 | Old Master encounter | TODO |
| P1-014 | Victory reward | TODO |
| P1-015 | Defeat resolution | TODO |
| P1-016 | Loss / dog-safe preservation | TODO |
| P1-017 | Minimal hospital/result | TODO |
| P1-018 | Debug/test hooks | TODO |
| P1-019 | Android combat validation | TODO |
| P1-020 | Sprint 02 QA readiness | TODO |
