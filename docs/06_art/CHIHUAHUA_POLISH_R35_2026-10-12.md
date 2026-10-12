# Chihuahua face polish r35 — 2026-10-12

Published to assets/characters/dog/models/breeds/chihuahua.glb. REVIEW / grade B.
Owner priority: refine dogs; this pass addresses Chihuahua facial surface and cheek material.

## Result

Local native Blender smoothing softens the eye-socket/cheek planes without changing topology.
7,023 vertices move, maximum 3.191 mm; no inverted faces. Protected eye/nose/mouth
core has at most 0.0039 mm numerical movement. Ucupaint base, donor and feathered
mask layers replace the outlined cheek patch and tooth-like white flecks with continuous fur.
The donor is the existing project Chihuahua side reference; no new downloaded asset.

[Front and three-quarter comparison](chihuahua_r35_2026-10-12/face_true.png)
[Profile comparison](chihuahua_r35_2026-10-12/sides_true.png)
[Standard material comparison](chihuahua_r35_2026-10-12/all_false.png)
[Run comparison](chihuahua_r35_2026-10-12/M2M_Run.png)
[Jump comparison](chihuahua_r35_2026-10-12/M2M_Jump.png)

## Validation

Blender clay/material inspection and Godot 4.6.3 D3D12 captures: 20 static views,
9 original animation samples and 90 M2M before/after samples. All nine M2M sheets
reviewed. Published-path Run capture adds 10 samples; five after PNGs byte-identical
to candidate capture. breed_models: 81 checks; dog_motion: 80 checks, both PASS.

Independent GLB audit retains topology, UVs, both joint/weight sets, skeleton and
animation values. Geometry stage changes only POSITION/NORMAL binary ranges;
texture stage retains that binary prefix and appends the baked image. The full
atlas is baked, so unchanged texture bytes outside the local mask are not claimed.
Nine M2M clips audited at 33 poses each, Run at 209 (473 poses per version).
Lowest skinned surface values unchanged; maximum p99 stretch change is Howl
1.472714 to 1.473078 (about 0.025%). Existing Run p99 stretch 2.47870 remains.
No M2M rebake or gameplay code change.

Published SHA-256: 92514df9a47d421d4bb5dcbe532167daf50b809859a8add13da4b1f4e210b80e.
[Audit and verification](chihuahua_r35_2026-10-12/validation.json)
[Runtime verification](chihuahua_r35_2026-10-12/runtime_verification.json)
[Test logs](chihuahua_r35_2026-10-12/regression_final.json)

## Rebuild and editable source

In Blender 5.2, run tools/art/polish_chihuahua_r35.py then paint_chihuahua_r35.py;
package_chihuahua_r35.py appends the baked image without Blender re-exporting skin.
Fixed baseline: assets/art_previews/dogs/candidates/r34/models/chihuahua.glb.
Candidate: assets/art_previews/dogs/candidates/r35/chihuahua.glb.
Capture/contact/validation/verification tools have chihuahua_r35 in their names;
M2M capture/contact tools are capture_chihuahua_motion_r35.gd and
contact_chihuahua_motion_r35.py. Rebuild staging uses build/dog_polish_r35.
Editable packed Ucupaint source and untouched imported baseline are archived at
../good-human-3d-pipeline/blender/dog/chihuahua_r35/chihuahua_04_ucupaint.blend
and chihuahua_00_import.blend. Original source/reference material retained.

## Outstanding quality

Still B, not S/final approval. Long angular muzzle silhouette, lower jaw/neck planes,
ear edges, coarse torso/fur, lack of jaw animation and inherited original Sit defects
remain. M2M limb stretch/sliding is not resolved by a facial pass. Triangle count
47,787 remains above the 8–20k target. Other breeds need their own refinement.
