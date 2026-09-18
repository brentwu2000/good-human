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
| V3D-001 | Run systems accept 3D world objects | REVIEW |
| V3D-002 | Dog 3D controller (camera-relative) | REVIEW |
| V3D-003 | Owner 3D follower + leash | REVIEW |
| V3D-004 | 3D interaction (Interactable3D) | REVIEW |
| V3D-005 | 3D search + extraction points | REVIEW |
| V3D-006 | Street + park slice level | REVIEW |
| V3D-007 | Camera rig A/B switch | REVIEW |
| V3D-008 | Occlusion: collision, owner fade, building fade | REVIEW |
| V3D-009 | Seamless 3D fight (one pair) | REVIEW |
| V3D-010 | Home entry + run flow | REVIEW |
| V3D-011 | Scene test | REVIEW |
| V3D-012 | Build for owner playtest | REVIEW |

## P-02 Engineering Notes (Claude)
- Play: Home → "🐕 3D 散步（試玩）" (the 2D walk stays next to it until the port is complete).
- Validation: `tests/run_all.sh` (16 scene tests). `run_3d_slice_test` = Home → 3D walk, camera-relative movement in both views, view toggle (key + button), owner fade, top-down building fade vs dog-view wall collision, 3D search through RunManager, fight in place + disengage + victory reward, extraction → result → Home stash.
- Reused unchanged: RunManager rules, loot tables, inventory, save, HUD, result, Home, CombatSimulation, growth stat bonuses. RunManager/RunHUD now accept a `dog_actor` of either dimension (V3D-001).
- New 3D code: `DogController3D`, `HumanFollower3D` (+ leash, growth hooks), `Interactable3D`/`InteractionArea3D`, `SearchPoint3D`, `ExtractionPoint3D`, `OpponentPair3D`, `FighterPuppet3D`, `CombatCoordinator3D` (1 m = 100 simulation units, disengage 9 m), `CameraRig3D`, `RunMap3D` + `run_map_3d_01.tscn`, `Greybox` primitives.
- Camera (owner after playing: dog view only, top-down removed): low chase camera with P-01 "B" framing; movement is relative to the camera; the camera eases behind the dog only while the stick points forward and the dog already faces away (sideways input no longer spins it); walls pull the camera in down to 1.2 m, closer walls fade instead of lifting it; the owner and foliage fade while blocking; fights pull back to frame both humans.
- Not in the slice yet: training/goal world observers, owner behaviour traits, squirrel/scents/places, rival and Old Master, debug combat buttons (the 2D debug panel's combat hooks don't target the 3D coordinator), full neighbourhood, 3D art, Android performance.

## P-03 — 3D CONTENT PORT
Owner approved 2026-09-17. Plan: `docs/03_sprints/P_03_3D_CONTENT_PORT.md`.

| ID | Task | Status |
|---|---|---|
| V3C-001 | Observers work in 2D and 3D | REVIEW |
| V3C-002 | Owner behaviour traits in 3D | REVIEW |
| V3C-003 | Training events in 3D | REVIEW |
| V3C-004 | 3D combat coordinator parity | REVIEW |
| V3C-005 | Dog desires + desire HUD in 3D | REVIEW |
| V3C-006 | Scent cues, squirrel, places in 3D | REVIEW |
| V3C-007 | Rival and Old Master in 3D | REVIEW |
| V3C-008 | Debug panel in 3D | REVIEW |
| V3C-009 | Scene tests | REVIEW |
| V3C-010 | Build for owner playtest | REVIEW |

## P-03 Engineering Notes (Claude)
- Validation: `tests/run_all.sh` (17 scene tests, all pass). `content_3d_test` = through the real 3D walk: shuffled ordinary pairs + Old Master + hidden rival, desire card and nose arrow, owner stumbling when dragged and hesitating near pairs, RUN/COURAGE training events, strange scent → half tennis ball → alley scent → 阿黑 revealed → duel desire, squirrel chase up a tree, place/dog discoveries, debug next-pair, extraction converts training, goal thread saved, next walk resumes the duel and beating 阿黑 resolves it.
- Approach: OwnerBehavior, TrainingObserver, GoalDirector and DesireHUD are dimension-agnostic (meters × `units_per_meter`: 80 on the 2D map, 1 in 3D); 3D actors expose the same methods (`planar_speed`, `play_growth_behavior`, `is_present`, `is_idle`, `set_hinted`, `get_pairs`, `Engagement3D`). No rule logic was duplicated.
- 3D level additions: 3 m alley between the west blocks (rival 阿黑 at its entrance, hidden until `rival_revealed`), the Old Master under the big tree, three ordinary pair spots shuffled per walk, park and alley scent cues, squirrel with three spawn points, place markers (street, alley, main path, park, big tree).
- Not yet: full neighbourhood layout (convenience store, back lane, gym area), retiring the 2D map and its tests, Android performance.

