# Claude → Codex (ART) handoff — 2026-10-09

From: Claude (gameplay/code). Owner: 「你有把新增的東西寫在文件中給codex去使用嗎 我需要他調整」.
Codex owns the art pipeline. Since 2026-10-07 Claude added or changed several art-facing things on the owner's direct requests. This document lists them, how each is rebuilt, what must not change, and **what the owner wants you to adjust** (section 2). Problems already hit and their rules: `docs/99_notes/LESSONS_LEARNED.md` (sections 1, 2, 6, 7 especially).

---

## 1. What exists now

### 1.1 Fight clips for the owner — generated, not hand-keyed
- **Generator:** `tools/art/make_fight_clips.py` (Blender 5.2, background): `blender -b --factory-startup --python tools/art/make_fight_clips.py`
- **Writes (overwritten on every run):**
  - `assets/characters/human/animations/p04_fight_clips.glb` (loaded as library `fight`)
  - `assets/characters/human/animations/p04_fight_grip.json`
- **What it makes, on your P-04 OwnerSkeleton:** poses solved with two-bone IK from targets (pelvis, chest, head, hands, feet).
  - **Empty-handed:** stance, footwork, jab/cross, both hooks, both kicks, block, dodge, light/heavy hits.
  - **Umbrella `_Armed`, one hand:** walking-stick style — guard, footwork, thrust, cut, hanging guard, reactions.
  - **Broom `_Long`, two hands:** held near the END of the handle — high guard, two-handed thrust, overhead chop, low sweep, shove, staff block, reactions.
  - **Carrying on the walk** (`Carry_Idle/Walk_Armed/_Long`): your relaxed clips with the lead hand closed round the thing.
- **Hands close in every clip:** fists empty-handed, round the shaft when holding. One hinge per finger. The palm is the opposite side from what the rest-pose finger bend suggests on this rig.
- **Blows** are built by `strike()`: an arc, the weapon lagging the hand and snapping through, a follow-through past the target, and a recovery with the hands kept out.
- **Grip:** `measure_hands()` curls the fingers round a shaft and measures the ring the middle finger makes. That gives the shaft axis and centre in the `hand_l`/`hand_r` frame → `p04_fight_grip.json`. Godot mounts props there (`WeaponProp3D.grip`).
- **Previews:** `blender -b --factory-startup --python tools/art/preview_fight_hands.py -- <out dir>` renders fists and grips close up.
- **References behind the poses:** `docs/99_notes/WEAPON_GRIP_REFERENCE.md` (Bartitsu walking stick, Arnis grip, broom as bayonet; game melee-animation practice).

### 1.2 Weapon props — how the game mounts them (your `assets/props/weapons/*.glb`)
- **Origin = where the lead fist holds it; +Y = towards the striking end.** The prop is parented to the measured grip, not to the hand bone.
- **Striking end:** `WeaponProp3D.TIP` — umbrella 0.60 m, broom 0.79 m along +Y.
- **Reach calibration:** clips are calibrated so the drawn tip lands at each skill's reach (`tests/weapon_test.gd`, `_test_contact`).
- **Broom:**
  - The handle end sits at **−0.695 m**. The game holds it near the handle end: `LONG_GRIP_SHIFT` = 0.395 m, written to the grip JSON as `long_shift`; the prop is moved +0.395 along +Y in the hand.
  - The rear hand holds at the end. **If the broom's length or origin changes, `BROOM_HANDLE_BACK` / `LONG_GRIP_SHIFT` in the generator must change with it.**
- **Collision:** each prop is measured from its own mesh (`BodyContact.prop_capsules`: 6 slices along Y, radius per slice), for:
  - not passing through its holder (`tests/weapon_clip_test`)
  - not passing through the other fighter (`tests/weapon_fight_contact_test`)
  - stopping blows on contact
- **Runtime only (no art needed):**
  - a swing trail (`WeaponTrail3D`)
  - the weapon turning away at the wrist when someone comes inside it

