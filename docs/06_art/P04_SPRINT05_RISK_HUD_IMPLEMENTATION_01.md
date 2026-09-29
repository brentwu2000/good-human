# P-04 / Sprint 05 Risk HUD Implementation 01

Date: 2026-09-29

D5-05 now has a working visual prototype in the P-04 ART showcase. Greed Moment mode displays a quiet dark dog-tag panel with a narrow teal edge and two short lines:

- `WALK VALUE`
- `UNBANKED 12 · one more thing`

The panel is shown only in the Greed Moment review mode, stays below the existing review controls, and uses cream/amber text for carried value. It does not calculate value, move loot, unlock extraction, or mutate run state.

## Verification

- Godot showcase parses and launches after the HUD addition.
- Existing targeted P-04 asset validation remains passing.
- The HUD is visible in the same `capture_5.png` composition as the safe exit and temptation props.

This is a B-grade UI art candidate pending connection to the runtime `RunValue` and `value_changed` presentation contract.
