> Superseded: owner clarified the Claude handoff; CX-04 repair published in [r33](DOG_MOTION_R33_2026-10-10.md).

# Dog texture / Mesh2Motion diagnosis — 2026-10-09

Status: inspection completed; requested repair is NOT complete. Awaiting owner identification of affected breed/area. Runtime files and animation libraries unchanged.

Inspected all seven breed models at rest and at midpoint of Run, Fetch and Howl using the actual DogModelMotion3D binding. Captures: build/dog_texture_r32/inspect. Also inspected Claude's existing build/captures/dogs.avi.

Chihuahua at rest has duplicate mouth projections. At Howl midpoint, neck/mouth texture stretches and torso collapses with back-facing/open-looking regions. This is visible geometry deformation in addition to texture defects; a texture swap alone cannot fix it. Original Mesh2Motion animation files contain a skeleton/stub, not replacement body materials.

Checked all seven breed models' coincident-position UV seam vertices: no weight differences above 0.05; normalized weight sums near 1. A 60-iteration adjacency weight smoothing experiment on Chihuahua did not resolve the collapse. REJECTED, not published. Diagnostic GLB is build/dog_texture_r32/rejected_weight_smoothing.glb; trial images under build/dog_texture_r32/trial. Do not promote it.

No final-art or deformation pass claimed. Reproduction tools: tools/art/inspect_dog_texture_r32.gd (published models), build/dog_texture_r32/inspect_weights.py. tools/art/inspect_dog_weights_r32.gd is the rejected trial's capture script; its former candidate path is intentionally no longer populated.
