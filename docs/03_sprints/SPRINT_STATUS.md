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
| D4/P02-008 | Owner condition feedback | REVIEW |
| D4/P02-009 | Dog instinct feedback | REVIEW |
| D4/P02-010 | Owner↔dog acknowledgement | REVIEW |
| D4/P02-011 | Debug/tuning | REVIEW |
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
- D4/P02-008 (COMBAT_EMOTIONAL_FEEDBACK): the owner's condition reads in three stages in the body, never a bar. HEALTHY: steady. HURT (60 % health and below): breathing hard, the guard pulled in tight, heavier feet, and a deeper, slower recovery after an action. CRITICAL (30 % and below): the guard sags with fatigue, they sway on their feet, and every couple of seconds they falter for a moment, head dropping (hesitation). DOWN is the existing owner-down beat. It builds on the P04-11 stoop; that first version dropped the guard as soon as they were hurt, where the spec wants it guarded when hurt and sagging only when critical.
- D4/P02-009: `DogInstinct` gives the dog its own read of danger to its owner, in its own body and nowhere else (it changes no rule). THREAT, while a heavy blow (hook or kick) winds up at the owner: head down and forward and a "grr"; in the dog's eyes the ears prick up and the muzzle lifts in a snarl. WORRY, while the owner is critical or down: head low and a "嗚…"; ears laid back and down, muzzle lowered. The captions stand in for sound while the project has no audio, like the bark's. The growl lands on the same telegraph a leash pull answers.
- D4/P02-011: the debug overlay shows the camera context and blend, which combat camera is in use, the owner's condition stage and health, and the dog's instinct. The debug panel gains "主人重傷（25%）" (owner to 25 % mid-fight, to tune HURT/CRITICAL and the CRISIS framing) and a combat-camera switch between Dog POV (ADR-015) and the P-02 owner-focused third person (ADR-014).
- D4/P02-012 is Codex's blind comparison. Two builds for it: `build/windows_qa/GoodHuman.exe` (Dog POV) and `build/windows_qa_p02/GoodHuman.exe` (new export preset "Windows Desktop QA P-02", feature `p02_camera`: the fight stays in the owner-focused third person). Both are release builds with no debug panel and fight text off. Brief: `docs/07_qa/P_02_COMBAT_CAMERA_QA.md`.
- Test: `combat_feedback_test` (31 checks) covers the three condition stages, the dog's THREAT and WORRY in both views and back to calm, the P-02 camera staying in third person while Dog POV drops into the dog's eyes, and the debug overlay and buttons.

## P-03 STREET BRAWL (Update 006 Patch 02)
Installed 2026-09-18, after the owner played the P-02 framing and said it looked no different from an ordinary walk. The storyboard (`docs/06_art/dog_agency/P03_STREET_BRAWL_STORYBOARD.png`) answers why: the intended Combat Snap **drops the camera into the dog's eyes (first person)**, not a third-person shot that looks at the owner. "Explore as the dog. Fight through the dog's eyes."

P-03 is now the Sprint 04 experience blocker. Sprint 05 engineering stays gated; Sprint 05 design may continue. ADR-015 (Dog POV) is the primary candidate; ADR-014 / P-02 (owner-focused third person, already built) is retained as the comparison baseline.

| ID | Task | Status |
|---|---|---|
| P03-E01 | Physical human combat state/motion | REVIEW |
| P03-E02 | Punch/Kick/Block/Dodge + reactions/down | REVIEW |
| P03-E03 | Combat spacing, approach/circle/reset | REVIEW |
| P03-E04 | Dog POV combat camera | REVIEW |
| P03-E05 | Dynamic CombatCenter + soft auto framing | REVIEW |
| P03-E06 | Third-person → POV → third-person | REVIEW |
| P03-E07 | Bark attention reaction visible in-world | REVIEW |
| P03-E08 | Leash Pull visible result | REVIEW |
| P03-E09 | Combat Atmosphere Director hooks | TODO |
| P03-E10 | Hide combat log, keep debug panel | REVIEW |
| P03-E11 | Victory/defeat resolution beat | REVIEW |
| P03-E12 | Capture build/video for QA | REVIEW |

