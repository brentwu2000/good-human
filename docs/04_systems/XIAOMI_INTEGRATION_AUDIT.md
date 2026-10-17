# Xiaomi integration audit (Phase 0) — 2026-10-17, Claude

Spec: [XIAOMI_TOY_PROXY.md](XIAOMI_TOY_PROXY.md) (owner, v1.0, installed from `.claude/`).
Sheet: `assets/characters/human/concepts/xiaomi_bunny_robot_visual_target_01.png`.
Owner decision change: on 2026-10-14 Xiaomi was "model only, not an adopter (a 10-year-old would
fight adults)". The spec makes her an adopter whose fights are fought by a bunny toy robot.

## What exists

| Area | Where | Fact |
|---|---|---|
| Xiaomi model | `assets/characters/human/models/xiaomi/xiaomi.glb` | OwnerSkeleton, 19 clips (incl. hurt/KO clips she must not play), 1.35 m. No `.tres` uses it. |
| Adopters | `resources/human_background_data.gd`, `data/identity/human_backgrounds/*.tres` (8) | `skeletal_model` is the only per-background visual hook; no behaviour hook. |
| Adoption | `core/identity/human_candidate_generator.gd:14`, `scenes/adoption.gd`, `Game.adopt()` | background picked at random, stats 4–7 from one shared spread. |
| Owner fighter | `core/identity/human_candidate.gd:39 to_fighter_data()` | duplicates `player_human.tres`, copies `skeletal_model`. |
| Combat | `core/combat/combat_simulation.gd`, `combat_fighter.gd` | headless 1v1, sides `PLAYER=0`/`OPPONENT=1`. Targeting is implicit (`_other()`); **no hitboxes, no AOE/traps/projectiles**. The only owner-side damage is `_resolve_attack()`. |
| Fight in the world | `core/combat/combat_coordinator_3d.gd` | no scene change; PLAYER side is drawn by `human.puppet` (`HumanFollower3D`), the same body the leash and camera use. |
| Dog in fights | `core/agency/dog_agency.gd` | no QTE (ADR-011): bark distracts, leash pull saves/stumbles/drags out — all measured on `human`. |
| Defeat | coordinator `_on_finished` DEFEAT → `HumanFollower3D.State.DOWN`, `play_down()`; `RunManager.defeat_run()` → run bag lost | "hospital" is text only (`ui/run_result/run_result.gd:39`); there is no hospital cooldown system. |
| Owner HP | `RunManager.owner_condition` (S05) | carries between fights; hurt owner walks slower. |
| Weapons | `RunManager.equipped_weapon`; `WorldWeapon3D`, `RunMap3D:89` call `human.puppet.hold()` | the weapon is put in the owner's hand when picked up. |

## Where the spec meets this project

1. **Safety is easier than the spec assumes.** Enemies only ever hit "the other side" of the
   simulation; nothing can target a node. So if the PLAYER side's *body* is the robot, Xiaomi
   cannot be hit, locked onto or knocked down by construction. The work is presentation and
   wiring: every place that draws or measures the PLAYER side through `human` must go through a
   "fighter body" that is the robot in Xiaomi's fights (list below).
2. **"QTE" in the spec = Bark + Leash Pull here** (ADR-011). Bark works unchanged. Leash pull
   acts on the fighting owner; in Xiaomi's fights the leash is in her hand at the safe spot,
   not on the robot (decision D1).
3. **No hospital system exists**: defeat = run bag lost + "🏥" result text. "兔兔維修中" is the
   same cost (same loss rules, same owner-condition 0), with repair wording and a robot
   shutdown instead of the human KO.
4. **Weapons**: in her fights the robot holds the equipped weapon; while walking Xiaomi carries
   it in her backpack (not in her hand). Toy modules (拳套=weapon, etc.) are Phase 2.

### Places that use the owner's own body as the fighter (Phase 1 changes)
- `CombatCoordinator3D`: `start_engagement` (positions, hold, HP), `_sync`, `_on_combat_event`
  (`own = human.puppet`), `_update_motion`, `_contact_point`/`_fight_centre`/`_world_position`,
  `_on_finished`, disengage distance, debug text.
