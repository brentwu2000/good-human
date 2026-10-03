# Dog texture repair — second pass

This pass refreshed the seven preview GLBs and the factory `_codex` copies.

- Poodle: restored more curl variation on the head-side transition.
- Corgi: reduced side-view projection takeover and feathered the flank seam.
- Chihuahua, Pomeranian, Frenchie, Shiba, and Golden: regenerated from the same validated recipe so the set stays consistent.

All seven still preserve DogBody, UVs, Shiba_Rig, 23 joints, and Idle/Walk/Sit. The source factory files without `_codex` remain unchanged. GLB sizes are 2.027 MB (Chihuahua), 2.448 MB (Pomeranian), 2.083 MB (Poodle), 2.076 MB (Frenchie), 2.053 MB (Corgi), 2.088 MB (Shiba), and 2.362 MB (Golden).

The remaining poodle ear opening, Frenchie rear geometry, Corgi tail-root UV boundary, and Sit deformation are geometry/weight issues outside texture repair. The second-pass Godot import completed successfully, and the lineup was captured in [standard mode](dog_texture_review_2026-10-01/lineup_standard_round2.png) and [Soft Toon](dog_texture_review_2026-10-01/lineup_toon_round2.png).
