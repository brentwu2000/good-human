# P-04 Human Hair Fix 01

Date: 2026-09-29

The P-04 human candidate received a Blender hair pass after review found a hard, floating cap silhouette. `Hair_Module` is preserved but hidden in the source milestone; `Hair_Cap_Refined` plus three small fringe meshes now provide a rounded short-hair silhouette with a narrower side profile and no flat cut edge.

## Files

- Workshop milestone: `../good-human-3d-pipeline/blender/human/p04_owner/owner_11_hair_fix.blend`
- Runtime candidate: `assets/characters/human/models/p04_owner/p04_owner_hairfix.glb`
- Build script: `tools/art/fix_owner_hair.py`
- Runtime preload updated in `assets/characters/human/modular/p04_human_visual.gd`

## Verification

- Blender background export completed successfully.
- Godot reimported the GLB and the P-04 showcase launched.
- Updated human review capture: `assets/art_previews/p04/capture_0.png`.
- Targeted P-04 asset validation remains passing.

This remains a B-grade human art candidate; final hair topology and texture polish are still open.

## Skinning fix — 2026-10-03

The first export left `Hair_Cap_Refined` and the three fringe meshes unparented
and unskinned, so the hair stayed at its rest position whenever the head moved
(head snaps, `Down`). `fix_owner_hair.py` now parents them to `OwnerSkeleton`
with an Armature modifier and a full-weight `head` group; the GLB was
re-exported. `tests/skeletal_model_test.gd` checks that every hair mesh is
skinned to the shared human's skeleton.