- `OpponentPair3D._wanted_dog_offset` (their dog placed by `coordinator.human`).
- `DogAgency._bark_in_fight`, `_update_leash`.
- `CameraRig3D.combat_center` (owner_actor), `CombatAtmosphere3D._fighter_position`.
- `HumanFollower3D.set_state(COMBAT/DOWN)` → Xiaomi gets a new SAFE state instead.
- `run_result.gd` defeat text; hurt-walk slowdown (Xiaomi must not limp).
- `FighterPuppet3D` body-stop only for `P04HumanVisual` (the robot skips it; fine for Phase 1).

## Phase 1 plan (minimum playable loop)

| Step | Change |
|---|---|
| 1 | `HumanBackgroundData.combat_proxy: PackedScene` (+ `proxy_fighter: FighterData`). New background `granddaughter` (小米, xiaomi.glb, proxy = bunny robot). |
| 2 | `BunnyProxy3D`: placeholder robot (pink/cream capsule body, ears, spring fists, wheels), a puppet with the same interface the coordinator uses (`face/hold/play_attack/play_hurt/play_down→shutdown`). |
| 3 | Coordinator `fighter_body`: `human` by default; for a proxy owner the robot is spawned in front of Xiaomi at engagement, Xiaomi walks to a safe spot behind the dog (validated against WORLD; fallback: out of the fight area, then cancel the fight), state SAFE (remote-control idle). All PLAYER-side drawing/measuring uses `fighter_body`. Cleanup on every end (victory, defeat, disengage, abort). |
| 4 | Defeat: robot shutdown (sparks/stars, slump), Xiaomi hugs/retreats, result text 「兔兔沒電了，要修理……」; loss rules unchanged. |
| 5 | Robot fighter data: 彈簧愛心拳 (attack, longer reach, small knockback), 兔兔翻滾 (dodge), block; uses the existing priority/cooldown evaluator. |
| 6 | Tests `xiaomi_proxy_test`: through the real walk with a Xiaomi pair — damage only lowers the robot side; Xiaomi never enters COMBAT/DOWN or plays hurt/KO; Xiaomi stays ≥ safe distance from the opponent throughout; defeat → shutdown + repair text; robot freed after each end; quick re-engage; other owners unchanged (existing suite). |

Phase 2 (skills/modules/save) and Phase 3 (robot art through the AI 3D factory) follow the spec.

## Decisions needed before Phase 1

