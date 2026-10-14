# Claude → Codex (ART) handoff — 2026-10-12

Owner: 「請你負責精修人物」. This round Claude refines the human characters
(owner, ordinary opponents, grandma). The art split is otherwise unchanged;
the dogs and props stay with you.

## Added / changed
- **Owner model r1** — `assets/characters/human/models/p04_owner/p04_owner_refined.glb`,
  rebuilt by `blender -b --factory-startup --python tools/art/refine_owner_head.py`
  from your workshop `owner_11_hair_fix.blend` (writes `owner_12_head_refine.blend`).
  New meshes `Hair_Curls`, `Glasses`, `Brows`, all skinned to `head`; old hair
  meshes removed; jacket collar points / zip / pocket seams laid onto the body.
  `P04HumanVisual.MODEL` now points here. Record: `OWNER_HEAD_R1_2026-10-12.md`.
- **Review capture** — `tests/capture/human_portraits.tscn -- <out dir> [fighter…]`.

- **Office worker r1 (2026-10-13)** — `assets/characters/human/models/office_worker/office_worker.glb`,
  made through the AI 3D factory (owner chose that route): Qwen-Image-Edit-2509 view →
  TripoSG → retopo → bake → projection + `paint_head_stylized.py` → `rig_lods.py --name office_worker`.
  Worn by the `office_worker` adopter background (`HumanBackgroundData.skeletal_model`).
  Record: `OFFICE_WORKER_R1_2026-10-13.md`.
- **Factory changes** (in `good_human_stylized_factory/scripts`, defaults unchanged for the grandma):
  `project_textures.py --hair dark`, `rig_lods.py --name / --measure-neck / --no-game-normal`,
  `rig_character.measure_neck`, new `paint_stylized.py` (+ per-character `paint_profile.json`),
  new `match_proportions.py` (head-to-body ratio; the office worker matches the grandma's 0.24);
  `batch_dogs.sh` now launches generators from `C:/Users/b/tools/modly` (Modly 1476fd0 +
  TripoSG, reinstalled 2026-10-13; the old `Documents/ai_3d_pipeline_poc` is gone).

- **Market auntie r1 (2026-10-13)** — `assets/characters/human/models/market_auntie/market_auntie.glb`,
  background `market_vendor`. New factory pieces: `project_simple.py` (layout-free multi-view
  projection, fixes inside-out normals first), `paint_stylized.py` `"mode": "zones"`,
  `project_textures.py --no-region-gate`. Record: `MARKET_AUNTIE_R1_2026-10-13.md`.

- **Retired fisher r1 (2026-10-13)** — `assets/characters/human/models/retired_fisher/retired_fisher.glb`,
  background `retiree`. `project_simple.py` now welds UV seams before fixing normals;
  `paint_stylized.py` zones accept `x_min` and `r_min`/`y_centre`. Record: `RETIRED_FISHER_R1_2026-10-13.md`.

- **Rider, gym coach, Xiaomi r1 (2026-10-14)** — `assets/characters/human/models/{delivery_rider,gym_coach,xiaomi}/`.
  Xiaomi is not wired to any background (owner). New options: `project_simple.py --neck-search`,
  `match_proportions.py --neck-range`, zones `y_min`. Record: `CHARACTERS_R1_2026-10-14.md`.

## Do not change without telling Claude
- OwnerSkeleton bone names; the clips are shared by every human.
- Mesh names starting `Hair` (`skeletal_model_test` checks they are skinned).

## Requests
None yet. Codex QA of the refined humans is welcome when the round ends.