## Sprint 04 — DOG AGENCY
Camera Gate decided before install (ADR-010: dog-height camera only), so the camera-gated tasks P3-012/P3-013 are unblocked. Built in the 3D walk.

| ID | Task | Status |
|---|---|---|
| P3-001 | DogAgency coordinator/events | REVIEW |
| P3-002 | Bark world event | REVIEW |
| P3-003 | Bark attention reaction | REVIEW |
| P3-004 | Bark anti-spam | REVIEW |
| P3-005 | Leash tension model | REVIEW |
| P3-006 | Leash pull owner reaction | REVIEW |
| P3-007 | Bad-pull/stumble outcome | REVIEW |
| P3-008 | Pull-assisted disengage | REVIEW |
| P3-009 | Nearby interaction during combat | REVIEW |
| P3-010 | TrainingEvent integration | REVIEW |
| P3-011 | Opponent dog basic reactions | REVIEW |
| P3-012 | Camera-specific tuning | REVIEW |
| P3-013 | Mobile input/HUD integration | REVIEW |
| P3-014 | Debug overlay | REVIEW |
| P3-015 | Sprint 04 QA readiness | REVIEW |
| P3-016 | Core Experience Gate 02 | REVIEW |

## Sprint 04 Engineering Notes (Claude)
- Play: Home → "🐕 3D 散步（試玩）". Bark = Q or the "🐶 汪！" button above the interact button. Leash pull = run away from your fighting owner past the leash length.
- Validation: `tests/run_all.sh` (18 scene tests, all pass). `combat_sim_test` adds distract / pull / stumble hooks; `dog_agency_3d_test` = through the real 3D walk: bark outside a fight (their dog answers), bark from the flank (opponent looks away, COURAGE), resistance (second bark weaker, third ignored), bark from behind your owner (owner startled), facing away (unheard), pull away during a kick (saved, STRAIN), sideways pull (stumble, ENDURE), sustained pull (dragged out of the fight, RUN), sniffing a bench while the humans fight, opponent dog watching the player dog, debug overlay.
- Design (ADR-011, no QTE): `DogAgency` reads the dog's position, facing and movement. Bark works only near the fight (5 m), facing the opponent (75°) and from a useful side (≥50° away from the owner as seen from the opponent); each bark within 6 s halves the next; below 30% it's ignored. Leash pull: the fighting owner is yanked when the dog runs ≥0.3 m past the leash; ≥50% away from the opponent = reposition (and dodges a wind-up in progress), otherwise or two pulls within 1.6 s = stumble; staying 1.5 m past the leash for 1.2 s drags the owner out. CombatSimulation only gained situation hooks — the dog still never commands attacks.
- Opponent dogs: watch the player dog within 6 m, bark back and lunge on barks, sniff when close to an idle pair.
- Training: bark distraction (COURAGE), pull save (STRAIN), drag out (RUN), bad pull (ENDURE), with cooldowns; routed through TrainingObserver.
- HUD fix: the "主人記住了" experience card could grow to half the screen (autowrap) and sat under the desire card; it now keeps its size and sits below the desire card.
- Hidden numbers only in the debug panel ("Agency:" line). All tuning values are placeholders for playtesting.
- P3-016 Core Experience Gate 02 reviewed 2026-09-18: **REWORK CORE EXPERIENCE** (`docs/07_qa/reports/CORE_EXPERIENCE_GATE_02_REVIEW.md`). Owner: "沒有明顯" — the identity does not come across, and all four pillars asked about (TRAIN, DOG AGENCY, GOALS, WALK/FIGHT) were reported weak. Sprint 05 engineering is paused at P4-010; nothing is reverted.
- Rework, step 1 (owner: "打架很沒有感覺"). What a landed punch actually was: the body slid back a fixed 0.25 m over 0.05 s, a small pulse, a text shout — identical whether it was a jab or a ×1.4 opening kick. No hitstop, no camera shake, and **the project contains no audio at all** (no sound files, no `AudioStreamPlayer` anywhere in game code). Added, presentation only, with the simulation still the sole authority: hitstop on a landed hit (`HITSTOP_LIGHT` 0.06 s → `HITSTOP_HEAVY` 0.16 s, scaled by damage, longest on the dog-made "破綻" opening), trauma-based camera shake on `CameraRig3D` (`add_trauma`, offset is trauma², applied after placement so collision and framing are untouched), and knockback/recoil scaled by damage so a jab and a kick no longer look the same. `run_3d_slice_test` checks the grading, that the pause is always short, and — the important one — that the simulation neither advances nor deals damage while it is held.
- Audio is the open half of this and needs an ownership call: the game has never had any sound, which on its own explains much of "no feel". Placeholder audio would be mine under the placeholder-art rule; final audio belongs to the art pipeline. Not started.
- Owner feedback (2026-09-18): "拉繩子跟吠叫好像完全沒有正面效益，只有負面效果". Causes found: continuous pulling alternated a good pull with a forced stumble (1.0 s cooldown vs 1.6 s repeat rule); dogs naturally stand behind their owner, which was the startle zone; a successful distraction only delayed the opponent, so no benefit was visible; sideways pulls counted as bad. Changes: a distracted opponent is exposed — the owner attacks at once and the hit does ×1.6 ("破綻"); bark range 6 m, facing 110°, "behind the owner" only within 25° and startle only within 1.5 m of the owner, resistance window 4 s; pulls only stumble when dragging the owner towards the opponent, sideways/away repositions, no repeat penalty; every outcome shows a HUD toast (✦ positive / ✘ negative). Measured (200 fights each, bark every 2.5 s): Jogger 175→200, Delivery Worker 156→200, Gym Regular 163→200 wins; Old Master still wins (0–5 of 200). Positive effect may now be too strong — tune after playtest.
- Owner feedback (2026-09-18): "轉視角有點不順". Cause: the camera followed only inside two hard 50° gates (stick direction, dog vs camera heading), so it stalled after bigger turns and then started abruptly. Now it eases behind the dog continuously, weighted by forward stick share² × speed (sideways/backwards → 0, so no spinning), and players can turn it by dragging on the right half of the screen, right mouse drag, or ←/→ (`camera_turn_left/right`); auto-follow waits 1.5 s after a manual turn. `run_3d_slice_test` checks no yaw jumps and manual turning.
- Camera/art boundary (2026-09-18): the art commit `fb186ca` tagged every starter-kit piece, buildings included, as a `FADE_GROUP` occluder. That marker means "the camera looks through this", so a building no longer pulled the camera in: at the test spot the camera's target sits at z≈6.07 inside the building that spans z 5.5–11.5, i.e. it settles inside the wall and watches the dog through it (`run_3d_slice_test`: "wall pulls camera in, dog still visible" failed). Buildings are now solid again — the rig pulls in and only fades when pulling in would come closer than `collision_min_distance`. The kit's thin props (bush, bench, bin, gate posts, bus-stop posts, tree) keep the fade marker, which is right for them, and no geometry, colour or detail of Codex's kit was changed.
- Owner feedback (2026-09-18): "轉向的部分還需要調整，實測搖桿拉左上，會往左邊轉，但是轉到一個角度後就不會轉了". Cause: the previous fix froze the stick's control frame at the moment it was pushed, so a held diagonal turned the dog once (45°) and then ran straight while the camera settled behind it — the turn visibly stopped. Now the stick still answers the view exactly as it was pushed (so pointing somewhere sends the dog there at once), but while held its frame follows the turning view at `control_follow_rate` (1.2/s, slower than the camera's 2.4/s follow); the two rates settle into a steady arc instead of either straightening out or spinning. Measured: holding up-left turns ~41°/s then ~36°/s (a circle in ~10 s); a full sideways push turns harder, ~42°/s then ~88°/s. `run_3d_slice_test` now checks that a held direction keeps turning across successive windows, that a diagonal curves more gently than a full sideways push, and that "up" afterwards follows the new view.
- Balance pass (2026-09-18) after the note above that the positive effect might be too strong. Measured over 200 seeds per opponent it was worse than "too strong": any steady bark rhythm won 198-200/200, and a player who pulled on every wind-up won 200/200 against every opponent including the Old Master, while pulling blindly *lost* fights (Gym 161 → 78). Causes: a bark deleted the opponent's committed attack and handed the owner a free turn, so against a slow heavy fighter it removed most of their few hits; a pull granted a guaranteed dodge at no cost; and a pull with nothing to dodge still shoved the owner out of their own range. Changes: an attack can only be called off in the first half of its wind-up (`COMMIT_SHARE`), a bark never advances the owner's turn — the opening is a damage window instead (`OPENING_DAMAGE` 1.6 → 1.4, `OPENING_GRACE` 1.2 s), opponents habituate over a fight (`BARK_HABITUATION` 0.75 per bark heard, resistance window 4 → 8 s, distraction 0.9 → 0.7 s), a pull that saves costs the owner 1.5 s of their own tempo and its cooldown is 1 → 3 s, and a pull with nothing to dodge now does nothing at all instead of losing ground. Measured after: baseline 167/163/161 of 200 (jogger/delivery/gym); spamming or mistiming ≈ baseline; well-paced barking 193/191/186; pulling on every wind-up 198/200/193; both together 198/200/199 — a perfect player's ceiling, not a default. The Old Master stays 0/200 in every mode. `combat_sim_test` now models the real resistance curve and checks paced > spammed and that good barking does not decide every fight.
- Owner feedback (2026-09-18): "轉方向的時候視角沒有跟著轉，例如我要往右邊，拉了以後鏡頭還是往前". The previous fix deliberately ignored sideways input. Now the camera follows the dog in any direction (weighted by speed, gentler when running back towards the camera), and the stick's control frame is latched to the camera yaw when pushed (re-latched on release or when the stick is steered more than 45°), so the turning view doesn't curve the dog's path. `run_3d_slice_test`: pushing right runs straight right and the view turns right; up after that follows the new view.

