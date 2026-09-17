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
- Owner decisions (2026-09-17): Sprint 02 Codex blind QA not run for now (tasks stay REVIEW, not DONE); player HP resets per fight and the bag stays usable during combat for now; ADR numbering follows the update packages (ADR-007 seamless combat, ADR-008 training, ADR-009 desires, ADR-010 camera); the local Portrait decision is ADR-L01.
- P1-019 deferred with P0-019 (owner decision 2026-09-17: Android not validated for now).
- Builds: owner/debug `build/windows/GoodHuman.exe`; blind QA release `build/windows_qa/GoodHuman.exe`. Blind QA brief: `docs/07_qa/SPRINT_02_QA_BRIEF.md` (question 5 updated to provoking vs walking past).

## Sprint 03 — TRAIN
Do not begin until the Phase 2 Vertical Slice Gate (`docs/07_qa/PHASE2_VERTICAL_SLICE_GATE.md`) is reviewed.

> Gate reviewed 2026-09-17: PROCEED WITH CHANGES (`docs/07_qa/reports/PHASE2_VERTICAL_SLICE_GATE_REVIEW.md`). Sprint 03 started.

| ID | Task | Status |
|---|---|---|
| P2-001 | TrainingEvent model | REVIEW |
| P2-002 | TrainingTracker | REVIEW |
| P2-003 | RUN generation | REVIEW |
| P2-004 | STRAIN generation | REVIEW |
| P2-005 | COURAGE generation | REVIEW |
| P2-006 | SOCIAL generation | REVIEW |
| P2-007 | ENDURE generation | REVIEW |
| P2-008 | Anti-farming rules | REVIEW |
| P2-009 | RunTrainingSummary | REVIEW |
| P2-010 | Training conversion | REVIEW |
| P2-011 | Defeat partial conversion | REVIEW |
| P2-012 | Persistent Growth data | REVIEW |
| P2-013 | GrowthResolver | REVIEW |
| P2-014 | Prototype perks | REVIEW |
| P2-015 | Visible growth effect 1 | REVIEW |
| P2-016 | Visible growth effect 2 | REVIEW |
| P2-017 | Visible growth effect 3 | REVIEW |
| P2-018 | Training result presentation | REVIEW |
| P2-019 | Debug tools | REVIEW |
| P2-020 | Sprint 03 QA readiness | REVIEW |

## Sprint 03 Engineering Notes (Claude)
- Validation: `tests/run_all.sh` (12 headless scene tests). `training_core_test` = tracker anti-farming, conversion, resolver, perks, traits, persistence; `training_world_test` = all five tags from world behaviour through real scenes, extraction/defeat conversion, result/Home wording, trained vs untrained owner behaviour, debug tools.
- Pipeline (ADR-008): world moment → `TrainingObserver` → `RunManager.record_training` → `TrainingTracker` (run-scoped) → `RunTrainingSummary` on the RunResult → `Game.finish_run` → `GrowthResolver` → `HumanGrowth` (save: `human.growth_data`). All numbers in `data/training/training_balance.tres`; events in `data/training/events`, perks in `data/training/perks`.
- Behaviours that train: dragging the owner at speed, escaping a fight (RUN); walking with 6+ bag slots, pulling while the owner is stopped (STRAIN); provoking (Old Master counts double), lingering near the Old Master, escaping while hurt (COURAGE); lingering near any pair ~3 s (SOCIAL); long walk, pushing through exhaustion, hard win, defeat (ENDURE).
- Anti-farming: per-event cooldown, once per pair per walk, repeat diminishing ×0.7, per-tag run cap 12.
- Conversion: extraction 100%, defeat 50%, other failure 50%.
- Visible growth (`OwnerBehavior`, no stats UI): stumbling when dragged (RUN), exhaustion stop length and frequency (ENDURE), hanging back near pairs (COURAGE), heavy-bag slowdown (STRAIN), greeting pairs (SOCIAL perk). Growth also adds small combat stat bonuses; appearance never changes.
- Perks (8, 2 hidden): 被迫晨跑, 死都不放牽繩, 見怪不怪, 社恐改善中, 這狗到底要跑去哪, 今天也活下來了 (needs a defeat), hidden 巷口熟面孔, 越挫越勇.
- Player-facing text describes experiences; raw tags/growth only in the debug panel (+ train all +3, full growth, reset growth).
- Note: the untrained owner now stumbles/hangs back/tires by default, so walks feel slower than Sprint 02 until trained. Values are placeholders.
- `HumanFollower` only gained `speed_multiplier` / `hold_time` hooks; Codex art integration in that file was left uncommitted and untouched.
- Validation pacing pass (owner, 2026-09-17: "現在是驗證用 節奏不該這麼長"): run map scaled to 0.4 (1600×6160, same layout), dog 280 / owner 270 speed, search 1.0 s, extraction 1:00 / 2:00, human HP ~40% lower (shorter fights, win-rate bands unchanged), disengage 400; owner interruptions softened (stumble after 3 s for 0.35 s, breather 1.2 s, hesitation 0.6 s, heavy bag ×0.85); growth ~2× faster (traits full at 4, perk thresholds halved, run cap 8); training detection shortened (drag 2 s, linger 2 s, long walk 1500). Bigger/smaller maps are for later content. Core Loop Gate 01: PROCEED WITH CHANGES, tuning to revisit (`docs/07_qa/reports/CORE_LOOP_GATE_01_REVIEW.md`).