- **D1 Leash in her fights.** Recommended: the leash stays with Xiaomi at the safe spot; bark
  works as usual; pulling hard away = Xiaomi calls the robot back (the existing "drag out" →
  disengage); pull-save/stumble (which shove the fighter's body) are off in robot fights.
- **D2 Adoption.** Recommended: Xiaomi comes to the shelter like any visitor (background
  `granddaughter`); a 10-year-old adopting alone could later show grandma beside her (not now).
- **D3 Sprint order.** This is outside the current plan (P-05 gate / Sprint 05–06). Phase 1 is
  self-contained and does not change other owners; it starts now on the owner's instruction.

## Phase 1 — done 2026-10-17 (REVIEW)

Decisions: D1 leash stays with Xiaomi (owner), D2 she comes to the shelter like any visitor (owner).

| Part | Where |
|---|---|
| Data | `HumanBackgroundData.combat_proxy`, `FighterData.body_kind`; background `granddaughter` (xiaomi.glb, proxy `bunny_robot.tres`); skills 彈簧愛心拳 / 彈簧重拳 / 兔兔飛踢 / 兔兔翻滾 + block; `HumanCandidate.to_proxy_fighter_data` (her own rolled stats), `PairState/Game.owner_has_proxy/owner_proxy_fighter` |
| Robot | `assets/characters/proxy/bunny_robot_3d.gd` (placeholder on the greybox joints, ~1.0 m), `actors/proxy/bunny_proxy_3d.gd` (pop out, shutdown, pack away) |
| Fight | `CombatCoordinator3D.fighter_node()/fighter_puppet()`: the robot while it is out; `_deploy_proxy`, `_send_xiaomi_to_safety` (clear spot 2.6 m back, fallback: hidden), `_keep_xiaomi_safe`, fighters keep 1.4 m from her (`_walkable`), `_finish_proxy_fight` |
| Xiaomi | `HumanFollower3D.State.SAFE`; weapons stay in her backpack (`FighterPuppet3D.keep_held_in_bag`), robot holds them; never walks hurt |
| Dog | bark measured on the robot; leash in her fights = only the drag-out → robot called back |
| Camera / atmosphere / opponent dog | frame and place by `fighter_node()` |
| Loss | robot shutdown + 「兔兔！……沒電了」; result 「🔧 兔兔沒電了，送去修理……」, HUD 「兔兔電量變少了/快沒電了」; same loss rules |

Check: `tests/xiaomi_proxy_test` (34 checks: never COMBAT/DOWN, ≥1.8 m from the opponent while fighting, robot takes the blows and holds the weapon, win / call-back / loss clean up, loss rules and repair text). Full suite 48/48. Capture `tools/art/capture_xiaomi_proxy.tscn` → `xiaomi_proxy_phase1_capture.png`.
Not yet (Phase 2/3): toy modules and repair cooldown, 積木雨/超級兔兔, Xiaomi's remote/cheer/hug clips (she uses her ambient clips), final robot art.

## Phase 2 — done 2026-10-17 (REVIEW)

Owner: 「照你的建議做 Phase 2」 — conflicts 6–10 resolved as recommended:

| # | Decision | Implementation |
|---|---|---|
| 6 | No repair cooldown (no other owner has a hospital cooldown) | text only (Phase 1) |
| 7 | Toy parts in existing slots only | **彈簧拳套** = weapon (`WeaponData.Archetype.TOY`, moveset `spring_glove`: 伸縮拳 reach 100, 重彈 104, block, 兔兔翻滾; wears out at 30; drawn as a pink spring glove); **玩具電池** = recovery item (`owner_recovery` 0.3 → the robot's battery). Casing/chip slots not built. |
| — | Found only by her, other owners untouched | `ItemData.proxy_only`; `LootTableData.proxy_entries` join the roll only when `Game.owner_has_proxy()` (park search: glove 6, battery 10; residential trash: 5, 10). Same entries, same seed → same rolls for every other owner (tested). |
| 8 | 積木雨 / 超級兔兔 data placeholders | `skill_bunny_block_rain.tres`, `skill_super_bunny.tres` (priority 0, in no skill list; the simulation has no slow/area effect) |
| 9 | Growth: Xiaomi's growth drives her robot | (Phase 1) |
| 10 | Robot may use umbrella/broom | unchanged |

UI: in her walks the bag says 「讓兔兔帶著」, 「🔋 給兔兔充電」 / 「🩹 給兔兔修一修」.
Check: `tests/xiaomi_proxy_gear_test` (26 checks: other owners' rolls unchanged and never toy parts; she finds both; robot wears and fights with the glove, she keeps it in her backpack; battery +30 %; glove lost on defeat, battery in the dog's backpack comes home; pair and stash survive save + reload). `data_loot_test` registers the two items and checks toy parts never sit in shared entries. Suite 49/49 (`fight_body_contact_test` failed once in one full run, passed 4 reruns: seed-dependent, non-proxy path unchanged).
Open (Phase 3): robot model (CX-17), Xiaomi clips (CX-18), robot body contact.

## Phase 3 — done 2026-10-17 (REVIEW, Claude took CX-17/18/19 over on the owner's word)

- **Robot model**: sheet front/side/back cropped (`good_human_stylized_factory/references/props/bunny_robot/`), TripoSG (Modly) from the front, `tools/art/robot_prep.py` (clean, 1.0 m, 150k hi / 12k low + UV), Trellis2 colours from front+back (`t2_texture.py`), `tools/art/robot_finish.py` (bake, white balance to the sheet, cut into six rigid parts with origins on the greybox joints, turned to face -Z). `assets/characters/proxy/bunny_robot.glb`; `BunnyRobot3D` hangs the parts on Hips/Torso/Head/ArmL/R/LegL/R (`MODEL_FIT` 0.43, primitive build stays as fallback). ~1.03 m in game.
- **Spring glove**: heart-shaped glove on a spring (sheet), `WeaponProp3D._spring_glove`.
- **Xiaomi**: SAFE plays M2M_Phone with a pink remote in her right hand; a win plays M2M_Cheer_One; a loss she walks to the robot and plays M2M_PickUp. No hurt/KO clips.
- Note: the model faces -Z in Godot, so in Blender its face is +Y — a "front" render from -Y shows the back of the head.
Check: suite 49/49, `xiaomi_proxy_test` 34, `xiaomi_proxy_gear_test` 26. Capture `xiaomi_proxy_phase3_robot.png`.