## Sprint 05 — GREED / TERRITORY
Installed from Update 007 (2026-09-18). The update gates engineering behind Core Experience Gate 02.

> Owner decision (2026-09-18): start Sprint 05 engineering now ("動工"), before Core Experience Gate 02.
>
> **PAUSED 2026-09-18 at P4-010**: Core Experience Gate 02 came back REWORK CORE EXPERIENCE. P4-001..P4-010 stay REVIEW (unverified, not known-bad, and additive); P4-011..P4-017 are not started. Do not resume until the rework direction is agreed with the owner.

| ID | Task | Status |
|---|---|---|
| P4-001 | Run value/risk | REVIEW |
| P4-002 | SAFE/UNBANKED presentation | REVIEW |
| P4-003 | Post-extraction temptation hooks | REVIEW |
| P4-004 | Temptation data | REVIEW |
| P4-005 | Territory state/data | REVIEW |
| P4-006 | Banyan landmark | REVIEW |
| P4-007 | Mark Territory | REVIEW |
| P4-008 | Resident rival | REVIEW |
| P4-009 | Claim progression | REVIEW |
| P4-010 | Extraction resolution | REVIEW |
| P4-011 | Persistence | TODO |
| P4-012 | Territory reward | TODO |
| P4-013 | GOALS integration | TODO |
| P4-014 | TRAIN/DOG AGENCY compatibility | TODO |
| P4-015 | Debug/telemetry | TODO |
| P4-016 | Blind QA | TODO |
| P4-017 | Gate | TODO |