## Sprint 03.5 — GOALS

> Core Loop Gate 01 recorded 2026-09-17: PROCEED WITH CHANGES (owner: record now, tune later). Sprint 03.5 started.

| ID | Task | Status |
|---|---|---|
| P2G-001 | Desire model | REVIEW |
| P2G-002 | Desire tracker | REVIEW |
| P2G-003 | Primary selection | REVIEW |
| P2G-004 | Emergent triggers | REVIEW |
| P2G-005 | Persistent threads | REVIEW |
| P2G-006 | Completion/failure | REVIEW |
| P2G-007 | Goal chaining | REVIEW |
| P2G-008 | Context selection | REVIEW |
| P2G-009 | Strange Scent chain | REVIEW |
| P2G-010 | Squirrel desire | REVIEW |
| P2G-011 | Rival desire | REVIEW |
| P2G-012 | Bring-it-home | REVIEW |
| P2G-013 | New-dog discovery | REVIEW |
| P2G-014 | Old Master thread | REVIEW |
| P2G-015 | Collection discovery | REVIEW |
| P2G-016 | Desire UI | REVIEW |
| P2G-017 | World cues | REVIEW |
| P2G-018 | Save/load | REVIEW |
| P2G-019 | Debug tools | REVIEW |
| P2G-020 | QA readiness | REVIEW |

## Sprint 03.5 Engineering Notes (Claude)
- Validation: `tests/run_all.sh` (14 headless scene tests). `goals_core_test` = catalog, selection context, chains across walks, forks, emergent limit, growth-gated rematch, ignore/decay, save; `goals_world_test` = real scenes: walk-start desire + HUD + cues, Strange Scent chain over two walks, squirrel emergent chase, bring the clue home through the dog safe slot, rival reveal/meet/duel, discoveries, save/load, Home text, debug reset.
- Architecture (ADR-009): `GoalDirector` (scene node) observes existing signals (loot, extraction, engagements, proximity, scent cues, squirrel, places) and sends semantic events to `DesireTracker` (pure logic); persistent `GoalProgress` lives on `Game` (save `dog.goals`). Rewards go through `RunManager.grant_reward`. WALK/FIGHT/TRAIN rules are unchanged; no quest mode.
- Content (`data/goals`): 14 desires. Required chain: strange scent (park) → half tennis ball → alley scent trail → rival 阿黑 appears (hidden pair) → meet → duel → win, or lose → rematch thread. Other follow-ups/forks: squirrel escape → "squirrel again" on a later walk; Old Master fight → win / lose → avoid him, or rematch once the human has 2+ perks. Emergent triggers: squirrel spotted, tennis ball / clue found, provoking the Old Master (max 2 emergent at once).
- Selection: unresolved thread +100, priority, small run-RNG jitter, −30 if offered last walk; discovery desires only while something is undiscovered; growth-gated desires.
- Desires can be ignored: non-persistent ones fade at walk end; persistent ones sleep (DORMANT) and are listed at Home ("狗狗還掛念著").
- UI: dog-voiced list under the timer, popups for new/follow-up/resolved thoughts, nose arrow to the current target, ❗ on wanted pairs; Home shows threads and discovery counts. Debug panel shows active desires/flags, complete current, reset goals.
- Placeholder art: scent cue text, squirrel emoji, rival pair uses the fighter puppet. Codex desire icons (`assets/ui/desires`, `ui/desire`) were in progress and not committed by Claude.

