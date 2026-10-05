# P-04 / Sprint 05 ART Decision Pack 01

Date: 2026-09-29

This pack records the selected visual implementation for the Sprint 05 territory and greed work. It is an implementation handoff, not final-art approval.

## Selected visual language

| Deliverable | Selected implementation | Review entry |
|---|---|---|
| D5-01 Landmark | Blender-authored Big Banyan with three fused trunks, roots, aerial roots, canopy and pale scar | Showcase `4` |
| D5-02 Scent ownership | Root-level scent beads and strokes: violet, coral/teal contest, teal owned route | Showcase `7`, `T` |
| D5-03 Mark interaction | Review-only recognize, claim and reward calls on `p04_scent_visual.gd` | `R`, `M`, `Y` |
| D5-04 Greed moment | Safe exit props, full bag, rival pair, scent trail and dog-directed pull | Showcase `6` |
| D5-05 Risk HUD | Quiet two-line dark tag with teal edge and cream/amber copy | Greed mode HUD |
| D5-06 Rival pair | Persistent black dog + indigo-hoodie human, coral neckerchief and teal tag | Greed / target modes |
| D5-07 World states | UNKNOWN, DISCOVERED, CONTESTED, OWNED | Showcase `7` |
| D5-08 Reward reveal | Nine small teal/cream leaf shapes rising from roots | `Y` / owned state |
| D5-09 Target frame | Dog-height chase composition with review controls hidden | Showcase `8`, `capture_7.png` |

## Runtime boundaries

- Gameplay remains authoritative for territory state, extraction, RunValue, rewards, rival selection, timing and persistence.
- ART hooks are visual-only: `set_state`, `play_recognize`, `play_mark`, `play_reward_reveal`.
- The showcase never writes saves, awards resources, unlocks extraction, or resolves combat.

## Asset handoff

- Human: `assets/characters/human/models/p04_owner/p04_owner.glb`
- Banyan: `assets/environment/territory/models/banyan_01/banyan_01.glb`
- Scent states: `assets/environment/territory/models/banyan_01/banyan_scent_states.glb`
- Greed props: `assets/environment/territory/models/greed/greed_props.glb`
- Review scene: `assets/art_previews/p04/p04_asset_showcase.tscn`

## Open production work

All listed meshes remain B-grade candidates. Production integration still needs runtime presentation binding, mobile typography pass, final dog/human art review, and gameplay-owned timing tests.