## Sprint 05 Engineering Notes (Claude)
- Started on the owner's explicit instruction (2026-09-18) before Core Experience Gate 02 was reviewed; that gate stays TODO.
- Scope reminders from the update: reuse the Run World, seamless combat, GOALS, TRAIN and DOG AGENCY. No global territory simulation, passive-income empire, dozens of capture points, PvP, daily decay or generic map capture. One territory (the Big Banyan Tree).
- ADR-012 (territory is relationship, not empire) and ADR-013 (greed is voluntary) are installed in `docs/99_notes`.
- P4-001: `RunValue` (`core/run/run_value.gd`) reads the two run inventories the player is already deciding between — the dog's bag is SAFE, the owner's is UNBANKED — and reports value, slots, `at_risk_share()` and `is_bag_full()`. PERMANENT (the Home stash) is deliberately not in it: a walk never touches it. RunManager emits `value_changed` whenever the split actually moves, remembers when going home first became possible and what was at stake then (`first_extraction_time`, `value_at_first_extraction`, `is_past_first_extraction()`), and writes all of it onto the RunResult along with `lost_value` and `seconds_after_extraction()` — the evidence Gate 01 needs for "did the player choose to stay". No loss rules changed: the dog's bag still comes home, the owner's is still lost. `run_core_test` covers the split, the risk share, the update signal, the first-extraction snapshot and a defeat after staying on.
- P4-002: the bag button used to add both bags into one number, which hid the only distinction the player is deciding about. Its headline is now what the owner carries — what a defeat takes — and whatever the dog carries is marked `🔒$N` as already safe, so moving an item into a dog slot visibly moves value from one to the other. Under it, one quiet `RiskLabel` speaks only when there is something to say (RUN_TENSION_PRESENTATION, no extraction-shooter readout): silent while the walk is worth little, "主人身上帶著 $N" past `risk_notable_value` (60), and once going home is possible the greed line "現在回家，$N 就安全了"; a full bag adds "背包滿了", and past `risk_heavy_value` (160) the line warms in colour. Unlocking the first extraction also says "現在回家，主人身上這些東西就安全了" once, and only if anything is at risk. Thresholds live in `game_balance.tres`. `golden_path_test` checks all of it through the real HUD.
- P4-002 wording is design's (D5-05, `docs/06_art/SPRINT_05_RISK_HUD_SPEC.md`). Codex selected the phrasing while this was in flight and rewired the HUD to their `_update_risk_badge`, leaving my near-identical function orphaned; I deleted mine, kept theirs, and dropped my extra "現在回家…" toast because the spec says the HUD states the consequence but never tells the player to leave. `golden_path_test` now asserts the meaning (the line names going home and the amount), not the phrasing, so design can keep iterating without breaking the test.
- P4-003/P4-004: `TemptationData` (5 templates in `data/greed/temptations`) plus `TemptationDirector`, a scene node on both maps. A temptation is deliberately not a Desire: a Desire is what the dog wants, a temptation is what the world happens to be offering at the moment going home became possible. The director never spawns content, changes rules or blocks extraction — it asks whether a thing the template names is actually out there (`Needs`: unsniffed cue, idle pair, unsearched point with bag room, squirrel, territory), then says so in the dog's voice. Nothing is guaranteed (ADR-013): no offer before the first extraction unlocks, none for `FIRST_OFFER_DELAY` (6 s) after it so the choice lands first, a 55% roll on the run RNG per attempt, `BETWEEN_OFFERS` (30 s) between attempts, per-template cooldown/expiry, and a minimum unbanked value so an empty-handed walk is never tempted. Ignoring an offer just lets it lapse. `banyan_opportunity` needs TERRITORY, which nothing provides until P4-005, so it is inert by design. `greed_core_test` covers the templates and every rule; the measured offer rate over 20 seeded walks is deliberately neither 0 nor 20.
- P4-005: `TerritoryData` (authoring, `data/territory/banyan.tres`) and `TerritoryProgress` (persistent, saved under `dog.territories`). States are a relationship, not a capture meter (ADR-012): UNKNOWN → DISCOVERED → CONTESTED → CLAIMING → OWNED, and `advance_to` only ever moves forward, so a bad walk can never make the dog forget somewhere. `add_claim` is the only route to OWNED and takes `claim_target` (3) relevant successful extractions, so a place is earned by walks that came home rather than by standing next to a tree. No passive income, no upkeep, no decay. `deserialize` rejects impossible states and negative progress, so a hand-edited or older save cannot invent ownership.
- P4-006: `TerritoryPoint3D` replaces the banyan that the art pass added as scenery. It owns no rules — it reads `TerritoryProgress` to pick which of Codex's landmark variants to build (D5-01/D5-02/D5-07) and turns two things that already happen on a walk into the first two steps of the loop: coming within 6 m finds the place, and standing within 3 m for 1.5 s reads the scents at its roots and learns another dog lives there. Walking past at a distance does nothing, and neither step can fire twice. Marking, challenging and rewards are deliberately not here: a landmark should not be able to change a walk on its own. `territory_core_test` covers the data and state rules including bad save data; `territory_world_test` drives the real 3D walk and checks the scent traces on the landmark actually change with the state.
- P4-007: the banyan is now an `Interactable3D` ("💧 做記號"), offered only somewhere the dog has understood (CONTESTED or further), once per walk, and never once the place is already its own. Marking costs nothing, risks nothing and grants nothing by itself — it sets `marked_this_walk`, says the dog's words and plays Codex's `play_recognize()` + `play_mark()` (D5-03). Claim progress is deliberately not touched here: a walk counts for a place only if it gets home (P4-009/P4-010), which is what keeps ownership something you take home rather than something you stand next to.
- P4-008: D5-06 names the existing black-dog/student pair (`enc_rival`, 阿黑 + 學生) as the resident, but that pair was already placed in the alley for the Sprint 03.5 scent chain, and the same dog must not be in two places at once. Resolved with a new `retired_by_flag` on `OpponentPair3D` (symmetric to `required_flag`): the alley meeting is retired by `rival_beaten`, and the new `banyan_resident` spot requires it. So the alley is where the dog meets 阿黑, and once that is settled he has gone home to his tree, where the territory story continues — the Sprint 03.5 chain leads into Sprint 05 instead of competing with it. Note for design/owner: the Old Master still stands at the same big tree (`pair_big_tree`, ~7 m away). Both are reachable and interaction targeting is unambiguous, but two fixed pairs around one landmark is worth a look during playtest.
- P4-009/P4-010: marks travel with the walk and are settled on the way home, following the shape training already uses — `RunManager.record_territory_mark` collects them, `RunResult.marked_territories` carries them, and `Game._resolve_territories` applies them. A place moves forward only on a successful extraction: a defeated or failed walk adds nothing and, just as importantly, takes nothing away — territory never decays (ADR-012). Getting home without marking does nothing either, so ownership needs both halves. The third marked walk home sets OWNED once, writes the territory's `owned_flag` into `goal_progress` so other content can read it, and reports itself on the RunResult (`territory_claims`, `territories_claimed`) for the result screen. An owned place cannot be claimed again and its progress stops counting. `territory_core_test` runs the whole ladder including a defeat in the middle; `territory_world_test` marks and walks home through the real 3D walk and the real result screen.

