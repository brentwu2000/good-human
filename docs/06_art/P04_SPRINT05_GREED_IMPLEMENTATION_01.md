# P-04 / Sprint 05 Greed Moment Implementation 01

Date: 2026-09-29

The D5-04 storyboard is now represented as an art-only Godot review composition using a Blender-authored prop kit.

## Implemented

- Safe exit side: bus-stop pole, sign, bench, and teal exit plaque.
- Value carried: full canvas bag with two handles beside the owner.
- Temptation: rival dog staging with coral neckerchief and a low violet scent trail.
- Voluntary choice: the player dog leans toward the scent while the teal leash stays readable; the banyan remains in the same frame.
- P-04 review scene adds mode `6` / `Greed moment` and captures `capture_5.png`.

## Blender evidence

- Workshop: `../good-human-3d-pipeline/blender/environment/greed/greed_props_01.blend`
- Runtime candidate: `assets/environment/territory/models/greed/greed_props.glb`
- Source script: `tools/art/build_greed_props.py`

## Scope and limits

This is a B-grade composition candidate for D5-04. It does not resolve extraction, RunValue, Risk HUD, or territory gameplay. Those systems remain authoritative when engineering connects the art hook.

## Verification

- Blender background export completed with 14 mesh objects.
- Godot imported the GLB successfully.
- P-04 showcase launched with no new parse errors.
- Review capture: `assets/art_previews/p04/capture_5.png`.