### 1.3 The old dumbbell is no longer a weapon
Owner decision: it is training kit (TRAINING / SUPPLY), like the hand grip and jump rope. The weapon data and moves were removed. Your `assets/props/weapons/old_dumbbell.glb` is now unused.

### 1.4 Breed models published to the runtime (owner: 「把codex完成的狗建模套入遊戲中」)
- Your latest non-rejected candidates were copied over `assets/characters/dog/models/breeds/<breed>.glb`:
  - frenchie r18
  - corgi r21
  - opponent shiba r23
  - golden r25
  - poodle r28
  - chihuahua r29
- Unchanged: pomeranian (r10), the player's `shiba_01`.
- r30 was in progress and was left alone.
- Check: `tests/breed_models_test` — skeleton, Idle/Walk/Sit, coloured, ≤ 60k tris, dog height, on the ground, facing.

### 1.5 Mesh2Motion animations (owner: 「好的，狗的部分也要使用」)
- **Sources:** Mesh2Motion, CC0 art, MIT code. Pinned untouched in `assets/_source/mesh2motion/`; commit, SHA-256s and licences are in `PROVENANCE.md`.
- **Tool:** `blender -b --factory-startup --python tools/art/retarget_mesh2motion.py -- [human|dogs|all]`
  - Each mapped bone's world rotation away from its rest goes onto the target bone's rest.
  - Hips move by leg-length ratio.
  - The dogs' vertical bounce is damped to 0.55.
- **Writes (overwritten on every run):**
  - `assets/characters/human/animations/p04_m2m_clips.glb` — owner, library `m2m`, 21 clips:
    - states: Idle_Hurt, Tired, Kneel_Tired, Dizzy, Shiver, Idle_Subtle
    - gestures: Victory, Cheer, Cheer_One, Greeting, Nod
    - actions: PickUp, Walk_Carry, Talk, Phone, Interact, Sit_Idle
    - combat: Dodge_Back/Left/Right, Knockback
  - `assets/characters/dog/animations/m2m/<model>.glb` — **one per dog model**, so each breed keeps its height. 9 clips: Run, Sneak, Fetch, Bark, Alert, Jump, Howl, Sit, Idle.
- **Bone maps** are in the tool:
  - Owner: same names as Mesh2Motion's human.
  - Dogs: fox → Shiba_Rig. The paws are mapped from the fox's *ankle*. Spine_1/Spine_3/Spine_4 → spine_01/spine_02/neck.
- **Used in game:**
  - Dogs: run, nose down (Fetch), bark, alert at a THREAT instinct.
  - Owner: win (Victory), pick-up, hurt idle, wave setting off.
- **In the libraries but not yet used:** dogs' Jump, Howl, Sneak; owner's Tired, Dizzy, Talk, Phone, Dodges, Sit_Idle, Walk_Carry.
- **Checks:** `tests/dog_motion_test` (clips, right moment, paws neither sunk nor floating), `tests/owner_gesture_test`.
- **Captures:** `tests/capture/dog_showcase.tscn`, `tests/capture/owner_showcase.tscn`.

### 1.6 Walking camera (FYI)
The walk is now a slightly third-person shot over the owner's shoulder, with the owner seen whole on the right of the frame. The owner model reads much more on the walk than before.

---

## 2. Adjustments requested (owner: 「我需要他調整」)

Mark each one in `ART_STATUS.md` as you take it. Where a change touches something Claude's code depends on, note it in your record and tell the owner; Claude will follow.