## P-02 COMBAT EXPERIENCE (Update 006 Patch 01)
Installed 2026-09-18, after Core Experience Gate 02 returned REWORK and the owner named combat ("打架很沒有感覺"). The patch's own priority line — evaluate this before committing to Sprint 05 engineering — matches the pause already in place.

Key experiment (ADR-014, PROPOSED/PROTOTYPE): during seamless combat the dog stays the movement anchor while the player's human becomes the visual focus; the camera tightens for tension with soft composition, never a lock-on, and the dog stays controllable in the Run World.

| ID | Task | Status |
|---|---|---|
| D4/P02-001 | Follow Dog + Focus Owner camera | REVIEW |
| D4/P02-002 | Soft focus / dead-zone | REVIEW |
| D4/P02-003 | Tension/Snap transition | REVIEW |
| D4/P02-004 | Active combat framing | REVIEW |
| D4/P02-005 | Crisis framing | REVIEW |
| D4/P02-006 | Victory release | REVIEW |
| D4/P02-007 | Defeat owner-down beat | REVIEW |
| D4/P02-008 | Owner condition feedback | TODO |
| D4/P02-009 | Dog instinct feedback | TODO |
| D4/P02-010 | Owner↔dog acknowledgement | TODO |
| D4/P02-011 | Debug/tuning | TODO |
| D4/P02-012 | Blind comparison QA | TODO |

