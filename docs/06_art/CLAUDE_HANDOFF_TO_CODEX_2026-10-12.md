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

## Do not change without telling Claude
- OwnerSkeleton bone names; the clips are shared by every human.
- Mesh names starting `Hair` (`skeletal_model_test` checks they are skinned).

## Requests
None yet. Codex QA of the refined humans is welcome when the round ends.