## P-01 — DOG EYE CAMERA (prototype)
Isolated greybox experiment. Sprint 04 production is paused until the Camera Gate review.

| ID | Task | Status |
|---|---|---|
| CAM-001 | isolated 3D greybox | REVIEW |
| CAM-002 | dog/human/leash proxies | REVIEW |
| CAM-003 | A top-down baseline | REVIEW |
| CAM-004 | B dog-height chase | REVIEW |
| CAM-005 | C hybrid profiles | REVIEW |
| CAM-006 | collision/smoothing | REVIEW |
| CAM-007 | walk/sprint | REVIEW |
| CAM-008 | sniff/search | REVIEW |
| CAM-009 | squirrel chase | REVIEW |
| CAM-010 | seamless fight proxy | REVIEW |
| CAM-011 | dog movement/disengage | REVIEW |
| CAM-012 | mobile framing | REVIEW |
| CAM-013 | runtime tuning/debug | REVIEW |
| CAM-014 | A/B/C build | REVIEW |
| CAM-015 | blind QA | TODO |
| CAM-016 | Camera Gate decision | REVIEW |

## P-01 Engineering Notes (Claude)
- Build: `build/p01_camera/GoodHumanP01Camera.exe` (export preset "Windows P-01 Camera", feature tag `p01_camera` overrides the main scene). The game builds are unchanged; the QA release preset excludes `prototypes/*`.
- Code: `prototypes/dog_eye_camera/` only (3D primitives, no final art). Production scenes do not reference it. Added Input Map actions `sprint` (Shift; full joystick push also sprints) and `proto_cam_a/b/c` (1/2/3).
- Greybox: street with road markings, sidewalks, house fronts, blocks, path to a park entrance gate, trees, bushes, bench, searchable trash can, dog + owner + leash, opponent pair (外送員和阿黑), squirrel.
- Cameras (`ProtoCameraRig`: pivot + boom + smoothing + ray collision): A 3/4 top-down (fixed yaw, high/far); B dog-height chase (yaw follows the dog); C hybrid with framing contexts EXPLORE / SPRINT (farther, higher, wider) / SNIFF (lower, closer) / COMBAT_READABILITY (farther, higher, frames dog + fight). Contexts only change framing.
- Tested actions: walk, sprint and drag the owner, sniff the trash can, chase the squirrel up a tree, provoke the pair, fight in place, move around the fight, run 9 m away to disengage.
- Runtime tuning: on-screen buttons (A/B/C, height, distance, pitch, FOV ±, reset tuning, restart) and an overlay with variant, context, height, distance, pitch, FOV, dog speed, owner distance, opponent distance and disengage distance.
- Early engineering observations for the Camera Gate (not QA): in B, and in C's close framings, the leashed owner walks between the dog and the camera and blocks the view; the prototype fades the owner while it blocks (standard chase-cam fix). Close walls pull the camera in; below 1.8 m it rises so the dog stays in frame. A shows the most surroundings but the dog is small in portrait.
- `p01_camera_test`: all variants keep the dog visible while walking, C context switching, wall collision, owner fade, seamless fight + disengage, squirrel.
- CAM-015 (blind QA) and CAM-016 (Camera Gate decision) are for Codex/owner.
- Camera Gate (2026-09-17): owner prefers free switching between A and B in the game. Recorded with a 2D→3D impact estimate in `docs/07_qa/reports/P_01_CAMERA_GATE_REVIEW.md`; migration not started, ADR-010 stays PROPOSED until the owner approves. CAM-015 blind QA not run.

## P-02 — 3D VERTICAL SLICE
Owner approved the move to 3D (2026-09-17). Plan: `docs/03_sprints/P_02_3D_VERTICAL_SLICE.md`.

| ID | Task | Status |
|---|---|---|
| V3D-001 | Run systems accept 3D world objects | TODO |
| V3D-002 | Dog 3D controller (camera-relative) | TODO |
| V3D-003 | Owner 3D follower + leash | TODO |
| V3D-004 | 3D interaction (Interactable3D) | TODO |
| V3D-005 | 3D search + extraction points | TODO |
| V3D-006 | Street + park slice level | TODO |
| V3D-007 | Camera rig A/B switch | TODO |
| V3D-008 | Occlusion: collision, owner fade, building fade | TODO |
| V3D-009 | Seamless 3D fight (one pair) | TODO |
| V3D-010 | Home entry + run flow | TODO |
| V3D-011 | Scene test | TODO |
| V3D-012 | Build for owner playtest | TODO |
