# Dog texture repair — all-breed 45° head pass

The same 3/4 projection issue was present at different strengths on the other breeds. The texture generator now applies the cheek mask to every non-poodle breed as well: facial features remain on the forward head plane, while cheek/rear head islands are returned to the breed coat field.

Validation used an exact −45° Blender camera for chihuahua, pomeranian, poodle, frenchie, corgi, shiba, and golden. Each render shows the expected two eyes on the face, with no extra eye or duplicated muzzle detached on the cheek. The updated preview and factory `_codex` GLBs were published after the check.

The exact renders are under `build/dogs_texture_codex/<breed>/renders/<breed>_45.png`; the existing preview backup remains under `build/dogs_texture_codex/preview_originals/`. Mesh, UV, rig, weights, and clips were not changed.