## P-03 Engineering Notes (Claude)
- Execution order is set by the patch and is not mine to reorder: physical combat motion first, then the Dog POV camera, then visible Bark/Pull results, then atmosphere, then resolution. The reason is stated plainly in `HUMAN_COMBAT_MOTION.md` and matches what I found during the Gate 02 feel pass — "damage events without physical motion cannot validate combat camera, dog intervention or atmosphere". Today two humans stand still and exchange HP with a 0.25 m slide; no camera can rescue that.
- Exit gate: the team must be able to watch an encounter **with the combat text hidden** and still read the fight, the dog's intervention and the escalation. Text-only combat is explicitly unacceptable.
- P03-E01: `CombatMotion3D` holds the eleven states the spec asks for and is read from the simulation every frame; `FighterPuppet3D.play_motion()` gives each one a body — squared-up breathing, weight forward while closing, side-to-side footwork while working for an angle, and an off-balance lean during RECOVER, which is the moment a bark is worth most. Reactions hold for their own beat (HIT_REACT 0.28 s, STAGGER 0.45 s) so a hit reads as a hit instead of flickering back to neutral.
- Circling without touching the rules: the simulation stays one-dimensional and keeps owning distance and every outcome, while the *line* the two of them stand on turns slowly in the world (`ORBIT_SPEED`), and only while neither is committed to anything. Two people circling each other is presentation; who can reach whom is not. This also means the balance measured in the Gate 02 pass is untouched.
- `play_evade()` and `play_miss()` were text-only, which the patch names as unacceptable — a dodge is now a body moving out of the way and a miss overreaches. Also fixed `set_guard`, which assigned `position.z` to itself when guarding ended, so a guard never actually dropped.
- `combat_motion_3d_test` asserts the requirement as stated: over a real fight both humans travel more than half a metre, the fight passes through several different body states, and attacks are telegraphed — the cue the dog's intervention depends on.
- P03-E04/E05/E06 (owner after E01: "有好一點，但是視角還是需要處理，更有帶入戰鬥感"): once blows land the camera moves into the dog's head — `pov` blends the rig from the chase position to `DogController3D.eye_position()` at its own snap rate, the dog's own mesh is hidden above 0.85 so it does not fill the lens, and RELEASE blends back out. Nothing cuts. The aim tracks `combat_center()` — a point between the two humans biased towards the owner (`combat_center_owner_bias` 0.62, exposed for tuning as the spec asks) — with a dead zone so it does not micro-correct and a capped turn rate so first person stays readable rather than nauseating. `_keep_dog_in_frame` is skipped in POV: inside the dog's head there is no dog to keep in frame.
- Consequence worth stating plainly: adopting ADR-015 means ADR-014's owner-focused third person is **no longer the combat shot**. It survives only as the build-up (TENSION) and the exhale (RELEASE), and as the comparison baseline the patch asks us to keep. The P-02 world assertions in `run_3d_slice_test` were moved to TENSION accordingly, because in ACTIVE they no longer described any moment that exists.
- One bug worth remembering: `pov` was read from the blended `current` framing, which never lerped it because "pov" was missing from the per-key list — so the snap silently never happened and the tests passed for the wrong reason (the dog was "still on screen" because the camera had never left). It now reads the context's own value, since `pov` already has its own rate and must not be smoothed twice.
- Owner feedback (2026-09-19): "第一人稱沒錯，但是玩家的方向沒有跟著攝影機，導致不自覺的向後退". Cause: the stick was still read against the boom yaw. In first person the boom hangs behind the player's eyes and means nothing, so pushing forward walked somewhere other than into the screen — and because the camera was turned towards the fight, "forward" pointed partly away from it. Added `view_yaw()`: the direction the player is actually looking along, which is the boom out of POV and the camera's own aim inside it, and moved the control-frame update to the end of `_update` so it reads this frame's aim rather than last frame's. `combat_motion_3d_test` now holds a real stick press in first person and checks the dog walks into the screen.
- That test also caught `combat_center()` adding head height twice, so the POV camera was watching a point ~2.2 m up — above both fighters' heads. Fixed, and the test now pins the watched point to head height.
- P03-E07/E08: the simulation has always emitted `distracted`, `pulled` and `stumbled`, and the 3D coordinator handled **none** of them — so barking and pulling produced no body motion at all, only a shout and a HUD toast. That is exactly the "text-only combat" the patch rules unacceptable, and it mattered far more once the camera moved inside the dog's head, where a toast is the only thing left. Now a bark turns the opponent's head and body towards the dog and opens their guard for as long as they are looking away (`play_distracted`, and `face_towards` yields to it); a pull that catches a wind-up yanks the owner bodily backwards; a bad pull throws them sideways off balance, deliberately uglier so a mistake looks like a mistake.
- `pull()` was emitting the requested distance whether or not anything happened, so presentation could not tell a real save from a wasted tug. It now reports how far the fighter actually moved — 0 when they simply braced against the leash.
- Test-timing lessons from this pass, both of which made checks pass alone and fail in the suite: a yank is a ~0.09 s tween, so sample the peak across the movement instead of one frame of it; and a STAGGER hold is shorter than the sampling window, so record that it happened *while* it happens rather than asking once it is over.
- P03-E10: the combat log is off in normal play and back on from the debug panel ("戰鬥文字"). The cut is between the puppet's *automatic* notes about its own mechanics (skill name, 擋住／閃過／落空／被打斷／什麼？！), which are the log, and deliberate dialogue from the coordinator and the map (你家的狗在叫什麼？！／好狗狗。), which is the characters talking and stays. This is the exit gate made real: with it off, the only things left are the bodies, so E01/E07/E08 have to carry the fight.
- P03-E11: winning ends with the owner turning round to the dog and crouching to it (storyboard 09/10), not with a number — "好狗狗。" with the reward in parentheses, said sparingly as `COMBAT_EMOTIONAL_FEEDBACK` asks. Losing already left the owner down in the world with the dog still able to reach them; the camera now holds on them through CRISIS and RELEASE rather than cutting away.
- P03-E02/E03 (owner: "鏡頭氛圍有了，戰鬥本身還是要調整"). Two things were wrong at the root. A punch telegraphed for 0.25 s — unreadable on a phone, and since the dog may only intervene in the first half of a wind-up, it had 0.125 s to act; `HUMAN_COMBAT_MOTION` says plainly that if the player cannot anticipate an attack, the intervention design fails. And `active_time` was unused for attacks: damage resolved the instant the wind-up ended, so the strike animation played *after* the outcome was already decided and there was no contact window at all. Now attacks pass through a real ACTIVE contact phase (damage still lands as the wind-up ends, so pull protection, opening windows and the cancel share all keep their meaning), punch telegraphs 0.45 s and kick 0.8 s.
- Lengthening telegraphs broke the balance badly at first (jogger 167 → 46 of 200), and chasing it turned up two real faults rather than needing a tuning pass. Defence answered `INCOMING_ATTACK` for as long as the wind-up lasted, so a longer telegraph was simply a longer free block — a fighter now answers the *start* of a telegraph (`REACTION_WINDOW` 0.3 s, and never in the same step it begins). And fighters always decided in the same order, so the player always attacked first and was therefore always the one caught mid-attack when the other answered; deciding order now alternates. That last one was worth 175/167/128 against 155/95/129.
- Fight length was restored with a scalar rather than more timing changes: `hp_base` 24 → 40, `hp_per_endurance` left alone (raising it amplified the endurance gap and made the Delivery Worker the hardest fight). Measured now: wins 175/167/128 of 200 and 8.2/10.7/8.3 s against a baseline of 167/163/161 and 10.3/14.3/9.2 s. The Old Master is still 0/200. The Gym Regular at 64% is the widest departure — opponents now differ more from each other, which reads as variety rather than as a fault, but it is a change worth the owner knowing about.
- The stagger check now obeys the same commit rule as a bark: an attack they have already committed to still comes.
- Design consequence worth surfacing: a fight is short enough that **one strong bark is all anyone gets, whatever the rhythm**, so the resistance curve tuned in the Gate 02 pass no longer differentiates pacing from spamming (both 180-182/200 against 128 plain). `combat_sim_test` now asserts what is actually true and worth protecting — extra barks are worth nothing — instead of a claim the timings no longer support.
- Storyboard comparison (owner, 2026-09-19): the fighters "tipped over" because `Greybox.human()` returned a flat bag of primitives — two leg capsules, two arm capsules, a torso, a head, all siblings of one root, with no hierarchy at all. Every combat animation could therefore only move that single root, so a punch was the whole figure sliding forward 0.3 m and a death was the whole figure rotating 90° about one axis, feet and head turning at the same rate. That is a plank falling, not a person, and no amount of art fixes it: the body had no ability to be posed.
- The body is now articulated: `Hips → Torso → (ArmL, ArmR, Head)` and `LegL/LegR` off the root, each at the joint it actually turns around, looked up by `Greybox.part()`. A wind-up draws the striking limb back and turns the body into it; a strike swings that limb through; going down buckles the legs, drops and folds the hips, and puts one arm out towards the dog (storyboard 08). **Ownership boundary**: this is the ability to be posed, which is gameplay. What the poses should look like is design's (P03-D04 silhouettes, P03-D06 owner condition) and none of Codex's art code changed — `Greybox.bind_parts()` moves anything art adds to the root in plain world coordinates onto the body part it sits on, so faces, hair, clothing and bags travel with the limb they belong to.
- Two mistakes of my own here, neither caught by the existing tests: `_reset_pose` did not reset the new joints, so limbs kept the previous action's pose; and the fall tweened the hips' `position:y` to an absolute −0.46 when that joint rests at 0.72, which would have sunk the upper body through the floor. `combat_motion_3d_test` now checks the joints exist and hang off each other, that the hips sit at hip height, that art decoration ends up on the head, and that a wind-up actually rotates an arm.
- D4/P02-010, the storyboard's emotional end (frames 09/10): winning now holds in the dog's eyes while the owner crouches, reaches a hand out and puts it on the dog's head. A new AFFECTION context keeps `pov` at 1 for the beat and watches the owner alone — the beaten pair is not part of being thanked — before RELEASE blends back out.
- This needed the dog to have a head to pet, which is storyboard 06 and was missing: in first person the dog's mesh was hidden outright, so the player saw nothing of themselves. `DogFirstPersonView3D` puts the muzzle low and centred with both ear tips at the upper corners, hanging off the camera, and it dips under the hand when it lands. Sized to sit at the frame edges, as the camera spec allows only "if they improve identity without obscuring combat".
- The reaching hand is only possible because of the joint work: before it, the owner could not raise an arm at all.
- Two test-timing notes, in the same family as the earlier ones: moving into the dog's eyes is a blend, so a check one frame after the win reads `pov` at 0.43 and fails for the right reason; and the hand and the dip happen within the same two seconds, so sampling them in sequence misses whichever went first — watch the whole beat at once.
- The atmosphere director assumes audio (ducking ambience, impact, dog breathing, low-frequency pulse before the first strike). The project still has none, and this now blocks P03-E09.
- P03-E12: a capture tool records the fight under normal presentation (no debug, no fight text) at the 405×720 portrait size the ART capture requests use. `tests/capture/record.sh` plays scripted cases in the real 3D walk through Godot's Movie Maker into `build/captures/<case>.avi`: snap (approach and Combat Snap), orbit_cw, orbit_ccw, behind_bark, leash_pull, critical, win, loss, and p02_snap (the same approach under the P-02 third-person camera). One case per clip, so nothing is written on the picture. It needs a desktop session (Movie Maker renders); it asserts nothing and is not part of the test run.
- The captures found what the headless tests had not: with the dog standing still beside a fight, the fighters circled straight onto it and the dog's eyes filled with clothing seen from below, a gate Critical Fail ("camera makes fight unreadable"). Fixed at the cause and without moving the dog, as the composition docs require: fighters keep 0.9 m clear of the dog (P-04: "adjust path round the dog"), through the same "where can I stand" question as walls. That question now answers with how badly placed a spot is, and no move may make it worse, so someone inside the margin can step out or round but not further in and nobody is pinned; a dog that keeps them from closing for 2 s stops counting until they are in range, so it cannot jam the fight. A person right at the lens, or standing between the lens and the dog outside first person, is faded, never hidden; that includes the opponent's dog. The dog's eyes look up no further than 20°, so a person right beside it no longer turns the view into sky and chins. What the owner learned ("主人記住了…") now waits until the fight is over instead of appearing over it.
- Tried and dropped: easing the view out of the dog's head when a fighter came close. It moved the lens 2 m back behind the dog, into the space the fighters were circling through, and made the view snap (0.26 rad in a frame).
- `dog_pov_presence_test` gains the case: a dog standing 0.7 m from a live fight for 6 s. Without the clearance it fails (up to 131 of 360 frames with a fighter pressed onto the dog); with it, none. `combat_motion_3d_test` checks the first-person view faces the fight and does not crane up past the cap.
- For ART review (P03-D10, D4-17), seen in the final captures and not changed: with the dog directly behind its owner the owner's back hides the opponent (the composition doc lists "owner blocks entire rival" as a failure); a person standing just beyond the fade distance can still fill much of the portrait frame from dog height; and in the defeat beat the downed owner is very close to the dog's eyes. These are composition calls for review, not engineering failures the spec settles.