## P-02 Combat Experience Engineering Notes (Claude)
- D4/P02-001/002: the camera's two jobs now come apart during a fight. The boom still hangs behind the dog (FollowAnchor, so steering and the turning rules are untouched), but what it looks at is composed separately (FocusAnchor): the owner, pulled 30% towards the opponent so the fight frames as a pair. The aim is soft — it takes `focus_weight` (0.9) of only the part of the offset outside `focus_dead_zone` (0.35 m) and eases there at `focus_rate`, so it is composition rather than a lock-on and a snap is interpolation. Replaced the old rule that lerped the whole focus point halfway to the midpoint of the two humans.
- Two things the tests forced out that are worth keeping in mind. First, the dead-zone was initially 0.9 m at 0.65 weight, which made the focus shift nearly invisible at realistic owner distances — the dead-zone is for swallowing shuffling, not for suppressing the feature. Second, when the dog is standing on top of its owner, looking at one *is* looking at the other, so the composition correctly does nothing; the framing only means something once the dog roams, which is exactly the situation ADR-014 is about.
- D4/P02-003..007: the five framing contexts (EXPLORE / TENSION / ACTIVE / CRISIS / RELEASE) in `CONTEXT_FRAMING`, each a destination the camera eases towards — nothing cuts and nothing changes a rule. The coordinator now reports the facts (`blows_landed`, `owner_condition()`, `is_owner_down()`, `release_left`) and the camera alone decides the framing. TENSION holds before the first blow, ACTIVE tightens once they land, CRISIS tightens further below 34% owner health and also covers the owner-down beat so the camera stays with them while the dog can still move, and RELEASE holds 1.4 s after a fight resolves before blending back to walking.
- Three real mistakes the tests forced out, all worth remembering. (1) I applied the slow push-in rate to the camera's *position* follow as well as its framing; the rig fell 4.4 m behind the dog. A deliberate push-in is camera language — how fast the rig follows the thing the player is steering must never be slowed. (2) Smoothing the aim as a world-space point is unstable: when the camera travels far it flies past the point and the aim goes wild (measured 64° off the dog). The composition is now stored as an offset from the anchor instead. (3) Tightening the shot pushed the dog off screen, exactly the QA failure mode — `_keep_dog_in_frame` now swings the aim back so the dog never leaves a share of the half-FOV, measured against the dog itself rather than the smoothed pivot, which sits above it and moves when a wall pulls the camera in.
- Owner playtest (2026-09-18) of the first contexts pass: "打鬥畫面不如預期，推進，看起來比較有戰鬥帶入感的，現在感覺跟平常畫面沒差別". The framing was wrong by my own measure: I sized the combat contexts against the *old* 7.5 m pull-back instead of against the walking shot, so ACTIVE sat at 4.6 m / 62° against EXPLORE's 2.8 m / 70° — it backed off 1.8 m while narrowing 8°, and the two cancelled. A fight now genuinely pushes in: TENSION 2.35 m / 62°, ACTIVE 2.00 m / 54°, CRISIS 1.75 m / 46°, every one of them closer and narrower than walking, with `combat_spread` giving ground only for a dog that has run off rather than framing every fight for that case. `run_3d_slice_test` now asserts the property itself — each combat context must be closer and narrower than EXPLORE — so this cannot regress quietly.
- Two test-side mistakes worth remembering from that pass: comparing the aim against the dog's feet but the owner's chest made the dog look closer to the aim for free; and the owner-focus promise belongs to ACTIVE (focus 0.92), not TENSION (0.50, where the owner is deliberately only half the subject), so a test that holds the fight before the first blow is asserting the wrong thing.
- Owner decision (2026-09-18): "後續只針對3D的版本，2D版本先不用". Home's main "出去散步" button now goes to the 3D walk; the 2D map is demoted to a small "舊的 2D 版本（已停止開發）" button. It is kept, not deleted, because `golden_path_test`, `run_core_test`, `combat_world_test`, `goals_world_test` and `training_world_test` still cover the shared rules through it. Note this was a live trap: the big, plainly-named first button led to the old 2D game, which has none of the 3D art, camera, hitstop or territory work.
- Still to do here: owner condition read through behaviour rather than an HP bar (D4/P02-008), dog instinct and owner↔dog acknowledgement (D4/P02-009/010), debug (011) and the blind comparison (012). Adoption depends on the P-02 playtest and the blind comparison (D4/P02-012, `docs/07_qa/P_02_COMBAT_CAMERA_QA.md`); ADR-014 stays PROPOSED until then.
- The Gate 02 feel pass already landed (hitstop, camera shake, damage-scaled impact) and is complementary: it is the moment of contact, this patch is the framing and the emotional curve around it.
- Audio is still absent project-wide and still needs an ownership call; `COMBAT_EMOTIONAL_FEEDBACK` assumes an audio duck on SNAP, which cannot exist yet.

