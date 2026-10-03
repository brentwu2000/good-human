# Dog texture repair — 45° head pass

The poodle had a front-face projection reaching too far onto the cheek at 3/4 view. That could read as a second eye or duplicated muzzle. The face depth mask was narrowed to the nose/eye plane, leaving cheek surfaces on the curl coat field.

The new poodle 3/4 render was checked after the change: one eye set and one muzzle remain visible, with no new broken colour patch. The poodle preview GLB is 2,076,420 bytes and keeps the same mesh, UVs, rig, joints, and clips. The preview and factory `_codex` copy were updated.

Godot 4.6.3 re-imported the updated preview successfully, and the seven-dog lineup was captured again in [Standard](dog_texture_review_2026-10-01/lineup_standard_round3.png) and [Soft Toon](dog_texture_review_2026-10-01/lineup_toon_round3.png).

This pass does not claim to fix the poodle ear opening, tail geometry, or Sit deformation; those are model/weight issues.
