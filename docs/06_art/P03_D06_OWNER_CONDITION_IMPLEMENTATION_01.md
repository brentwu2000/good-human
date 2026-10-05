# P03-D06 / Owner Condition Implementation 01

Date: 2026-09-29

The P-04 ART showcase now includes an art-only condition board on key `9`. Four owner candidates are staged side by side:

- HEALTHY: vertical spine and even stance;
- HURT: protective torso asymmetry and slight head offset;
- CRITICAL: unstable hips, deeper torso bend and delayed head reacquisition;
- DOWN: authored `Down` animation rather than a recolor or HUD-only cue.

The state differences are carried by body behavior and silhouette. No persistent HP bar, red screen grade, damage calculation, or combat outcome was added.

## Verification

- Godot showcase launches and captures `assets/art_previews/p04/capture_8.png`.
- Existing targeted P-04 asset validation remains passing.
- This is a B-grade ART candidate; gameplay still owns condition thresholds and transitions.