## P-03 STREET BRAWL (Update 006 Patch 02)
Installed 2026-09-18, after the owner played the P-02 framing and said it looked no different from an ordinary walk. The storyboard (`docs/06_art/dog_agency/P03_STREET_BRAWL_STORYBOARD.png`) answers why: the intended Combat Snap **drops the camera into the dog's eyes (first person)**, not a third-person shot that looks at the owner. "Explore as the dog. Fight through the dog's eyes."

P-03 is now the Sprint 04 experience blocker. Sprint 05 engineering stays gated; Sprint 05 design may continue. ADR-015 (Dog POV) is the primary candidate; ADR-014 / P-02 (owner-focused third person, already built) is retained as the comparison baseline.

| ID | Task | Status |
|---|---|---|
| P03-E01 | Physical human combat state/motion | REVIEW |
| P03-E02 | Punch/Kick/Block/Dodge + reactions/down | TODO |
| P03-E03 | Combat spacing, approach/circle/reset | TODO |
| P03-E04 | Dog POV combat camera | TODO |
| P03-E05 | Dynamic CombatCenter + soft auto framing | TODO |
| P03-E06 | Third-person → POV → third-person | TODO |
| P03-E07 | Bark attention reaction visible in-world | TODO |
| P03-E08 | Leash Pull visible result | TODO |
| P03-E09 | Combat Atmosphere Director hooks | TODO |
| P03-E10 | Hide combat log, keep debug panel | TODO |
| P03-E11 | Victory/defeat resolution beat | TODO |
| P03-E12 | Capture build/video for QA | TODO |

