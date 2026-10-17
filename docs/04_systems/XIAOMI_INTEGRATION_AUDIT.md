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
