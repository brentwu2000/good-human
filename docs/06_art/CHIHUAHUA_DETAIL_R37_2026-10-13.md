# Chihuahua ear-tip/throat refinement r37 — 2026-10-13

Started 2026-10-12; completed 2026-10-13 Asia/Taipei. Published to
assets/characters/dog/models/breeds/chihuahua.glb. REVIEW / B.

Very local ear-tip relaxation (3 native Smooth iterations, factor 0.3) reduces
minor roughness without repeating r36's broad ear shrinkage. 425 vertices moved,
maximum 1.113 mm, zero inverted faces; protected eyes/nose/mouth unmoved.
Ucupaint base/donor/mask layers soften the disconnected grey-white throat band
above the collar, sampling the existing project Chihuahua side reference.

[Front and three-quarter](chihuahua_r37_2026-10-12/face_true.png)
[Profiles](chihuahua_r37_2026-10-12/sides_true.png)
[Standard material](chihuahua_r37_2026-10-12/all_false.png)
[Howl](chihuahua_r37_2026-10-12/M2M_Howl.png)
[Run](chihuahua_r37_2026-10-12/M2M_Run.png)

The throat reads more continuously, but donor fur is relatively flat; ear-tip
improvement is subtle and tiny irregularities remain. Coarse body fur, angular
muzzle, original Sit, missing jaw motion and 47,787-triangle budget remain open.
No S/final-art claim.

## Verification

Godot 4.6.3 D3D12: 20 static views and 9 original animation samples reviewed,
plus all 9 M2M sheets (90 before/after frames). Published-path Run: 10 images,
with all five after PNGs byte-identical to the candidate. Model tests 81 and
motion tests 80 checks PASS. No runtime capture stderr.

Independent skin audit: 473 poses per version (Run 209); lowest surfaces and p99
edge stretch unchanged for all nine clips. Geometry stage retains binary except
positions/normals; texture packaging retains geometry binary prefix and appends
PNG. Topology, UVs, both skin influence sets, rig and animation values retained.
Full atlas baking can change pixels outside the mask by resampling.

[Geometry audit](chihuahua_r37_2026-10-12/geometry_verification.json)
[Motion audit](chihuahua_r37_2026-10-12/validation.json)
[Tests](chihuahua_r37_2026-10-12/regression_final.json)
[Published verification](chihuahua_r37_2026-10-12/runtime_verification.json)

SHA-256: 1648b03a7b833465e82d29bbe4336fc1e3c30ce77d9fc0e1ffa1b786d7983970.
Fixed baseline: assets/art_previews/dogs/candidates/r36/chihuahua.glb.
Candidate: assets/art_previews/dogs/candidates/r37/chihuahua.glb.
Editable packed geometry/paint source:
../good-human-3d-pipeline/blender/dog/chihuahua_r37/chihuahua_05_final.blend.

Rebuild in Blender 5.2: tools/art/polish_chihuahua_r37.py, then
paint_chihuahua_r37.py; package_chihuahua_r37.py packages the baked image.
Stage folder build/dog_polish_r37. Capture/contact/validate/verify tools use
chihuahua_r37; M2M capture/contact use chihuahua_motion_r37.
This run initially painted the r36 surface, then transferred final r37 ear
positions and normals to the editable source; ear mask is outside the painted
throat region. Original r36 and earlier source assets remain intact.