## P-04 HUMAN BRAWL FEEL + PHYSICAL PRESENCE (Update 006 Patch 03)
Installed 2026-09-28. Spec: `docs/01_prototypes/P_04_HUMAN_BRAWL_PHYSICAL_PRESENCE.md`; ADR-016 (PROPOSED). Combat must read through motion and physical interaction, not text. Obvious Dog↔Human or Human↔Human penetration is a Critical Fail. Out of scope: ragdoll, a large move list, direct dog combat, rope wrapping, territory work, new map content.

**BLOCKER:** Sprint 05 engineering stays gated until the P-04 Brawl Feel Gate (`docs/07_qa/P04_BRAWL_FEEL_GATE.md`).

| ID | Task | Status |
|---|---|---|
| P04-01 | Physical presence baseline | REVIEW |
| P04-02 | Combat spacing/footwork | REVIEW |
| P04-03 | Jab phases/contact | REVIEW |
| P04-04 | Heavy Hook | REVIEW |
| P04-05 | Kick | REVIEW |
| P04-06 | Block/Dodge | REVIEW |
| P04-07 | Hit reactions/impact | REVIEW |
| P04-08 | Anti-stuck/sliding | REVIEW |
| P04-09 | Dog POV presence test | REVIEW |
| P04-10 | Bark/Pull integration | REVIEW |
| P04-11 | No-HUD readability | REVIEW |
| P04-12 | Fresh Codex blind QA | TODO |

