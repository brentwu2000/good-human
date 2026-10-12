# Chihuahua ear/chin detail polish r36 — 2026-10-12

Published assets/characters/dog/models/breeds/chihuahua.glb. REVIEW / B.
Local ear bowl/root and under-chin transition smoothing over published r35.
Visual improvement is subtle; identity, pointed ears and prior cheek paint retained.

[Front/three-quarter comparison](chihuahua_r36_2026-10-12/face_true.png)
[Profile comparison](chihuahua_r36_2026-10-12/sides_true.png)
[Standard material](chihuahua_r36_2026-10-12/all_false.png)
[Howl](chihuahua_r36_2026-10-12/M2M_Howl.png)
[Run](chihuahua_r36_2026-10-12/M2M_Run.png)

7,414 moved vertices, maximum 2.5 mm, zero inverted faces. Core eye/nose/mouth
movement at most 0.00042 mm. Binary edits limited to positions/normals; UVs,
texture, topology, eight skin influences, rig and all animation data retained.
47,787 triangles unchanged. No new source asset or addon.

First ear-wide smoothing trial rejected: surrounding surface shrank while tiny
irregular tip details remained, making spikes more conspicuous. Final mask fades
out between z=0.320 and 0.337 m and preserves the upper ear tip. Trial retained in
build/dog_polish_r36/trial1; it was never published. Existing tip irregularities
are still unresolved, rather than claimed removed.

Godot 4.6.3 D3D12: 20 static, 9 original animation and 90 M2M before/after images
reviewed. All nine M2M sheets inspected; 10 published-path Run images captured.
Five candidate/published after PNGs byte-identical. breed_models 81 checks and
dog_motion 80 checks PASS. Independent actual-skin audit: 473 poses per version,
including Run 209. Lowest surfaces unchanged; Howl p99 edge stretch rises from
1.473078 to 1.474556 (~0.10%); other clips unchanged. Existing limb motion
limitations remain. [Audit](chihuahua_r36_2026-10-12/validation.json),
[tests](chihuahua_r36_2026-10-12/regression_final.json),
[runtime](chihuahua_r36_2026-10-12/runtime_verification.json).

SHA-256: cdef00ca9d67907cf2af5e01c3470d05016718ba60b51b679869e92592f85e21.
Rebuild: run tools/art/polish_chihuahua_r36.py in Blender 5.2. Uses native Smooth
on a temporary welded logical surface and writes bounded position/normal changes
to the fixed r35 candidate GLB. Capture/contact/validation tools named chihuahua_r36;
M2M tools named chihuahua_motion_r36. Original r35 candidate remains intact.
Editable result: ../good-human-3d-pipeline/blender/dog/chihuahua_r36/chihuahua_02_surface.blend.
Prior Ucupaint source remains in sibling chihuahua_r35 folder.

Still B, not S: irregular tips, ear/neck texture seams, long angular muzzle,
coarse body fur, absent jaw motion, inherited Sit and over-budget topology remain.
This is a local geometry pass, not complete dog-art approval.
