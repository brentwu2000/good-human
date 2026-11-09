# Market auntie detail r2 — 2026-10-15

**WORK IN PROGRESS / B. Not a finished character; runtime remains unchanged.** Owner asked to proceed with one character in depth after rejecting the previous six-character pass as incomplete.

## Retained work

- Added an independent rounded leather satchel with a raised flap, rolled hem, closure tongues, brass clasps, actual stitch geometry and a crossbody strap. New pieces are joined into one skinned object with four material surfaces; no external assets.
- Recoloured the original head ribbon into continuous coral fabric with small cream dots. Repaired selected nose/chin projection marks and the skin-coloured forehead curl. Existing expression samples are protected (zero pre-encoding change in the selected landmarks).
- Bounded outer-hair relaxation: 1,114 welded-position keys, maximum 3 mm displacement. This does not rebuild the hair topology.
- Towel depth follows bounded front/back surface rays, with grid depth smoothing. The projection is capped at 35 mm and retains the drape's X/Z coordinates; no blanket nearest-surface collapse.
- Retracted/coloured the old flat side-panel remnants below the hands; the actual hands remain the source mitten geometry.
- Strap blends between chest and pelvis at its ends. Satchel follows pelvis. Original body weights are retained after the rejected trial below.

## Rejected work and current limits

Broad forehead masks produced horizontal bands and erased parts of the brow boundary; they were rolled back. Some original forehead/ear/cheek boundary errors remain. Do not call this head finished.

A torso reweighting trial (3,378 vertices) reduced arm influence but introduced sharper waist/skirt folds in actual Godot poses. It was rejected and restored from the pre-trial checkpoint. The retained script explicitly disables that torso patch. Original garment collapse during lifted-arm poses remains. This requires topology-aware shoulder/waist/hem work, not another rectangular weight mask.

Remaining: proper hand anatomy, natural hair/skin boundary, bow underside, smoother towel shoulder attachment, coherent clothing topology and deformation, less regular cloth motifs, complete accessory acceptance across motion. No S grade or runtime promotion.

## Files and validation

Candidate: assets/art_previews/humans/market_auntie_r2/market_auntie.glb, with per-file provenance. 53 skin joints and 19 clips retained. Godot before/after checks compare bone names and clip lists and sample 342 poses for finite transforms; this is **not** a deformation-quality pass. All 19 clips also receive a visual sample per version.

[Static comparison](../../assets/art_previews/humans/market_auntie_r2/comparison.jpg)
[Head comparison](../../assets/art_previews/humans/market_auntie_r2/head_comparison.jpg)
[Motion comparison](../../assets/art_previews/humans/market_auntie_r2/motion_comparison.jpg)

Checkpoints under build/market_auntie_refine_r2/: 00_before.blend, 01_head_and_towel.blend, 02_satchel.blend, 03_export.blend, 04_skin_refined.blend. Despite its filename, 04 has the failed torso trial disabled; only the new strap blend remains. JSON records: head_towel.json, skin.json, godot_validation.json.

Rebuild scripts: refine_auntie_r2.py; auntie_r2_satchel.py; auntie_r2_skin_export.py (starts from joined 03_export checkpoint); preview helper auntie_r2_preview.py; capture_auntie_r2.gd; contact_auntie_r2.py. Blender 5.2 only. Preserve the pre-join checkpoint before combining accessory meshes.

No downloads or new third-party source. Existing reference rights are unchanged.

## Final retained-build audit

Final GLB: 15,322 triangles, 53 joints, 19 clips, six material surfaces. Godot 342 pose samples pass the structural/finite-transform checks. A UV-keyed named-bone comparison verifies 11,067 exported body vertices against the prior candidate: no missing UV keys, maximum weight difference 1.1920929e-7. The failed body-weight trial is therefore not in the delivery.

Reviewed static sides/three-quarter, head close-up and the ten-clip motion comparison. Original lifted-arm garment collapse remains; Down moves partly outside the fixed review camera, so that sample cannot establish full-body visual acceptance. New satchel/strap are present in the sampled poses, but dynamic attachment/collision acceptance is still open.