## P-04 Engineering Notes (Claude)
- P04-01: before this, nothing in the 3D walk occupied space except the world. The dog and owner collided only with walls, and an opponent human or dog was a drawing with no body at all, so the dog walked straight through everyone. Now every primary body is solid: `PhysicalPresence3D` (an `AnimatableBody3D` riding on the node it is attached to) gives each opponent human and opponent dog a capsule no wider than what is drawn, and both the dog and owner collide with the actor layer. The dog slides round a body it clips the way it slides along a wall. Sizes and the bump response are data (`data/presence/presence.tres`, `PresenceData`, per the P-04 tuning schema).
- Fast contact (≥ 4.5 m/s into someone, i.e. sprinting) is answered by the body, never by the fight: the person gives 8 cm away from the dog, sways and glances down, then settles (`FighterPuppet3D.play_bumped`); their dog steps back. It gives way to anything the fight is already doing with that body, and walking into someone is only a block.
- Ownership: the combat sync still places both fighters directly, so in a fight the dog is the one that gives way. A dog left partly inside a fighter is pushed back out by the physics. Exactly dead centre it is not (no direction to push), which belongs to P04-08 anti-stuck.
- Not in this task: human↔human separation and the opponent's knockback against the world (P04-02 / P04-07). A fighter who is down still has a standing body where they fell (P04-07 reactions).
- `physical_presence_test` (21 checks) drives the dog through the real Input Map into each body, in and out of a fight. `combat_motion_3d_test` pushed the dog forward from a metre off the fight to check the stick direction and could now end against a fighter depending on the random orbit; it steps back first.
- P04-02 (owner chose option A, 2026-09-28: keep the one-dimensional rules, let the simulation own an angle). Footwork now belongs to the simulation instead of being a camera-side orbit. Between actions nobody stands still: too far, they close; too close, they backstep out; in their band (`ideal_min`–`ideal_max`, 0.58–0.68 m) they circle, sometimes sidestep and sometimes switch direction; and after an attack they sometimes step back to reset the distance. A fighter circling moves round the other one, who stays exactly where they are: the fight's line turns about them (`line_angle`, `origin`) and the distance does not change, so every rule and outcome still comes from the distance. All of it is data (`data/combat/spacing.tres`, `SpacingData` per the tuning schema); approach speed is a scale on each fighter's own speed stat, so training still shows.
- Human↔human: the closest two fighters could stand was 0.30 m centre to centre, against 0.48 m for two bodies, so any shove (dodge, leash pull) could put one inside the other, which is a Critical Fail under P-04. `hard_min_separation` is now 0.52 m.
- Balance moved little (200 fights each, player vs jogger/delivery/gym): wins 163/152/113 → 169/157/122, fights about 0.2 s longer, Old Master still 0/200. All `combat_sim_test` balance bands hold unchanged.
- Presentation reads the simulation's footwork (`CombatMotion3D` gains SIDESTEP and BACKSTEP; APPROACH now means the simulation is actually closing). The fake side-to-side sway in CIRCLE is gone, because they really move now. The run RNG draw that used to choose the camera orbit direction now chooses which way the fighters start circling, so run seeds and loot are unchanged.
- Seen while testing, for P04-03..05: fighters approaching from range both open with a kick at the edge of its 1.0 m reach, so the first exchange is two simultaneous kicks from a standstill. That is the attack layer (reach and phases), not footwork, but it reads as "stationary trading" at the start of a fight.
- Not handled yet: circling does not know about walls, benches or the dog (P04-08/P04-09); the dog still gives way when a fighter steps onto it.
- `combat_spacing_test` (20 checks, 36 simulated fights) covers the band, never standing inside each other, every footwork kind happening, under 5 % of free time spent standing still, the line turning, resets after exchanges, and determinism. `physical_presence_test` now also checks, in the 3D walk, that the fighters' bodies never overlap and that the ground matches the simulation's distance and line.
- P04-03: an attack is now an event with a shape, WINDUP → STRIKE → CONTACT → FOLLOW_THROUGH → RECOVERY, not a wind-up that deals damage the instant it ends. It can land only inside its contact window, only on a body within reach at that moment (checked every step of the window, so someone stepping into it is hit), and only once. A window that closes on nobody is a whiff: it keeps going through the follow-through and adds `whiff_recovery`, which is the opening a counter, bark or pull can use. The strike animation now plays when the strike is released (a new `strike` event), before anyone knows whether it lands; contact events only add the other body's answer.
- The punch is now the Jab (`skill_jab.tres`, 刺拳): wind-up 0.40, strike 0.06, contact 0.06, follow-through 0.08, recovery 0.22, whiff +0.18. That is 0.82 s from start to ready (the punch took 0.87), and it lands 0.46 s after the telegraph starts (the punch landed at 0.45). It keeps the 2D sprite's `punch` animation key.
- The kick is deliberately unchanged until P04-05: it lands as its wind-up ends (0.02 s window) and stays out for the same 0.18 s as before.
- The leash now protects the owner until the attack's contact window closes, not just until its wind-up ends; otherwise a pull could save them from the telegraph and still leave them standing in the strike.
- Balance (200 fights each): 169/157/122 → 160/159/137 wins against jogger/delivery/gym, fight length unchanged, Old Master still 0/200. The Gym Regular moved most (61 % → 68.5 %), because a whiffed kick-then-jab now costs the whiffer more. All balance bands hold.
- `combat_contact_test` (26 checks): phase order, nothing lands during the wind-up, landing inside the window, landing once however long the window is, whiff and its extra recovery, stepping into an open window, blocking inside it, the pull covering it, and across 20 real fights no outcome ever arriving before its strike.
- P04-04 BLOCKED on a balance decision for the owner. The groundwork is in and unused: `skill_heavy_hook.tres` (重勾拳: wind-up 0.55, strike 0.10, contact 0.06, follow-through 0.18, recovery 0.40, whiff +0.30, power 1.3, stagger 4, displacement 8, cooldown 5), a `displacement` field every attack can use, and the hook's body (shoulders and hips load away and the arm comes up and out on the wind-up, the arm sweeps across at shoulder height on the strike, and the person hit twists with it). No fighter carries it yet, so nothing plays differently.
- Why it is blocked: given to every fighter, it pushes the untrained player below the approved "beatable but not free" band (≥ 50 %). Best setting found, 200 fights each against jogger/delivery/gym: 95/165/86, against 160/159/137 without it. A slow, readable heavy punch is exactly what a quick fighter steps away from or dodges: 60 % of the player's hooks missed the Jogger, against 28 % of the Jogger's hooks missing the player. No combination of wind-up, power, displacement or cooldown brought the Jogger and Gym fights back into the band.
- Found on the way: with a 0.55–0.65 s wind-up, a guard raised against the hook (0.6 s) drops just before its contact window opens, so blocking it never worked. The fix (a guard raised against a blow you saw coming stays up until that blow's window closes) is written and measured but not committed, because on its own it moves the Delivery Worker from 159 to 99 of 200. It belongs with whichever balance option is chosen, or with P04-06 Block/Dodge.
- Also seen: with kick and hook alternating on their cooldowns, the jab is almost never chosen (the AI always takes the highest-priority valid attack). The spec treats the jab as the everyday attack, so the priority-only choice needs revisiting whichever way the hook goes.
- P04-04, option A tried (owner, 2026-09-28): the hook for the player, the Gym Regular and the Old Master only. Parked on branch `p04-04-hook-wip`; main is unchanged. On that branch attack choice is a weighted pick among valid attacks, so the jab is thrown again, and a fighter takes the heaviest blow into an opening (the dog's bark, or someone recovering from a swing). The balance bands hold (200 fights: jogger 143, delivery 134, gym 105; Old Master still wins all), but paced barking's edge against the Gym Regular falls to about a tenth of fights (+22 of 200, +8 of 100 on the test's seeds), under the tested bar. The cause is the Gym's own hook: it misses so often that the player wins more without the dog, which squeezes the bark's margin (against a Gym without a hook barking is worth +42 of 200). Stepping in behind the hook raised the bark back to +28 of 200 but dropped the Gym fight under half. Needs an owner call on which approved number moves: bark strength (P04-10 territory), opponent stats, or the bark bar.
- P04-04 unblocked by the owner (2026-09-28): "狗本來就不該是左右戰鬥重點". Recorded as ADR-L02 (the dog changes the exchange, not the result). The bark test now asks that paced barking helps and that its edge stays within 15 of 100 fights, instead of requiring it to swing at least a tenth of them. The option-A branch is merged: the hook for the player, the Gym Regular and the Old Master; attacks chosen by weighted priority, so the jab is thrown again; the heaviest blow into an opening (a bark, or someone recovering from a swing). Balance (200 fights): jogger 143, delivery 134, gym 105, Old Master still wins all; paced barking against the Gym Regular adds about 22 of 200.
- A real bug surfaced while stabilising the tests: after a win nothing turned the owner round to the dog, because only the running fight calls `face_towards`. It only looked right when the owner already faced that way, which circling (P04-02) made a coin toss. `play_acknowledge` now turns them to the dog itself.
- Tests: `combat_contact_test` gains the hook (data, who carries it, displacement landed and blocked, the heaviest blow into an opening); `combat_motion_3d_test` checks that the hook's wind-up turns the shoulders and hips away and raises the arm, and that the strike unwinds the body through and past square.
- P04-05: the kick now runs all five phases and reads as a kick. Its wind-up chambers the leg, lifting it up in front while the upper body leans back and the hips tilt to balance it; standing on one leg is the commitment the dog can read. The strike drives the leg out level with the hips in behind it, and it stays out through the follow-through. Timing: wind-up 0.65, strike 0.12, contact 0.06, follow-through 0.14, recovery 0.60, whiff +0.20. It still lands about 0.8 s after the telegraph starts (0.77, against 0.80 before), so the dog's window is unchanged. It reaches furthest (1.0 m), telegraphs longest and is the biggest commitment of the three attacks (1.57 s start to ready).
- The kick deliberately has no displacement. Measured: 14 units of kick knockback swings the Gym fight by 50 wins in 200 and the Jogger fight by 25, so knockback is left to P04-07 (impact) to decide as a whole.
- Balance (200 fights): jogger 130, delivery 131, gym 103; Old Master still wins all; paced barking against the Gym Regular adds 14 of 200 (within ADR-L02). For the owner's playtest: the Student, who has the player's exact stats but no hook, now beats the player about 78 % of the time (45 of 200), and that matchup swings widely with small timing changes. It is outside the tested bands.
- P04-06: a dodge is now getting out of reach, not a shield. It used to succeed whenever the defender was in the dodge state, wherever they stood; the gate calls that a Critical Fail. Now someone still in reach when the contact window opens is hit however hard they are trying to get away, and a blow that whiffs because its target backed out is reported as `dodged` (the defender snaps back from it and the attacker overreaches). The fake 32 cm sideways slide in the dodge animation is gone, because the simulation already moves them for real. Balance is unchanged to the fight (200 fights: 130/131/103): with the current timings a real dodge always got far enough anyway, so the auto-success never decided anything, it only made the rule dishonest.
- Block: the guard now stays visibly up through a blow. The hit reaction used to reset the pose and drop both arms at the moment of contact; the forearms are now knocked back towards the face and set again, and the guard comes down when the block actually ends rather than whenever the next action happens to reset the pose.
- Still dog-owned and unchanged: a leash pull still carries the owner clear by protection time rather than by distance. It is the dog's action and P04-10 (Bark/Pull integration) revisits it.
- Tests: `combat_contact_test` (a dodge in time is out of reach when the window opens and costs nothing; one too late is hit); `combat_motion_3d_test` (both forearms up in a guard, a blocked blow knocks it back without dropping it, it sets again, it comes down when the block ends, and a dodge leans away without sliding the figure).
- P04-07: the reaction set is the spec's: HIT_LIGHT (was HIT_REACT), HIT_HEAVY (a hook or kick, or any hit heavy enough), STAGGER, STUMBLE (a bad leash pull, which used to borrow STAGGER) and DOWN, each holding the body for its own moment: light 0.28 s < heavy 0.40 < stagger 0.45 < stumble 0.50. Each blow is answered differently at the moment of contact: a jab snaps the head back, a hook turns the body with it and the head further, a kick folds them over it with the hips driven back. The impact happens all at once and the recovery after it; before, part of it was chained a step late.
- Hit-stop is per attack and inside the spec's ranges: jab 0.05 s, hook 0.08, kick 0.09, a blocked blow 60 % of that, and nothing ever holds longer than 0.10 s, even the dog's biggest opening. The heavy hit-stop used to reach 0.16 s. The camera impulse and contact flash are unchanged, still scaled by the blow.
- Not in this task: knockback checked against walls and other bodies is the same mechanism as keeping circling fighters out of walls, so it goes with P04-08. Impact audio is still missing because the project has no audio yet (the same gap blocks P03-E09).
- P04-08: the fight now knows where people cannot stand. The simulation takes an optional `walkable` question about a ground position, and the Run World answers it with a body-sized shape query against walls, benches and trees (people and the dog are not obstacles here: the simulation keeps the fighters apart and the dog gives way). A step back, a dodge, a leash pull and a knockback all stop at a wall, so a dodge into a wall does not save anyone, which is honest. A blocked approach turns into circling round the obstacle, and circling into a wall turns them the other way, so nobody walks into a wall for ever. Someone who is already caught in something may always move, so nobody is pinned. Headless, the question is unset and every balance number is unchanged.
- The dog is never left inside a body. Physics pushes it out of a partial overlap but has nothing to push by when it sits dead centre; there it now steps out itself (away from the body, or backwards). It only does this for a deep overlap (under 0.15 m centre to centre): a first version that also acted on mere contact shoved the dog away from anyone it leaned on, and the extraction test caught it.
- The dog cannot jam the fight (a gate Critical Fail): fighters never stop for it, it is moved aside instead (ADR-016), and it can never end up stuck inside one.
- Tests: `combat_spacing_test` runs 24 fights with a wall behind the player or a post between them (nobody ever stands in it, every fight still ends in a winner) and checks that a fighter who starts inside something is not pinned; `physical_presence_test` puts the dog dead centre in a fighter and checks the Run World says no where a wall is.
- P04-09: a new test, `dog_pov_presence_test`, plays physical presence the way the player sees it: from inside the dog's head during a live fight, steering through the real Input Map round the fight one way, straight in, back out and round the other way (about 34 m and more than two laps in 7 s). It checks that the first-person view holds, the dog moves freely and can circle, the lens never enters a person, the dog never stays inside one, and the view never snaps.
- It found a real snap. The first-person aim was kept as a point in the world, so when the dog ran close past someone the view swung by parallax alone, up to 0.41 rad (23°) in a single frame, which the existing turn cap never saw. The aim is now a direction from the eye, and only that direction turns, never faster than the cap, however the dog moves: the sharpest turn measured is now 0.05 rad per frame (the cap plus a little hit shake).
- It also showed that the collision body was narrower than the drawn one: the torso is drawn 0.27 m wide and the body was 0.24, so two fighters at their closest (0.52 m) visibly overlapped by about 2 cm. The body now matches the widest drawn part (0.27 m) and fighters never stand closer than 0.56 m. Balance unchanged (130/131/103). The lens stays at least 0.39 m from anyone's centre, outside every drawn part at the dog's eye height.
- Also found in P04-09, by the extraction test failing about one run in six: a dog (or owner) standing on a person or another dog took that body as its floor, a moving platform, so when the body was placed somewhere new (fighters and opponent dogs are positioned directly) its jump was handed on as velocity and flung the dog up to 23 m across the map. Only the world is ground now (`platform_floor_layers`, no platform walls) for both the dog and the owner. `physical_presence_test` stands the dog on their dog and moves the pair 5 m: without the fix the dog is carried 3.6 m, with it it stays put.
- P04-10 (in progress): the leash is now physical. A good pull hauls the owner back 0.7 m over 0.25 s instead of teleporting them in one frame, and nothing protects them but the distance it makes: pull in time and the blow whiffs (reported as dodged); pull too late, or into a wall, and it lands. Fighters also no longer walk back into a blow they can see coming while they are out of its reach, which is what undid a successful pull at first (the owner, yanked clear of a kick, strolled straight back into it). The bark's opening multiplier is now data (`GameBalance.opening_damage`, still 1.4). Balance (200 fights): jogger 111, delivery 138, gym 116; Old Master still wins all.
- P04-10 finding for the owner: measured with a perfectly timed dog, the dog decides fights, against ADR-L02. No dog → bark every 6 s → pull on every enemy wind-up → both: jogger 130/195/200/200, delivery 131/187/200/200, gym 103/136/199/200 of 200. The cause is structural, not a tuning slip: fights last 8–12 s and a kick takes about 38 % of the owner's health, so avoiding one blow or cancelling one wind-up nearly decides the fight. Weakening the bark's multiplier (1.4 → 1.1) or making the leash rarer (one pull per 9–12 s) still left each one adding 30–60 wins. Three times the health gives 27–37 s fights (the P-04 goal is a 30–60 s brawl) and brings the bark to +11..+26 and the leash to +29..+46; untrained player wins rise to 154–171 of 200. Waiting on the owner before changing fight length.
- P04-10 finished (owner chose option A, 2026-09-29: fights three times longer). Health ×3 (`hp_base` 40 → 120, `hp_per_endurance` 3.6 → 10.8): fights now last 28–39 s on average (longest 60 s), inside P-04's 30–60 s brawl. Longer fights make outcomes more predictable, so any steady edge becomes near-certain wins; the dog's help is therefore bounded per fight rather than per second. The leash can haul the owner clear at most twice a fight (`PULL_SAVES_PER_FIGHT`); after that they have their footing and a pull only braces them ("我站穩了！"), at no cost. A blow missed only because its target was hauled away is not the attacker's whiff (no extra recovery, no opening), and a bark's opening now covers one blow rather than a combination (`opening_grace` 1.2 → 0.5 s, `opening_damage` 1.4 → 1.25, both data).
- Result, untrained player against jogger / delivery / gym, 200 fights each, no dog → bark every 6 s → leash on every wind-up it can → both: 135/177/185/189, 162/178/193/185, 167/174/183/184 (Student 46 → 81, Old Master 0 throughout). A perfect dog used to make these fights certain (200/200); now it helps and never guarantees. The untrained player's odds (67–84 %) are in line with the approved pre-P-04 difficulty (87/83/64 %), so opponent stats are unchanged. The Jogger matchup is the most sensitive to the dog (+54), because it is the closest in health terms and any help worth one blow tips a close fight.
- `dog_value_test` checks this against all three ordinary opponents (the old bark check only looked at the Gym Regular, whose margin is the smallest): a perfect dog never makes a fight certain, never adds more than 35 % of fights, and bark and leash each help overall.
- P04-11: in normal play nothing explains a fight in words. The one fight-text switch (`FighterPuppet3D.show_combat_text`, off; debug panel "戰鬥文字/血條") now covers the combat log, the health bars over the fighters, the dog's outcome toasts ("✦ 對手分心了！…") and the lines that announce a mechanic (好機會！, 哇！差點被打到！, 我站穩了！, （不理你）, 別扯啦！, 哇！你叫什麼啦！). Story dialogue at the start and end of a fight stays, and so does the dog's "汪！" caption, which stands in for a bark sound while the project has no audio.
- Without the bars, how each fighter is doing shows in the body (this also covers the owner-condition idea in D4/P02-008): from 60 % health down they stoop, their guard drops and their feet get heavy, and near the end they sway on their feet. The rest of the gate's questions were already answered physically by P04-01..10: who attacked (wind-ups per attack), hit or miss (contact, whiff overreach), light or heavy (the jab's head snap, the hook's twist, the kick's fold, hit-stop), block or dodge (the guard knocked back, a real step out of reach), pressure (backsteps, knockback, now posture), loss of balance (STUMBLE), and the dog (their head turns to a bark; the owner is hauled by the leash).
- Test: `combat_motion_3d_test` checks that in normal play there are no health bars, a landed bark produces no announcing line and no toast while their body turns to the dog, the debug switch brings the bars back, and a badly hurt fighter stoops and sways. Its leash-lean check now samples on process frames, where the tween runs; it failed about one run in ten sampling on physics frames.
- Codex ART integration (owner request, 2026-09-29: "把codex做的東西套進遊戲中"). Codex's P-04 human (`p04_owner.glb`, 53-bone rig, 17 clips) is now every person in the 3D walk (`art/use_p04_candidate` on in project.godot). Codex grades it B, not final art; the owner asked for it explicitly. Outside a fight people play its authored Walk / Idle clips; in a fight the tested P-04 choreography drives its joints through Codex's adapter; going down and being beaten play its authored Down clip, because the adapter maps rotations only and the fall drops the hips. Codex's Big Banyan (`banyan_01.glb`) and scent-state set replace the greybox tree on the existing landmark (P4-006), with the scent pieces following the territory state; the greybox build is kept as a fallback.
- Integration fixes: the adapter turned bones wrongly (it dropped each bone's rest rotation and ignored its parent, so a 0.5 rad turn of the head control moved the head bone 0.06 rad and every choreographed pose would have been wrong or invisible); it now computes the local pose as parent-rest⁻¹·control·parent-rest·local-rest, and Codex's own validator still passes. `Greybox.set_faded` only worked on greybox materials, so none of the camera fades would have reached the new model; imported meshes now get their own copy of each material the first time they are faded. The opponent's dog fades at 1.6× a person's distance, because at dog-eye height it fills far more of the frame.
- Not integrated yet: the authored combat clips (Jab, HeavyHook, Kick, Block, Dodge, HitLight, HitHeavy, Stumble, footwork) — using them in fights needs their timing matched to the simulation's phases, which Codex flags as a separate integration; and the greed props and risk HUD, which are compositions for Sprint 05 systems still gated. Codex's review scene, tools and source art are committed but excluded from every export.
- Codex's combat clips are now in the fight (owner, 2026-09-29). They are timed by the simulation, not by their own clock: Codex authored each strike as an out-and-back whose peak is exactly halfway, so the first half of Jab / HeavyHook / Kick is spread over the wind-up and strike and the peak lands as the contact window opens, and the second half over contact, follow-through and recovery (a whiff's longer recovery never runs it backwards). Block holds, Dodge follows the evasion, HitLight / HitHeavy / Stumble follow the reaction being held, and footwork loops Approach / Circle / Backstep, with Idle as the fighting stance. The P-04 choreography now layers over the clips at half weight instead of replacing them: the adapter adds each control on top of the clip's pose that frame (one-shot clips that have ended play alone, so nothing accumulates), and the choreography's whole-body tilts are kept at the same half weight, so a fighter leans with a blow rather than tipping over. Codex's review scene keeps its controls-only mode.
- Seen in the captures and fixed with it: the opponent's dog stood at a fixed spot beside its owner, so the fight could circle the player's owner right into it; in a fight it now keeps to the far side of its owner, easing there. Under the P-02 camera the owner is no longer faded for standing between the lens and the dog (they are that camera's subject), only when right at the lens.
- Still for review (ART / owner): at dog-eye height a fight within a metre is mostly legs and torsos even with the look-up cap; the clips are Codex's first-pass B-grade studies, so timing looks right but the poses are not final.
- Owner report (2026-09-29): "人物不正常的旋轉". A side-view capture (`record.sh inspect`) and a probe of the rig found it: the pelvis bone drifted to 90–160° and stayed there, so fighters leaned far back and one ended up on its side in mid-air. Godot's import drops animation tracks that never change (the pelvis in most of Codex's clips), so the clip did not rewrite that bone each frame, and the choreography layer took its own previous output as the next base and added onto it every frame while a hip accent was playing. The layer now remembers what it wrote: a bone the clip did not rewrite keeps the clip pose it was based on. The pelvis now stays within 16–28° (its natural angle) through a whole fight. `combat_feedback_test` checks it (157° from rest without the fix).
- Seen in the same capture, for the owner / Codex: every one of Codex's clips, Walk and Idle included, carries the fighting guard (hands at face height), so people simply standing or walking in the park hold their fists up; a relaxed stand and walk would need new clips. And the new model's arms are longer than the greybox's, so at the current spacing (0.56–0.68 m) the guards and a jab pass through the other person; matching reach and spacing to this body is a spacing and balance retune.
- P-04 combat spacing retuned to Codex's human (c5d8f3a, merged dc52e86). Measured reach forward of the pelvis: guard 0.30 m, jab 0.51, kick foot 0.68, hook hand 0.29, body front about 0.17 (two guards meet at about 0.60 m apart). Spacing is now ideal 62–69 with hard_min 60 (was 58–68 / 56); reach is jab/hook 73 and kick 82 (was 70/70/100), so a hit counts where the clip actually lands. Fixed `pose_clip` cross-fading while the clip was held at speed 0: the fade never finished, so the held combat clips never actually took over. Balance over 200 fights, untrained player, with the perfect dog's gain from bark / leash / both: Jogger 161 (+13/+12/+9), Delivery 180 (+3/+12/+13), Gym 159 (+5/+21/+9), Student 74, Old Master 0, all within the bands. Guards and jabs now stop at the other body; art gap for Codex: the HeavyHook clip barely moves the hand forward (0.29 m), so the hook cannot visibly reach its hit range and still overlaps the opponent's shoulder up close. Also for Codex: relaxed (non-guard) Idle and Walk clips.

## Sprint 05 — GREED / TERRITORY EXECUTION (Update 008)
Installed 2026-09-28. Spec: `docs/03_sprints/SPRINT_05_GREED_TERRITORY_EXECUTION.md`; systems `docs/04_systems/GREED_TERRITORY_SYSTEM.md`; data `docs/05_data/SPRINT05_DATA.md`; gate `docs/07_qa/SPRINT05_GREED_TERRITORY_GATE.md`; ADR-017 (extraction creates choice), ADR-018 (territory requires return). P-04 stays the combat baseline: Sprint 05 consumes it and does not redesign combat.

**ENGINEERING GATE:** P-04 Brawl Feel Gate PASS, or explicit owner approval with named exceptions. Design (D5-01–D5-10) may start now. Recommended engineering order: value model → extraction decision → Banyan/scent → Mark Territory → Rival Pair → persistence → extraction claim consolidation → Dog Desire → reward → blind QA/P-04 regression. Out of scope: global territory strategy, passive economy, PvP, BattleScene, combat rewrite, daily decay, giant capture UI.

| ID | Task | Status |
|---|---|---|
| S05-01 | SAFE/UNBANKED/PERMANENT runtime | REVIEW |
| S05-02 | Extraction decision presentation | IN_PROGRESS |
| S05-03 | Run Tension Director | TODO |
| S05-04 | Big Banyan integration | TODO |
| S05-05 | Scent ownership | TODO |
| S05-06 | MARK_TERRITORY | TODO |
| S05-07 | Persistent Rival Pair | TODO |
| S05-08 | Territory persistence | TODO |
| S05-09 | Extraction-based claim consolidation | TODO |
| S05-10 | Dog Desire integration | TODO |
| S05-11 | Ownership reward/event | TODO |
| S05-12 | Defeat/value verification | TODO |
| S05-13 | P-04 regression suite | TODO |
| S05-14 | Fresh Codex blind QA | TODO |

## Sprint 05 Execution Engineering Notes (Claude)
- **Owner decision (2026-09-29): Sprint 05 engineering approved** ("核准 Sprint 05 開工") without waiting for the P-04 Brawl Feel Gate. Named exception: Codex blind-tests the P-04 gate separately; if its result changes combat, Sprint 05 adapts. Order: the value layers first, consolidating the finished P4-001..010.
- S05 ↔ P4 mapping: S05-01 ← P4-001/002 (SAFE/UNBANKED) + PERMANENT added; S05-02 ← P4-002 + owner condition and extraction direction; S05-03 new (Run Tension Director, grows out of P4-003 temptations); S05-04 ← P4-005; S05-05/06 ← P4-006; S05-07 ← P4-007; S05-08 ← P4-004/008; S05-09 ← P4-009/010; S05-10 ← P4-013; S05-11 ← P4-012.
- S05-01: SAFE (dog's bag) and UNBANKED (owner's bag) were already runtime state (`RunValue`, P4-001). PERMANENT is now `RunResult.banked_value_delta`: what finishing the walk actually added to the home stash, so overflow that did not fit is not counted. The result screen shows it beside the collection total. Test: `run_core_test`. Also: `dog_pov_presence_test`'s lens-fade check now measures the longest solid stretch per body, as its message says, instead of a total across the fight (it flaked at 6 total frames).
- S05-02 (in progress): already there from P4-002/003 — the exposed value line after extraction opens (`回家就安全 · 主人還帶著 $X`) and one temptation in the dog's voice. Added the extraction direction as a world cue: a soft, slowly breathing light column (14 m) over every open exit, visible over the rooftops from the far side of the map (`ExtractionPoint3D.is_showing_way_home`, `run_3d_slice_test`). **Open design question — owner condition:** the owner's HP resets at the start of every fight, so there is no run-level condition to present at the extraction decision. Carrying HP between fights would change combat balance and defeat odds; waiting for the owner's call.
- Overlap to reconcile when engineering starts: the earlier Sprint 05 install (Update 007) already built P4-001..P4-010 (run value/risk, SAFE/UNBANKED presentation, temptation hooks, territory state/data, Banyan landmark, Mark Territory, resident rival, claim progression, extraction resolution), all REVIEW and paused. Most S05 tasks build on or re-verify that work rather than start from nothing; each S05 task should first check what P4-xxx already provides.

## Sprint 06 — IDENTITY / BOND (Update 009)
Installed 2026-09-29. Spec: `docs/03_sprints/SPRINT_06_IDENTITY_BOND.md`; systems `docs/04_systems/IDENTITY_SYSTEMS.md`; data `docs/05_data/SPRINT06_IDENTITY_SCHEMA.md`; gate `docs/07_qa/IDENTITY_GATE_01.md`; ADR-019 (one human, one relationship), ADR-020 (randomness with attachment). Depends on the P-04 combat baseline and the Sprint 05 Greed/Territory baseline; redesigns neither.

**ENGINEERING GATE:** after Greed/Territory Gate 01 (which itself waits for the P-04 Brawl Feel Gate), unless the owner explicitly approves an isolated opening/adoption prototype earlier. Design D6-01–D6-10 starts now. Engineering order: dog candidates/shelter → human candidates/adoption → owner commitment/naming → PairState → Bond → Habit → Memory → Home → Collection → blind QA. Scope guard: no human roster, gacha rarity, reroll economy, romance system, giant relationship skill tree, new combat architecture or map expansion.

| ID | Task | Status |
|---|---|---|
| S06-01 | Dog candidate generator | TODO |
| S06-02 | Shelter selection | TODO |
| S06-03 | Dog POV adoption | TODO |
| S06-04 | Human candidate generator | TODO |
| S06-05 | Behavior/reaction matching | TODO |
| S06-06 | Owner commitment + naming | TODO |
| S06-07 | PairState persistence | TODO |
| S06-08 | Bond | TODO |
| S06-09 | Habit | TODO |
| S06-10 | Memory | TODO |
| S06-11 | Home pair presentation | TODO |
| S06-12 | Collection integration | TODO |
| S06-13 | Save versioning | TODO |
| S06-14 | Fresh Codex QA | TODO |

## Sprint 06 Engineering Notes (Claude)
- Overlap to reconcile when engineering starts: owner habits already exist in part. Sprint 03 TRAIN's OwnerBehavior and GrowthResolver turn repeated dog behaviour into visible owner reactions (leash stumbles, recovery pauses, hesitation, social readiness); S06-09 Habit should build on them rather than add a parallel system. Likewise S06-12 extends the existing Collection progress, and the current walk always uses one fixed owner (`player_human.tres`), which S06-04..07 replace with a generated, persistent one.