## P-03 Engineering Notes (Claude)
- Execution order is set by the patch and is not mine to reorder: physical combat motion first, then the Dog POV camera, then visible Bark/Pull results, then atmosphere, then resolution. The reason is stated plainly in `HUMAN_COMBAT_MOTION.md` and matches what I found during the Gate 02 feel pass — "damage events without physical motion cannot validate combat camera, dog intervention or atmosphere". Today two humans stand still and exchange HP with a 0.25 m slide; no camera can rescue that.
- Exit gate: the team must be able to watch an encounter **with the combat text hidden** and still read the fight, the dog's intervention and the escalation. Text-only combat is explicitly unacceptable.
- P03-E01: `CombatMotion3D` holds the eleven states the spec asks for and is read from the simulation every frame; `FighterPuppet3D.play_motion()` gives each one a body — squared-up breathing, weight forward while closing, side-to-side footwork while working for an angle, and an off-balance lean during RECOVER, which is the moment a bark is worth most. Reactions hold for their own beat (HIT_REACT 0.28 s, STAGGER 0.45 s) so a hit reads as a hit instead of flickering back to neutral.
- Circling without touching the rules: the simulation stays one-dimensional and keeps owning distance and every outcome, while the *line* the two of them stand on turns slowly in the world (`ORBIT_SPEED`), and only while neither is committed to anything. Two people circling each other is presentation; who can reach whom is not. This also means the balance measured in the Gate 02 pass is untouched.
- `play_evade()` and `play_miss()` were text-only, which the patch names as unacceptable — a dodge is now a body moving out of the way and a miss overreaches. Also fixed `set_guard`, which assigned `position.z` to itself when guarding ended, so a guard never actually dropped.
- `combat_motion_3d_test` asserts the requirement as stated: over a real fight both humans travel more than half a metre, the fight passes through several different body states, and attacks are telegraphed — the cue the dog's intervention depends on.
- The atmosphere director assumes audio (ducking ambience, impact, dog breathing, low-frequency pulse before the first strike). The project still has none, and this now blocks P03-E09.