| ID | What | Why | Accept when |
|---|---|---|---|
| **CX-01** | **Umbrella prop readability**: bigger silhouette and/or lighter, higher-contrast canopy and handle; a clearer J-handle | Small and dark: hard to see on the walk and in fights at 405×720 (weapon showcase, real fights) | Readable in `tests/capture/weapon_showcase.tscn -- umbrella` and `record.sh umbrella`; origin/+Y convention kept; `weapon_test` passes (or tell Claude the new tip length) |
| **CX-02** | **One hit effect, not two** | Your coral impact rays (`EncounterPresentation3D.pulse_impact`, at the fighters' midpoint) and Claude's white hit spark (`CombatAtmosphere3D._spark`, at the front of the body hit) both fire on every blow | One readable effect per blow, agreed with the owner |
| **CX-03** | **Jaw bone on the dog rig** (all breeds and `shiba_01`), skinned to the lower jaw | Mesh2Motion's bark and howl move the fox's `Chin`; our Shiba_Rig has no jaw, so the bark opens no mouth | A jaw bone on every dog model, all existing bone names unchanged; tell Claude its name and Claude adds `Chin → <jaw>` to the dog map and re-bakes; `breed_models_test` and `dog_motion_test` pass |
| **CX-04** | **Review and clean the dogs' Mesh2Motion clips**: front legs overstretched in Run (most visible on the golden), the Alert paw lift, Sneak, Fetch | Retargeted automatically from a fox; good enough to ship, not polished | Fixes made in a way that survives a re-bake: change the map/offsets in `retarget_mesh2motion.py`, or add a post-pass there. Hand edits to the output GLBs are lost on the next run |
| **CX-05** | **Review the owner's Mesh2Motion clips** | The Greeting wave is small; "Tired Hunched" is on all fours (not used); Mesh2Motion clips leave the hands open | Same rule as CX-04. List which clips are fit for the game |
| **CX-06** | **Records** | `ART_STATUS.md` / `ASSET_LICENSES.md` are yours and held uncommitted edits, so Claude did not touch them | Mesh2Motion entry in `ASSET_LICENSES.md` (from `assets/_source/mesh2motion/PROVENANCE.md`); `ART_STATUS.md` notes the published breeds (1.4), the generated fight clips (1.1) and the Mesh2Motion libraries (1.5) |
| **CX-07** | **Poodle triangle budget** | r28 is ~51k triangles, above your character budget; mobile is the target | Within budget, same rig and clips; `breed_models_test` passes |
| **CX-08** | *Optional:* **closed hands in your relaxed Idle/Walk** | The carry clips close only the lead hand; the rest of the walk has open hands | If changed, re-run `make_fight_clips.py` (the carry clips are derived from yours) |
| **CX-09** | *Optional, needs the owner:* **the old dumbbell model as training kit** | It is no longer a weapon; the model is unused | Only if the owner wants it shown, e.g. at home |

---

## 3. Rules for these files

1. **Generated files are overwritten**:
   - `p04_fight_clips.glb`, `p04_fight_grip.json`, `p04_m2m_clips.glb`, `assets/characters/dog/animations/m2m/*.glb`
   - Change their generator (`make_fight_clips.py`, `retarget_mesh2motion.py`), or deliver your own clips under new names and tell Claude where to use them.
2. **Do not rename bones** on the OwnerSkeleton or the Shiba_Rig.
   - Code and both tools address them by name.
   - Adding bones (CX-03) is fine.
3. **Weapon props:**
   - Keep origin = grip and +Y = striking end.
   - If length or origin changes, say so: reach calibration, grip shift and collision depend on it.
4. **Re-run after any rig or prop change:**
   - `tests/breed_models_test`, `tests/dog_motion_test`, `tests/owner_gesture_test`, `tests/weapon_test`, `tests/weapon_clip_test`, `tests/weapon_fight_contact_test`, `tests/fight_body_contact_test`
   - All headless, via `tests/run_all.sh` or one scene each.
   - Captures: `tests/capture/record.sh`, `weapon_showcase.tscn`, `dog_showcase.tscn`, `owner_showcase.tscn` (Movie Maker, see LESSONS_LEARNED 3.4).
5. **Blender 5.2 only**, with the installed add-ons (`docs/99_notes/BLENDER_TOOLCHAIN.md`).
   - Check whether another Blender is open before changing preferences.
