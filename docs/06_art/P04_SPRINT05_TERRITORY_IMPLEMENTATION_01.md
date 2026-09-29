# P-04 / Sprint 05 Territory Art Implementation 01

Date: 2026-09-29

This pass turns the territory reference states into a Blender-authored art candidate and a Godot review hook. The source banyan remains in `banyan_01.glb`; the scent state candidate is `assets/environment/territory/models/banyan_01/banyan_scent_states.glb`.

## Implemented

- `UNKNOWN`: no scent geometry.
- `DISCOVERED`: violet bead and short scent stroke.
- `CONTESTED`: alternating coral and teal pairs.
- `CLAIMING`: teal dominant bead and stroke set used during the 1.15 second mark cue.
- `OWNED`: teal scent set plus a cream reward leaf cluster.
- `p04_scent_visual.gd` exposes `set_state`, `play_recognize`, `play_mark`, and `play_reward_reveal` without changing gameplay authority.
- P-04 review scene now exposes `T`, `R`, `M`, and `Y` controls in Banyan mode.

## Blender evidence

Milestones are under `../good-human-3d-pipeline/blender/environment/banyan_01/`: `banyan_06_before_scent.blend`, `banyan_07_scent_states.blend`, and `banyan_10_scent_only.blend`. The final GLB contains only 35 scent/reward mesh nodes; it does not include the human or banyan source meshes.

## Scope and limits

This is a B-grade art candidate for D5-02/D5-03/D5-08. Timing and state authority still belong to the territory gameplay/presentation layer. The review scene is art-only and does not write saves, award resources, or mutate territory state.

## Verification

- Blender bridge health: connected.
- GLB JSON inspection: 35 nodes, all prefixed `Scent_` or `Reward_`.
- Targeted P-04 asset validation remains the required regression check.
