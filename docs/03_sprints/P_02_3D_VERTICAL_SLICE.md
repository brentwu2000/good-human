# P-02 — 3D VERTICAL SLICE

Owner decision (2026-09-17): move production to 3D. After playing the slice the owner dropped the top-down view: the game uses the dog-height chase camera only (P-01 "B"). Start with a small vertical slice before porting everything. See `docs/07_qa/reports/P_01_CAMERA_GATE_REVIEW.md`.

## Goal
Play one real walk in 3D using the existing game systems: the dog walks the owner, sniffs for loot, meets and provokes a pair (seamless fight), and goes home through an extraction point — seen from the dog-height camera.

## Scope
- One street + park entrance area (greybox / CC0-ready primitives).
- Dog and owner on a leash in 3D; the owner behaves as in 2D (follow / combat / down).
- Search points and one extraction point using the existing RunManager, LootTables, inventory, HUD, result screen and save.
- One opponent pair using the existing CombatSimulation (seamless, in place, spatial disengage).
- Production camera rig: low chase camera behind the dog, wall collision, owner/foliage/too-close wall fade, automatic combat framing.
- Movement is relative to the camera; the camera follows only while moving forward (no spinning on sideways input).
- Entry from Home ("3D 散步") next to the 2D walk while both exist.

## Out of scope (next steps)
Training and goal world observers in 3D, squirrel/scent cues, the full neighbourhood, 3D art, Android performance, retiring the 2D map.

## Engineering rules
- Reuse engine-agnostic systems unchanged (run, loot, inventory, save, combat simulation, training/goal logic).
- 2D scenes and tests keep working until the port is complete.
- Units are meters.

## Acceptance
- A full walk (search → loot → fight → extract → result → Home) works in 3D.
- The camera stays low behind the dog without spinning the controls.
- The dog stays visible (collision, fading).
- Fights start and end without scene changes; running away disengages.
- Automated scene test covers the slice; all existing tests still pass.
